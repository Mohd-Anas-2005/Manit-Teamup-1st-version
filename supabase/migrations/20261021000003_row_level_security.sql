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
