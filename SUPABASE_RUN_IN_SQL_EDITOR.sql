-- MANIT TeamUp: Supabase PostgreSQL Schema Migration
-- Migration: 20261021000001_initial_schema.sql
-- Description: Creates core database tables, constraints, foreign keys, and indexes.

-- Enable pgcrypto for UUID generation if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. PROFILES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    college_name TEXT NOT NULL DEFAULT 'MANIT Bhopal',
    membership_status TEXT NOT NULL DEFAULT 'manitStudent' 
        CHECK (membership_status IN ('manitStudent', 'otherCollege', 'nonStudent')),
    membership_verification_status TEXT NOT NULL DEFAULT 'unverified' 
        CHECK (membership_verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
    branch TEXT NOT NULL DEFAULT 'Computer Science & Engineering',
    academic_year TEXT NOT NULL DEFAULT '1st Year B.Tech',
    bio TEXT NOT NULL DEFAULT '',
    skills TEXT[] NOT NULL DEFAULT '{}',
    interests TEXT[] NOT NULL DEFAULT '{}',
    portfolio_url TEXT,
    scholar_number TEXT,
    github_url TEXT,
    linkedin_url TEXT,
    whatsapp_number TEXT,
    is_profile_public BOOLEAN NOT NULL DEFAULT true,
    allow_whatsapp_direct BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_college_name 
    ON public.profiles(college_name);
CREATE INDEX IF NOT EXISTS idx_profiles_verification_status 
    ON public.profiles(membership_verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_membership_status 
    ON public.profiles(membership_status);
CREATE INDEX IF NOT EXISTS idx_profiles_skills 
    ON public.profiles USING GIN (skills);
CREATE INDEX IF NOT EXISTS idx_profiles_interests 
    ON public.profiles USING GIN (interests);

-- =============================================================================
-- 2. TEAMS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 2),
    description TEXT,
    category TEXT NOT NULL CHECK (
        category IN ('hackathon', 'academicProject', 'startup', 'aiMl', 'openSource', 'competitiveProgramming')
    ),
    event_name TEXT,
    required_skills TEXT[] NOT NULL DEFAULT '{}',
    max_members INTEGER NOT NULL DEFAULT 4 CHECK (max_members >= 1 AND max_members <= 30),
    recruitment_status TEXT NOT NULL DEFAULT 'open' CHECK (
        recruitment_status IN ('open', 'closed', 'paused')
    ),
    whatsapp_group_link TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Teams Indexes
CREATE INDEX IF NOT EXISTS idx_teams_owner_id 
    ON public.teams(owner_id);
CREATE INDEX IF NOT EXISTS idx_teams_category 
    ON public.teams(category);
CREATE INDEX IF NOT EXISTS idx_teams_recruitment_status 
    ON public.teams(recruitment_status);
CREATE INDEX IF NOT EXISTS idx_teams_created_at 
    ON public.teams(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_teams_required_skills 
    ON public.teams USING GIN (required_skills);

-- =============================================================================
-- 3. TEAM MEMBERS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'lead', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_team_member UNIQUE (team_id, user_id)
);

-- Team Members Indexes
CREATE INDEX IF NOT EXISTS idx_team_members_team_id 
    ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id 
    ON public.team_members(user_id);

-- =============================================================================
-- 4. JOIN REQUESTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL CHECK (char_length(trim(message)) >= 1),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'accepted', 'rejected', 'withdrawn')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Prevent duplicate active (pending) requests for the same team by the same requester
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_join_request 
    ON public.join_requests(team_id, requester_id) 
    WHERE (status = 'pending');

-- Join Requests Indexes
CREATE INDEX IF NOT EXISTS idx_join_requests_team_id 
    ON public.join_requests(team_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_requester_id 
    ON public.join_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status 
    ON public.join_requests(status);

-- =============================================================================
-- 5. NOTIFICATIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (
        type IN ('joinRequest', 'requestAccepted', 'requestRejected', 'requestWithdrawn', 'teamAnnouncement', 'directMessage')
    ),
    title TEXT NOT NULL CHECK (char_length(trim(title)) >= 1),
    body TEXT NOT NULL CHECK (char_length(trim(body)) >= 1),
    related_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created 
    ON public.notifications(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
    ON public.notifications(recipient_id) 
    WHERE (read_at IS NULL);

-- =============================================================================
-- 6. BLOCKS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.blocks (
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (blocker_id, blocked_id),
    CONSTRAINT chk_no_self_block CHECK (blocker_id <> blocked_id)
);

-- Blocks Index
CREATE INDEX IF NOT EXISTS idx_blocks_blocked_id 
    ON public.blocks(blocked_id);

-- =============================================================================
-- 7. REPORTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 2),
    details TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'under_review', 'resolved', 'dismissed')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_report_target CHECK (reported_user_id IS NOT NULL OR team_id IS NOT NULL)
);

-- Reports Indexes
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id 
    ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id 
    ON public.reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_team_id 
    ON public.reports(team_id);
CREATE INDEX IF NOT EXISTS idx_reports_status 
    ON public.reports(status);
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
        'Request Accepted! ðŸŽ‰',
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
-- MANIT TeamUp: Supabase Row Level Security (RLS) Policies
-- Migration: 20261021000003_row_level_security.sql
-- Description: Enables and enforces Row Level Security on all exposed tables with least-privilege policies.

-- =============================================================================
-- 1. ENABLE AND FORCE RLS ON ALL TABLES
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams FORCE ROW LEVEL SECURITY;

ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members FORCE ROW LEVEL SECURITY;

ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests FORCE ROW LEVEL SECURITY;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications FORCE ROW LEVEL SECURITY;

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks FORCE ROW LEVEL SECURITY;

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports FORCE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. PROFILES POLICIES
-- =============================================================================

-- SELECT: Users can view their own profile, or public profiles if not mutually blocked,
-- or teammates' profiles even if marked private.
CREATE POLICY "profiles_select_policy"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = id
        OR (
            NOT public.are_users_mutually_blocked(auth.uid(), id)
            AND (
                is_profile_public = true
                OR EXISTS (
                    SELECT 1 
                    FROM public.team_members m1
                    JOIN public.team_members m2 ON m1.team_id = m2.team_id
                    WHERE m1.user_id = auth.uid() 
                      AND m2.user_id = profiles.id
                )
            )
        )
    );

-- INSERT: Authenticated users can insert their own profile row
CREATE POLICY "profiles_insert_policy"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- UPDATE: Users may edit only their own permitted profile fields
CREATE POLICY "profiles_update_policy"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- DELETE: Users can delete their own profile (in addition to auth.users cascade)
CREATE POLICY "profiles_delete_policy"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- =============================================================================
-- 3. TEAMS POLICIES
-- =============================================================================

-- SELECT: Teams are visible to authenticated users if not blocked by the team owner
CREATE POLICY "teams_select_policy"
    ON public.teams
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = owner_id
        OR NOT public.are_users_mutually_blocked(auth.uid(), owner_id)
    );

-- INSERT: Only authenticated users can create teams, setting themselves as owner
CREATE POLICY "teams_insert_policy"
    ON public.teams
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = owner_id);

-- UPDATE: Only authorized team owners may manage/update their teams
CREATE POLICY "teams_update_policy"
    ON public.teams
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- DELETE: Only authorized team owners may delete their teams
CREATE POLICY "teams_delete_policy"
    ON public.teams
    FOR DELETE
    TO authenticated
    USING (auth.uid() = owner_id);

-- =============================================================================
-- 4. TEAM MEMBERS POLICIES
-- =============================================================================

-- SELECT: Members of visible teams are viewable by authenticated users
CREATE POLICY "team_members_select_policy"
    ON public.team_members
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.teams 
            WHERE teams.id = team_members.team_id
              AND (
                  teams.owner_id = auth.uid() 
                  OR NOT public.are_users_mutually_blocked(auth.uid(), teams.owner_id)
              )
        )
    );

-- INSERT: Direct client inserts are NOT permitted.
-- Team membership must be created through authorized operations:
-- (1) Automatic owner insertion on team creation trigger.
-- (2) Concurrency-safe accept_join_request() RPC.
-- Hence no INSERT policy for authenticated role, preserving authorization invariants.

-- UPDATE: Team owner can reassign non-owner roles (e.g. member -> lead)
CREATE POLICY "team_members_update_policy"
    ON public.team_members
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.teams 
            WHERE teams.id = team_members.team_id 
              AND teams.owner_id = auth.uid()
        )
        AND team_members.role <> 'owner'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.teams 
            WHERE teams.id = team_members.team_id 
              AND teams.owner_id = auth.uid()
        )
        AND team_members.role IN ('lead', 'member')
    );

-- DELETE: Members can voluntarily leave; owners can remove non-owner members
CREATE POLICY "team_members_delete_policy"
    ON public.team_members
    FOR DELETE
    TO authenticated
    USING (
        -- Member leaving themselves (owners cannot leave via delete; must delete team or transfer)
        (auth.uid() = user_id AND role <> 'owner')
        OR
        -- Owner removing a member
        (
            EXISTS (
                SELECT 1 FROM public.teams 
                WHERE teams.id = team_members.team_id 
                  AND teams.owner_id = auth.uid()
            )
            AND role <> 'owner'
        )
    );

-- =============================================================================
-- 5. JOIN REQUESTS POLICIES
-- =============================================================================

-- SELECT: Requester or team owner can view the join request
CREATE POLICY "join_requests_select_policy"
    ON public.join_requests
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = requester_id
        OR EXISTS (
            SELECT 1 FROM public.teams 
            WHERE teams.id = join_requests.team_id 
              AND teams.owner_id = auth.uid()
        )
    );

-- INSERT: Requester can submit pending request if not blocked and team is open
CREATE POLICY "join_requests_insert_policy"
    ON public.join_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = requester_id
        AND status = 'pending'
        AND EXISTS (
            SELECT 1 FROM public.teams 
            WHERE teams.id = join_requests.team_id
              AND teams.owner_id <> auth.uid()
              AND teams.recruitment_status = 'open'
              AND NOT public.are_users_mutually_blocked(auth.uid(), teams.owner_id)
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.team_members 
            WHERE team_members.team_id = join_requests.team_id 
              AND team_members.user_id = auth.uid()
        )
    );

-- UPDATE:
-- (1) Requester may withdraw their own pending request.
-- (2) Owner may reject a pending request.
-- (Direct acceptance via SQL UPDATE is blocked; owner must invoke accept_join_request RPC).
CREATE POLICY "join_requests_update_policy"
    ON public.join_requests
    FOR UPDATE
    TO authenticated
    USING (
        (auth.uid() = requester_id AND status = 'pending')
        OR
        (
            EXISTS (
                SELECT 1 FROM public.teams 
                WHERE teams.id = join_requests.team_id 
                  AND teams.owner_id = auth.uid()
            )
            AND status = 'pending'
        )
    )
    WITH CHECK (
        -- Requester withdrawing
        (auth.uid() = requester_id AND status = 'withdrawn')
        OR
        -- Team owner rejecting
        (
            EXISTS (
                SELECT 1 FROM public.teams 
                WHERE teams.id = join_requests.team_id 
                  AND teams.owner_id = auth.uid()
            )
            AND status = 'rejected'
        )
    );

-- DELETE: Requester can clean up their withdrawn or rejected requests
CREATE POLICY "join_requests_delete_policy"
    ON public.join_requests
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() = requester_id
        AND status IN ('withdrawn', 'rejected')
    );

-- =============================================================================
-- 6. NOTIFICATIONS POLICIES
-- =============================================================================

-- SELECT: Recipients can view their own notifications
CREATE POLICY "notifications_select_policy"
    ON public.notifications
    FOR SELECT
    TO authenticated
    USING (auth.uid() = recipient_id);

-- INSERT: Disallow direct client inserts; notifications are driven by system triggers/RPCs
-- (service_role retains bypassrls access)

-- UPDATE: Recipient can mark notification as read
CREATE POLICY "notifications_update_policy"
    ON public.notifications
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = recipient_id)
    WITH CHECK (auth.uid() = recipient_id);

-- DELETE: Recipient can delete notifications
CREATE POLICY "notifications_delete_policy"
    ON public.notifications
    FOR DELETE
    TO authenticated
    USING (auth.uid() = recipient_id);

-- =============================================================================
-- 7. BLOCKS POLICIES
-- =============================================================================

-- SELECT: Users can only view who they have blocked (not who blocked them)
CREATE POLICY "blocks_select_policy"
    ON public.blocks
    FOR SELECT
    TO authenticated
    USING (auth.uid() = blocker_id);

-- INSERT: Blocker can block someone other than themselves
CREATE POLICY "blocks_insert_policy"
    ON public.blocks
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = blocker_id 
        AND blocker_id <> blocked_id
    );

-- DELETE: Blocker can unblock
CREATE POLICY "blocks_delete_policy"
    ON public.blocks
    FOR DELETE
    TO authenticated
    USING (auth.uid() = blocker_id);

-- =============================================================================
-- 8. REPORTS POLICIES
-- =============================================================================

-- SELECT: Reporter can view reports they submitted
CREATE POLICY "reports_select_policy"
    ON public.reports
    FOR SELECT
    TO authenticated
    USING (auth.uid() = reporter_id);

-- INSERT: Authenticated user can submit a report with initial 'pending' status
CREATE POLICY "reports_insert_policy"
    ON public.reports
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = reporter_id
        AND status = 'pending'
    );

-- UPDATE: Clients CANNOT update reports under any circumstances.
-- "Prevent clients from modifying administrative report status."
-- Only administrative service_role can update report status.
-- (No UPDATE policy defined for authenticated role).

-- DELETE: Clients CANNOT delete submitted reports.
-- (No DELETE policy defined for authenticated role).
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
            'New Join Request ðŸ“©',
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
-- MANIT TeamUp: College Membership & Verification System
-- Migration: 20261021000005_college_membership_and_verification.sql
-- Description: Supports pending_review verification status, authorized verification workflow RPC,
-- student verification submission, and secure discoverable profiles view excluding sensitive PII.

-- =============================================================================
-- 1. UPDATE VERIFICATION STATUS CHECK CONSTRAINT
-- =============================================================================
ALTER TABLE public.profiles 
    DROP CONSTRAINT IF EXISTS profiles_membership_verification_status_check;

ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_membership_verification_status_check 
    CHECK (membership_verification_status IN ('unverified', 'pending', 'pending_review', 'verified', 'rejected'));

-- =============================================================================
-- 2. USER RPC: REQUEST VERIFICATION (SUBMIT FOR REVIEW)
-- =============================================================================
-- Ordinary MANIT students can transition their status from 'unverified' to 'pending_review'.
-- They can NEVER assign themselves 'verified'.
CREATE OR REPLACE FUNCTION public.submit_for_verification(
    p_scholar_number TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to submit for verification';
    END IF;

    SELECT * INTO v_profile 
    FROM public.profiles 
    WHERE id = v_caller_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found for authenticated user';
    END IF;

    IF v_profile.membership_status <> 'manitStudent' THEN
        RAISE EXCEPTION 'Only MANIT students are eligible for MANIT institutional verification';
    END IF;

    IF v_profile.membership_verification_status = 'verified' THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Account is already verified as a MANIT Scholar',
            'status', 'verified'
        );
    END IF;

    UPDATE public.profiles
    SET 
        membership_verification_status = 'pending_review',
        scholar_number = coalesce(p_scholar_number, scholar_number),
        updated_at = timezone('utc'::text, now())
    WHERE id = v_caller_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Verification request submitted for institutional review',
        'status', 'pending_review'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_for_verification(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_for_verification(TEXT) TO authenticated, service_role;

-- =============================================================================
-- 3. ADMINISTRATIVE WORKFLOW RPC: REVIEW MEMBERSHIP VERIFICATION
-- =============================================================================
-- Only authorized service_role or admin processes can grant 'verified' or 'rejected'.
CREATE OR REPLACE FUNCTION public.review_membership_verification(
    p_target_user_id UUID,
    p_new_status TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_profile RECORD;
BEGIN
    -- Strict authorization check: Only service_role or database admin can approve
    IF (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' 
       AND current_user NOT IN ('postgres', 'supabase_admin') THEN
        RAISE EXCEPTION 'Unauthorized: Only institutional verification authorities may review credentials';
    END IF;

    IF p_new_status NOT IN ('unverified', 'pending_review', 'verified', 'rejected') THEN
        RAISE EXCEPTION 'Invalid verification status: %', p_new_status;
    END IF;

    SELECT * INTO v_target_profile 
    FROM public.profiles 
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target scholar profile not found: %', p_target_user_id;
    END IF;

    UPDATE public.profiles
    SET 
        membership_verification_status = p_new_status,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_target_user_id;

    -- Generate notification for the user
    IF p_new_status = 'verified' THEN
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body
        ) VALUES (
            p_target_user_id,
            'teamAnnouncement',
            'Scholar Verification Approved! ðŸŽ“',
            'Congratulations! Your MANIT scholar verification is approved. You now hold the Verified Scholar badge.'
        );
    ELSIF p_new_status = 'rejected' THEN
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body
        ) VALUES (
            p_target_user_id,
            'teamAnnouncement',
            'Verification Review Update',
            coalesce(p_notes, 'Your scholar verification could not be approved. Please check your credentials.')
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', p_target_user_id,
        'status', p_new_status
    );
END;
$$;

REVOKE ALL ON FUNCTION public.review_membership_verification(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.review_membership_verification(UUID, TEXT, TEXT) TO service_role;

-- =============================================================================
-- 4. SECURE DISCOVERABLE SCHOLAR PROFILES VIEW
-- =============================================================================
-- Protects sensitive student PII: Excludes scholar_number and private contact information
-- Exposes only public collaboration information.
CREATE OR REPLACE VIEW public.discoverable_profiles AS
SELECT 
    p.id,
    p.display_name,
    p.avatar_url,
    p.college_name,
    p.membership_status,
    p.membership_verification_status,
    (p.membership_status = 'manitStudent' AND p.membership_verification_status = 'verified') AS is_manit_verified,
    p.branch,
    p.academic_year,
    p.bio,
    p.skills,
    p.interests,
    p.portfolio_url,
    p.github_url,
    p.linkedin_url,
    p.created_at
FROM public.profiles p
WHERE p.is_profile_public = true;

GRANT SELECT ON public.discoverable_profiles TO authenticated;
-- MANIT TeamUp: Student Discovery Optimization & Privacy Hardening
-- Migration: 20261021000006_student_discovery_optimization.sql
-- Description: Adds indexes for frequently searched student fields (branch, academic_year,
-- display_name, pagination), and enforces security_invoker = true on discoverable_profiles
-- to ensure block relationships and Row Level Security are strictly respected.

-- =============================================================================
-- 1. FREQUENTLY SEARCHED DISCOVERY INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_branch 
    ON public.profiles(branch);

CREATE INDEX IF NOT EXISTS idx_profiles_academic_year 
    ON public.profiles(academic_year);

CREATE INDEX IF NOT EXISTS idx_profiles_display_name 
    ON public.profiles(display_name);

-- Composite index for paginated public discovery
CREATE INDEX IF NOT EXISTS idx_profiles_discovery_paging 
    ON public.profiles(is_profile_public, created_at DESC);

-- =============================================================================
-- 2. SECURITY-INVOKER DISCOVERABLE PROFILES VIEW
-- =============================================================================
-- Setting security_invoker = true ensures that queries execute under the caller's
-- authenticated role, strictly respecting profiles_select_policy:
-- - Mutual block relationships are enforced (are_users_mutually_blocked)
-- - Private profiles (is_profile_public = false) are never exposed to non-teammates
-- - Sensitive columns (scholar_number, whatsapp_number) are omitted from the projection
CREATE OR REPLACE VIEW public.discoverable_profiles 
WITH (security_invoker = true) AS
SELECT 
    p.id,
    p.display_name,
    p.avatar_url,
    p.college_name,
    p.membership_status,
    p.membership_verification_status,
    (p.membership_status = 'manitStudent' AND p.membership_verification_status = 'verified') AS is_manit_verified,
    p.branch,
    p.academic_year,
    p.bio,
    p.skills,
    p.interests,
    p.portfolio_url,
    p.github_url,
    p.linkedin_url,
    p.created_at
FROM public.profiles p
WHERE p.is_profile_public = true;

GRANT SELECT ON public.discoverable_profiles TO authenticated;
-- MANIT TeamUp: Team Discovery & Management Performance Indexes
-- Migration: 20261021000007_team_discovery_and_management.sql
-- Description: Adds indexes for team search, event filtering, and open team browsing.

-- =============================================================================
-- 1. FREQUENTLY SEARCHED TEAM FIELDS INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_teams_name 
    ON public.teams(name);

CREATE INDEX IF NOT EXISTS idx_teams_event_name 
    ON public.teams(event_name);

-- Composite index for browsing open recruitment teams sorted by newest
CREATE INDEX IF NOT EXISTS idx_teams_open_browse 
    ON public.teams(recruitment_status, created_at DESC);

-- Index on team members for fast membership queries
CREATE INDEX IF NOT EXISTS idx_team_members_team_role 
    ON public.team_members(team_id, role);
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
        'Request Accepted! ðŸŽ‰',
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
            'New Join Request ðŸ“©',
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
