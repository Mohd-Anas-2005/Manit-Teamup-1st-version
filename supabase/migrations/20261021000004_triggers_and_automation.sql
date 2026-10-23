-- MANIT TeamUp: Supabase Triggers and Automated Invariants
-- Migration: 20261021000004_triggers_and_automation.sql
-- Description: Enforces immutability of identity fields, auto-enrolls team owners,
-- prevents tampering with verification status, validates capacity, and handles notifications.

-- =============================================================================
-- 1. PROFILES TRIGGER: Enforce permitted fields and protect verification status
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_enforce_profile_security()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Prevent clients from self-assigning verified status during direct inserts
        IF (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' 
           AND current_user NOT IN ('postgres', 'supabase_admin') THEN
            NEW.membership_verification_status := 'unverified';
        END IF;
        NEW.created_at := timezone('utc'::text, now());
        NEW.updated_at := timezone('utc'::text, now());
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        -- Prevent mutating immutable identifier
        IF NEW.id <> OLD.id THEN
            RAISE EXCEPTION 'Profile ID is immutable';
        END IF;

        -- Prevent mutating created_at timestamp
        IF NEW.created_at <> OLD.created_at THEN
            NEW.created_at := OLD.created_at;
        END IF;

        -- Prevent clients from assigning or modifying membership_verification_status
        IF NEW.membership_verification_status IS DISTINCT FROM OLD.membership_verification_status THEN
            IF (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' 
               AND current_user NOT IN ('postgres', 'supabase_admin') THEN
                RAISE EXCEPTION 'A user may not assign or modify their own membership verification status';
            END IF;
        END IF;

        NEW.updated_at := timezone('utc'::text, now());
        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_security ON public.profiles;
CREATE TRIGGER trg_profiles_security
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_profile_security();

-- =============================================================================
-- 2. TEAMS TRIGGER: Prevent owner tampering & auto-enroll owner in team_members
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_enforce_team_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.id <> OLD.id THEN
        RAISE EXCEPTION 'Team ID is immutable';
    END IF;

    IF NEW.owner_id <> OLD.owner_id THEN
        RAISE EXCEPTION 'Team owner is immutable and cannot be transferred directly';
    END IF;

    IF NEW.created_at <> OLD.created_at THEN
        NEW.created_at := OLD.created_at;
    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_teams_immutability ON public.teams;
CREATE TRIGGER trg_teams_immutability
    BEFORE UPDATE ON public.teams
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_team_immutability();

-- Automatically enroll the creator as the 'owner' in team_members upon team creation
CREATE OR REPLACE FUNCTION public.trg_auto_enroll_team_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (NEW.id, NEW.owner_id, 'owner', timezone('utc'::text, now()))
    ON CONFLICT (team_id, user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_teams_auto_enroll_owner ON public.teams;
CREATE TRIGGER trg_teams_auto_enroll_owner
    AFTER INSERT ON public.teams
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auto_enroll_team_owner();

-- =============================================================================
-- 3. TEAM MEMBERS TRIGGER: Enforce capacity & immutability defense-in-depth
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_enforce_team_members_invariants()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_max_members INTEGER;
    v_current_count INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Allow the owner insertion by checking if role is 'owner'
        IF NEW.role <> 'owner' THEN
            SELECT max_members INTO v_max_members 
            FROM public.teams 
            WHERE id = NEW.team_id;

            SELECT COUNT(*) INTO v_current_count 
            FROM public.team_members 
            WHERE team_id = NEW.team_id;

            IF v_current_count >= v_max_members THEN
                RAISE EXCEPTION 'Team capacity of % members has been reached', v_max_members;
            END IF;
        END IF;

        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NEW.id <> OLD.id OR NEW.team_id <> OLD.team_id OR NEW.user_id <> OLD.user_id THEN
            RAISE EXCEPTION 'Membership identifiers are immutable';
        END IF;

        IF OLD.role = 'owner' AND NEW.role <> 'owner' THEN
            RAISE EXCEPTION 'Team owner role cannot be downgraded directly';
        END IF;

        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_team_members_invariants ON public.team_members;
CREATE TRIGGER trg_team_members_invariants
    BEFORE INSERT OR UPDATE ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_team_members_invariants();

-- =============================================================================
-- 4. JOIN REQUESTS TRIGGER: Automated notification on submission & immutability
-- =============================================================================
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
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body,
            related_team_id
        ) VALUES (
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

DROP TRIGGER IF EXISTS trg_join_requests_notify_insert ON public.join_requests;
CREATE TRIGGER trg_join_requests_notify_insert
    AFTER INSERT ON public.join_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_join_requests_on_insert();

CREATE OR REPLACE FUNCTION public.trg_enforce_join_request_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.id <> OLD.id OR NEW.team_id <> OLD.team_id OR NEW.requester_id <> OLD.requester_id THEN
        RAISE EXCEPTION 'Core join request identifiers are immutable';
    END IF;

    IF NEW.message <> OLD.message THEN
        RAISE EXCEPTION 'Pitch message cannot be altered once submitted';
    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_join_requests_immutability ON public.join_requests;
CREATE TRIGGER trg_join_requests_immutability
    BEFORE UPDATE ON public.join_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_join_request_immutability();

-- =============================================================================
-- 5. NOTIFICATIONS TRIGGER: Content immutability
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_enforce_notification_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.id <> OLD.id 
       OR NEW.recipient_id <> OLD.recipient_id 
       OR NEW.type <> OLD.type 
       OR NEW.title <> OLD.title 
       OR NEW.body <> OLD.body 
       OR NEW.related_team_id IS DISTINCT FROM OLD.related_team_id 
       OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'Notification content is immutable; only read status (read_at) can be modified';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notifications_immutability ON public.notifications;
CREATE TRIGGER trg_notifications_immutability
    BEFORE UPDATE ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_notification_immutability();

-- =============================================================================
-- 6. REPORTS TRIGGER: Prevent client modification of report status
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_enforce_report_tampering_protection()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' 
       AND current_user NOT IN ('postgres', 'supabase_admin') THEN
        RAISE EXCEPTION 'Clients are not permitted to modify reports or administrative report status';
    END IF;

    IF NEW.id <> OLD.id OR NEW.reporter_id <> OLD.reporter_id OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'Report identifiers are immutable';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_tampering ON public.reports;
CREATE TRIGGER trg_reports_tampering
    BEFORE UPDATE ON public.reports
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_report_tampering_protection();

-- =============================================================================
-- 7. AUTH HOOK: Automatically provision profiles upon Supabase Auth registration
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_display_name TEXT;
    v_avatar_url TEXT;
    v_is_institutional BOOLEAN := false;
    v_verification_status TEXT := 'unverified';
    v_college TEXT := 'MANIT Bhopal';
BEGIN
    -- Determine display name from user metadata or email prefix
    v_display_name := coalesce(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'display_name',
        split_part(NEW.email, '@', 1)
    );

    v_avatar_url := NEW.raw_user_meta_data->>'avatar_url';

    -- Check institutional email domain (@stu.manit.ac.in or @manit.ac.in)
    IF NEW.email ILIKE '%@stu.manit.ac.in' OR NEW.email ILIKE '%@manit.ac.in' THEN
        v_is_institutional := true;
        -- If email is confirmed, mark verified; otherwise pending verification
        IF NEW.email_confirmed_at IS NOT NULL THEN
            v_verification_status := 'verified';
        ELSE
            v_verification_status := 'pending';
        END IF;
    END IF;

    INSERT INTO public.profiles (
        id,
        display_name,
        avatar_url,
        college_name,
        membership_status,
        membership_verification_status,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        coalesce(v_display_name, 'MANIT Scholar'),
        v_avatar_url,
        v_college,
        CASE WHEN v_is_institutional THEN 'manitStudent' ELSE 'nonStudent' END,
        v_verification_status,
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Note: In production Supabase, the trigger below binds to auth.users.
-- We wrap in DO block to avoid failure if running in an environment without auth schema yet.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'auth' AND table_name = 'users'
    ) THEN
        DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_new_auth_user();
    END IF;
END $$;
