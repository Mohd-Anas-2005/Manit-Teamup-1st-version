-- MANIT TeamUp: Complete Team-Joining Workflow Migration
-- Migration: 20261021000008_team_joining_workflow.sql
-- Description: Enforces PostgreSQL authorization, capacity invariants, optional pitch note,
--              concurrency-safe acceptance/rejection/withdrawal RPCs, and automated notifications.

-- =============================================================================
-- 1. SCHEMA REFINEMENT: OPTIONAL INTRODUCTION MESSAGE & REFERENTIAL INTEGRITY
-- =============================================================================

-- Allow optional introduction/pitch messages (can be empty string or NULL)
ALTER TABLE public.join_requests 
    ALTER COLUMN message DROP NOT NULL;

ALTER TABLE public.join_requests 
    ALTER COLUMN message SET DEFAULT '';

-- Drop legacy non-empty message check constraint if present
ALTER TABLE public.join_requests 
    DROP CONSTRAINT IF EXISTS join_requests_message_check;

-- Add updated check constraint allowing optional empty or reasonable length messages
ALTER TABLE public.join_requests 
    ADD CONSTRAINT chk_join_requests_message_length 
    CHECK (message IS NULL OR char_length(message) <= 2000);

-- Ensure foreign key relationship between join_requests and profiles for seamless joins
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_join_requests_requester_profile'
    ) THEN 
        ALTER TABLE public.join_requests 
            ADD CONSTRAINT fk_join_requests_requester_profile 
            FOREIGN KEY (requester_id) REFERENCES public.profiles(id) ON DELETE CASCADE; 
    END IF; 
END $$;

-- Index to optimize querying sent requests by user and status
CREATE INDEX IF NOT EXISTS idx_join_requests_requester_status 
    ON public.join_requests(requester_id, status);

-- Composite index to optimize owner incoming request queries
CREATE INDEX IF NOT EXISTS idx_join_requests_team_status_created 
    ON public.join_requests(team_id, status, created_at DESC);

-- =============================================================================
-- 2. DATABASE TRIGGER: ENFORCE JOIN REQUEST INSERTION INVARIANTS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.trg_enforce_join_request_invariants()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_team RECORD;
    v_current_count INTEGER;
BEGIN
    -- 1. Initial status MUST be 'pending'
    IF NEW.status <> 'pending' THEN
        RAISE EXCEPTION 'New joining requests must be initialized with status "pending" (received: %)', NEW.status;
    END IF;

    -- 2. Verify team exists
    SELECT * INTO v_team
    FROM public.teams
    WHERE id = NEW.team_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target team does not exist with ID: %', NEW.team_id;
    END IF;

    -- 3. Verify team is open for recruitment
    IF v_team.recruitment_status <> 'open' THEN
        RAISE EXCEPTION 'Team "%" is not currently open for recruitment (status: %)', v_team.name, v_team.recruitment_status;
    END IF;

    -- 4. Verify team capacity limit is not exceeded
    SELECT COUNT(*) INTO v_current_count
    FROM public.team_members
    WHERE team_id = v_team.id;

    IF v_current_count >= v_team.max_members THEN
        RAISE EXCEPTION 'Team "%" has reached maximum capacity (% of % members)', v_team.name, v_current_count, v_team.max_members;
    END IF;

    -- 5. Prevent team owner from submitting joining requests to their own team
    IF v_team.owner_id = NEW.requester_id THEN
        RAISE EXCEPTION 'Team owner cannot submit a joining request to their own team';
    END IF;

    -- 6. Prevent existing team members from submitting redundant requests
    IF EXISTS (
        SELECT 1 FROM public.team_members
        WHERE team_id = NEW.team_id AND user_id = NEW.requester_id
    ) THEN
        RAISE EXCEPTION 'User is already an enrolled member of this team roster';
    END IF;

    -- 7. Enforce privacy and blocking constraints
    IF public.are_users_mutually_blocked(NEW.requester_id, v_team.owner_id) THEN
        RAISE EXCEPTION 'Cannot submit joining request due to privacy or block restrictions';
    END IF;

    -- Set default empty string if message is null
    IF NEW.message IS NULL THEN
        NEW.message := '';
    END IF;

    NEW.created_at := coalesce(NEW.created_at, timezone('utc'::text, now()));
    NEW.updated_at := timezone('utc'::text, now());

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_join_requests_invariants ON public.join_requests;
CREATE TRIGGER trg_join_requests_invariants
    BEFORE INSERT ON public.join_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_join_request_invariants();

-- =============================================================================
-- 3. DATABASE TRIGGER: JOIN REQUEST IMMUTABILITY & STATUS INTEGRITY
-- =============================================================================

CREATE OR REPLACE FUNCTION public.trg_enforce_join_request_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Core identity columns cannot be altered once created
    IF NEW.id <> OLD.id OR NEW.team_id <> OLD.team_id OR NEW.requester_id <> OLD.requester_id THEN
        RAISE EXCEPTION 'Core join request identifiers are immutable';
    END IF;

    -- Pitch note is immutable after submission
    IF NEW.message IS DISTINCT FROM OLD.message THEN
        RAISE EXCEPTION 'Pitch message cannot be altered once submitted';
    END IF;

    -- Created_at timestamp cannot be changed
    IF NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'Creation timestamp is immutable';
    END IF;

    -- Prevent modifying status once it has transitioned out of 'pending'
    IF OLD.status IN ('accepted', 'rejected', 'withdrawn') AND NEW.status <> OLD.status THEN
        RAISE EXCEPTION 'Cannot alter status of a resolved join request (current status: %)', OLD.status;
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
-- 4. CONCURRENCY-SAFE RPC: SUBMIT JOIN REQUEST
-- =============================================================================

CREATE OR REPLACE FUNCTION public.submit_join_request(
    p_team_id UUID,
    p_message TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_request_id UUID;
    v_clean_message TEXT;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to submit a join request';
    END IF;

    v_clean_message := coalesce(trim(p_message), '');

    -- Insert into join_requests (triggers will validate recruitment, capacity, blocks, duplicates)
    INSERT INTO public.join_requests (
        team_id,
        requester_id,
        message,
        status
    ) VALUES (
        p_team_id,
        v_caller_id,
        v_clean_message,
        'pending'
    )
    RETURNING id INTO v_request_id;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', v_request_id,
        'team_id', p_team_id,
        'requester_id', v_caller_id,
        'status', 'pending',
        'message', v_clean_message
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_join_request(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_join_request(UUID, TEXT) TO authenticated, service_role;

-- =============================================================================
-- 5. CONCURRENCY-SAFE RPC: ACCEPT JOIN REQUEST (UPDATED & HARDENED)
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

    -- 2. Lock the associated team row exclusively to prevent concurrent acceptance races
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

    -- 7. Insert new member atomically (only after validation passes)
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
-- 6. RPC: REJECT JOIN REQUEST (UPDATED & HARDENED)
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
-- 7. RPC: WITHDRAW JOIN REQUEST (UPDATED & HARDENED)
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

    IF v_team.owner_id IS NOT NULL THEN
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

-- =============================================================================
-- 8. QUERY RPCs: INCOMING & SENT JOIN REQUESTS
-- =============================================================================

-- Fetch incoming requests for teams owned by current authenticated user
CREATE OR REPLACE FUNCTION public.get_incoming_join_requests()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_result JSONB;
BEGIN
    IF v_caller_id IS NULL THEN
        RETURN '[]'::jsonb;
    END IF;

    SELECT coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id', r.id,
                'team_id', r.team_id,
                'team_title', t.name,
                'applicant_id', r.requester_id,
                'applicant_name', coalesce(p.display_name, 'Student Applicant'),
                'applicant_branch', coalesce(p.branch, 'Engineering'),
                'applicant_year', coalesce(p.academic_year, 'Student'),
                'applicant_college', coalesce(p.college_name, 'MANIT Bhopal'),
                'applicant_is_manit_verified', (p.membership_verification_status = 'verified'),
                'applicant_skills', coalesce(p.skills, '{}'::text[]),
                'pitch_note', coalesce(r.message, ''),
                'status', r.status,
                'created_at', r.created_at
            )
            ORDER BY r.created_at DESC
        ),
        '[]'::jsonb
    ) INTO v_result
    FROM public.join_requests r
    JOIN public.teams t ON t.id = r.team_id
    LEFT JOIN public.profiles p ON p.id = r.requester_id
    WHERE t.owner_id = v_caller_id;

    RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_incoming_join_requests() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_incoming_join_requests() TO authenticated, service_role;

-- Fetch requests sent by current authenticated user
CREATE OR REPLACE FUNCTION public.get_sent_join_requests()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_result JSONB;
BEGIN
    IF v_caller_id IS NULL THEN
        RETURN '[]'::jsonb;
    END IF;

    SELECT coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id', r.id,
                'team_id', r.team_id,
                'team_title', coalesce(t.name, 'Team Roster'),
                'applicant_id', r.requester_id,
                'applicant_name', coalesce(p.display_name, 'Me'),
                'applicant_branch', coalesce(p.branch, ''),
                'applicant_year', coalesce(p.academic_year, ''),
                'applicant_college', coalesce(p.college_name, 'MANIT Bhopal'),
                'applicant_is_manit_verified', (p.membership_verification_status = 'verified'),
                'applicant_skills', coalesce(p.skills, '{}'::text[]),
                'pitch_note', coalesce(r.message, ''),
                'status', r.status,
                'created_at', r.created_at
            )
            ORDER BY r.created_at DESC
        ),
        '[]'::jsonb
    ) INTO v_result
    FROM public.join_requests r
    LEFT JOIN public.teams t ON t.id = r.team_id
    LEFT JOIN public.profiles p ON p.id = r.requester_id
    WHERE r.requester_id = v_caller_id;

    RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_sent_join_requests() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_sent_join_requests() TO authenticated, service_role;
