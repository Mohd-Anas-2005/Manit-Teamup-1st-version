-- =============================================================================
-- Migration: 20261021000009_notifications_enhancements.sql
-- Description: Hardens notification storage, authorization, deduplication,
--              read-state management RPCs, and unread count queries.
-- =============================================================================

-- 1. NOTIFICATION DEDUPLICATION & CREATION HELPER
-- Avoids spamming users with duplicate unread notifications for the same team/event
CREATE OR REPLACE FUNCTION public.create_notification_deduped(
    p_recipient_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_body TEXT,
    p_related_team_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_existing_id UUID;
    v_new_id UUID;
BEGIN
    IF p_recipient_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if an unread duplicate notification already exists
    IF p_related_team_id IS NOT NULL THEN
        SELECT id INTO v_existing_id
        FROM public.notifications
        WHERE recipient_id = p_recipient_id
          AND type = p_type
          AND related_team_id = p_related_team_id
          AND read_at IS NULL
        LIMIT 1;
    ELSE
        SELECT id INTO v_existing_id
        FROM public.notifications
        WHERE recipient_id = p_recipient_id
          AND type = p_type
          AND title = p_title
          AND read_at IS NULL
        LIMIT 1;
    END IF;

    -- If unread duplicate exists, do not re-insert; update created_at to bump freshness
    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- Insert new notification
    INSERT INTO public.notifications (
        recipient_id,
        type,
        title,
        body,
        related_team_id
    ) VALUES (
        p_recipient_id,
        p_type,
        p_title,
        p_body,
        p_related_team_id
    )
    RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_notification_deduped(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_notification_deduped(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated, service_role;

-- 2. UPDATE JOIN REQUEST INSERT TRIGGER TO USE DEDUPLICATION
CREATE OR REPLACE FUNCTION public.trg_join_requests_on_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_team_owner_id UUID;
    v_team_name TEXT;
    v_requester_name TEXT;
BEGIN
    -- Look up team and requester info
    SELECT owner_id, name INTO v_team_owner_id, v_team_name 
    FROM public.teams 
    WHERE id = NEW.team_id;

    SELECT display_name INTO v_requester_name 
    FROM public.profiles 
    WHERE id = NEW.requester_id;

    IF v_team_owner_id IS NOT NULL THEN
        PERFORM public.create_notification_deduped(
            v_team_owner_id,
            'joinRequest',
            'New Join Request 📩',
            coalesce(v_requester_name, 'A student') || ' requested to join "' || v_team_name || '".',
            NEW.team_id
        );
    END IF;

    RETURN NEW;
END;
$$;

-- 3. RPC: MARK A SINGLE NOTIFICATION AS READ
CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
    p_notification_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_recipient_id UUID;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to modify notification status';
    END IF;

    -- Verify notification exists and caller is recipient
    SELECT recipient_id INTO v_recipient_id
    FROM public.notifications
    WHERE id = p_notification_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Notification not found with ID: %', p_notification_id;
    END IF;

    IF v_recipient_id <> v_caller_id THEN
        RAISE EXCEPTION 'Unauthorized: You can only mark your own notifications as read';
    END IF;

    -- Update read timestamp
    UPDATE public.notifications
    SET read_at = timezone('utc'::text, now())
    WHERE id = p_notification_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', p_notification_id,
        'read_at', timezone('utc'::text, now())
    );
END;
$$;

REVOKE ALL ON FUNCTION public.mark_notification_as_read(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_notification_as_read(UUID) TO authenticated, service_role;

-- 4. RPC: MARK ALL NOTIFICATIONS AS READ FOR CALLER
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_count INTEGER;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to modify notification status';
    END IF;

    UPDATE public.notifications
    SET read_at = timezone('utc'::text, now())
    WHERE recipient_id = v_caller_id
      AND read_at IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN jsonb_build_object(
        'success', true,
        'marked_count', v_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.mark_all_notifications_as_read() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_as_read() TO authenticated, service_role;

-- 5. RPC: GET UNREAD NOTIFICATION COUNT FOR CALLER
CREATE OR REPLACE FUNCTION public.get_unread_notification_count()
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_count INTEGER;
BEGIN
    IF v_caller_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT count(*)::INTEGER INTO v_count
    FROM public.notifications
    WHERE recipient_id = v_caller_id
      AND read_at IS NULL;

    RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.get_unread_notification_count() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_unread_notification_count() TO authenticated, service_role;
