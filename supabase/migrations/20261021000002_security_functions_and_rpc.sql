-- MANIT TeamUp: Supabase PostgreSQL Security Functions and RPCs
-- Migration: 20261021000002_security_functions_and_rpc.sql
-- Description: Security-definer functions, concurrency-safe RPCs, and explicit search_path enforcement.

-- =============================================================================
-- 1. MUTUAL BLOCK HELPER FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.are_users_mutually_blocked(
    user_a UUID,
    user_b UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.blocks 
        WHERE (blocker_id = user_a AND blocked_id = user_b)
           OR (blocker_id = user_b AND blocked_id = user_a)
    );
$$;

-- Restrict execution to authenticated users and service_role
REVOKE ALL ON FUNCTION public.are_users_mutually_blocked(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.are_users_mutually_blocked(UUID, UUID) TO authenticated, service_role;

-- =============================================================================
-- 2. TEAM OWNER VERIFICATION HELPER FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.is_team_owner(
    p_team_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.teams 
        WHERE id = p_team_id 
          AND owner_id = p_user_id
    );
$$;

REVOKE ALL ON FUNCTION public.is_team_owner(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_team_owner(UUID, UUID) TO authenticated, service_role;

-- =============================================================================
-- 3. CONCURRENCY-SAFE RPC: ACCEPT JOIN REQUEST
-- =============================================================================
CREATE OR REPLACE FUNCTION public.accept_join_request(
    p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_request RECORD;
    v_team RECORD;
    v_current_count INTEGER;
    v_new_count INTEGER;
    v_is_now_full BOOLEAN;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to perform this action';
    END IF;

    -- 1. Lock the join request row exclusively
    SELECT * INTO v_request
    FROM public.join_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Join request not found with ID: %', p_request_id;
    END IF;

    IF v_request.status <> 'pending' THEN
        RAISE EXCEPTION 'Cannot accept join request: current status is "%"', v_request.status;
    END IF;

    -- 2. Lock the associated team row to prevent concurrent acceptance races
    SELECT * INTO v_team
    FROM public.teams
    WHERE id = v_request.team_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Team not found for join request: %', v_request.team_id;
    END IF;

    -- 3. Security check: Caller must be the team owner
    IF v_team.owner_id <> v_caller_id THEN
        RAISE EXCEPTION 'Unauthorized: Only the team owner can accept join requests';
    END IF;

    -- 4. Check recruitment status
    IF v_team.recruitment_status <> 'open' THEN
        RAISE EXCEPTION 'Team is not currently recruiting (status: %)', v_team.recruitment_status;
    END IF;

    -- 5. Count current members within the locked transaction
    SELECT COUNT(*) INTO v_current_count
    FROM public.team_members
    WHERE team_id = v_team.id;

    IF v_current_count >= v_team.max_members THEN
        RAISE EXCEPTION 'Team has reached its maximum capacity of % members', v_team.max_members;
    END IF;

    -- 6. Check if requester is already a member
    IF EXISTS (
        SELECT 1 
        FROM public.team_members 
        WHERE team_id = v_team.id 
          AND user_id = v_request.requester_id
    ) THEN
        UPDATE public.join_requests
        SET status = 'accepted', updated_at = timezone('utc'::text, now())
        WHERE id = p_request_id;
        RAISE EXCEPTION 'Requester is already an active member of this team';
    END IF;

    -- 7. Insert new member atomically
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (v_team.id, v_request.requester_id, 'member', timezone('utc'::text, now()));

    v_new_count := v_current_count + 1;
    v_is_now_full := (v_new_count >= v_team.max_members);

    -- 8. Update request status to accepted
    UPDATE public.join_requests
    SET status = 'accepted', updated_at = timezone('utc'::text, now())
    WHERE id = p_request_id;

    -- 9. Auto-close recruitment if team reached maximum capacity
    IF v_is_now_full THEN
        UPDATE public.teams
        SET recruitment_status = 'closed', updated_at = timezone('utc'::text, now())
        WHERE id = v_team.id;
    END IF;

    -- 10. Automatically notify the applicant
    INSERT INTO public.notifications (
        recipient_id,
        type,
        title,
        body,
        related_team_id
    ) VALUES (
        v_request.requester_id,
        'requestAccepted',
        'Request Accepted! 🎉',
        'Your request to join "' || v_team.name || '" has been accepted.',
        v_team.id
    );

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'team_id', v_team.id,
        'member_id', v_request.requester_id,
        'member_count', v_new_count,
        'max_members', v_team.max_members,
        'recruitment_closed', v_is_now_full
    );
END;
$$;

REVOKE ALL ON FUNCTION public.accept_join_request(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_join_request(UUID) TO authenticated, service_role;

-- =============================================================================
-- 4. RPC: REJECT JOIN REQUEST
-- =============================================================================
CREATE OR REPLACE FUNCTION public.reject_join_request(
    p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_request RECORD;
    v_team RECORD;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to perform this action';
    END IF;

    -- Lock the request row
    SELECT * INTO v_request
    FROM public.join_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Join request not found with ID: %', p_request_id;
    END IF;

    IF v_request.status <> 'pending' THEN
        RAISE EXCEPTION 'Cannot reject join request: current status is "%"', v_request.status;
    END IF;

    -- Verify caller is team owner
    SELECT * INTO v_team
    FROM public.teams
    WHERE id = v_request.team_id;

    IF NOT FOUND OR v_team.owner_id <> v_caller_id THEN
        RAISE EXCEPTION 'Unauthorized: Only the team owner can reject join requests';
    END IF;

    -- Update request status
    UPDATE public.join_requests
    SET status = 'rejected', updated_at = timezone('utc'::text, now())
    WHERE id = p_request_id;

    -- Notify applicant
    INSERT INTO public.notifications (
        recipient_id,
        type,
        title,
        body,
        related_team_id
    ) VALUES (
        v_request.requester_id,
        'requestRejected',
        'Request Declined',
        'Your request to join "' || v_team.name || '" was not approved at this time.',
        v_team.id
    );

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'status', 'rejected'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.reject_join_request(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_join_request(UUID) TO authenticated, service_role;

-- =============================================================================
-- 5. RPC: WITHDRAW JOIN REQUEST
-- =============================================================================
CREATE OR REPLACE FUNCTION public.withdraw_join_request(
    p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_request RECORD;
    v_team RECORD;
    v_requester_name TEXT;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to perform this action';
    END IF;

    -- Lock the request row
    SELECT * INTO v_request
    FROM public.join_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Join request not found with ID: %', p_request_id;
    END IF;

    IF v_request.status <> 'pending' THEN
        RAISE EXCEPTION 'Cannot withdraw request: current status is "%"', v_request.status;
    END IF;

    -- Verify caller is the requester
    IF v_request.requester_id <> v_caller_id THEN
        RAISE EXCEPTION 'Unauthorized: You can only withdraw your own join requests';
    END IF;

    -- Update request status
    UPDATE public.join_requests
    SET status = 'withdrawn', updated_at = timezone('utc'::text, now())
    WHERE id = p_request_id;

    -- Retrieve team and requester info to notify owner
    SELECT * INTO v_team FROM public.teams WHERE id = v_request.team_id;
    SELECT display_name INTO v_requester_name FROM public.profiles WHERE id = v_caller_id;

    IF FOUND AND v_team.owner_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body,
            related_team_id
        ) VALUES (
            v_team.owner_id,
            'requestWithdrawn',
            'Application Withdrawn',
            coalesce(v_requester_name, 'An applicant') || ' withdrew their request for "' || v_team.name || '".',
            v_team.id
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'status', 'withdrawn'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.withdraw_join_request(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_join_request(UUID) TO authenticated, service_role;
