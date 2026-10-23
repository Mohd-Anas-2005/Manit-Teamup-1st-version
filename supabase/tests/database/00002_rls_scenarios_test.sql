-- pgTAP Automated RLS Scenario Tests for MANIT TeamUp
-- Test File: supabase/tests/database/00002_rls_scenarios_test.sql
-- Description: Verifies authorization, security constraints, RPC concurrency controls, and tamper resistance.

BEGIN;
SELECT plan(15);

-- Setup Mock Test Users in auth.users
CREATE SCHEMA IF NOT EXISTS auth;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        CREATE TABLE auth.users (
            id UUID PRIMARY KEY,
            email TEXT,
            email_confirmed_at TIMESTAMPTZ,
            raw_user_meta_data JSONB
        );
    END IF;
END $$;

-- Insert test users
INSERT INTO auth.users (id, email)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'student1@stu.manit.ac.in'),
    ('22222222-2222-2222-2222-222222222222', 'student2@stu.manit.ac.in'),
    ('33333333-3333-3333-3333-333333333333', 'attacker@other.com')
ON CONFLICT (id) DO NOTHING;

-- 1. Verify Profile Creation
INSERT INTO public.profiles (id, display_name, membership_verification_status)
VALUES ('11111111-1111-1111-1111-111111111111', 'Alice', 'unverified')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, membership_verification_status)
VALUES ('22222222-2222-2222-2222-222222222222', 'Bob', 'unverified')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, membership_verification_status)
VALUES ('33333333-3333-3333-3333-333333333333', 'Charlie', 'unverified')
ON CONFLICT (id) DO NOTHING;

SELECT ok(
    EXISTS (SELECT 1 FROM public.profiles WHERE id = '11111111-1111-1111-1111-111111111111'),
    'Test profiles seeded successfully'
);

-- 2. Scenario: User cannot tamper with their membership_verification_status
SELECT throws_ok(
    $$ 
        UPDATE public.profiles 
        SET membership_verification_status = 'verified' 
        WHERE id = '11111111-1111-1111-1111-111111111111' 
    $$,
    'A user may not assign or modify their own membership verification status',
    'Self-assigning verified status must be rejected'
);

-- 3. Scenario: User cannot change their profile id
SELECT throws_ok(
    $$ 
        UPDATE public.profiles 
        SET id = '44444444-4444-4444-4444-444444444444' 
        WHERE id = '11111111-1111-1111-1111-111111111111' 
    $$,
    'Profile ID is immutable',
    'Mutating profile ID must be rejected'
);

-- 4. Scenario: Creating a team automatically adds the owner as 'owner' in team_members
INSERT INTO public.teams (id, owner_id, name, category, max_members, recruitment_status)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'AI Innovators',
    'hackathon',
    2,
    'open'
);

SELECT is(
    (SELECT role FROM public.team_members WHERE team_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' AND user_id = '11111111-1111-1111-1111-111111111111'),
    'owner',
    'Team owner is automatically enrolled into team_members with role "owner"'
);

-- 5. Scenario: Team owner cannot be transferred directly
SELECT throws_ok(
    $$
        UPDATE public.teams
        SET owner_id = '22222222-2222-2222-2222-222222222222'
        WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    $$,
    'Team owner is immutable and cannot be transferred directly',
    'Direct team owner mutation must be rejected'
);

-- 6. Scenario: Duplicate membership is prevented
SELECT throws_ok(
    $$
        INSERT INTO public.team_members (team_id, user_id, role)
        VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'member')
    $$,
    '23505', -- unique_violation
    'Duplicate membership insertion must violate uniqueness constraint'
);

-- 7. Scenario: Submit join request creates notification for team owner
INSERT INTO public.join_requests (id, team_id, requester_id, message, status)
VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '22222222-2222-2222-2222-222222222222',
    'I would love to join your SIH team as a Flutter developer!',
    'pending'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE recipient_id = '11111111-1111-1111-1111-111111111111' 
          AND type = 'joinRequest'
          AND related_team_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    ),
    'Submitting join request triggers notification to team owner'
);

-- 8. Scenario: Duplicate active (pending) join request is rejected
SELECT throws_ok(
    $$
        INSERT INTO public.join_requests (team_id, requester_id, message, status)
        VALUES (
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            '22222222-2222-2222-2222-222222222222',
            'Another pending request',
            'pending'
        )
    $$,
    '23505', -- unique_violation on partial unique index
    'Duplicate active pending join request must be rejected'
);

-- 9. Scenario: Join request message cannot be tampered with after creation
SELECT throws_ok(
    $$
        UPDATE public.join_requests
        SET message = 'Tampered message'
        WHERE id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    $$,
    'Pitch message cannot be altered once submitted',
    'Modifying pitch message on join request must be rejected'
);

-- 10. Scenario: Non-owner cannot accept join requests
SELECT throws_ok(
    $$
        -- Simulate caller as student2 (not owner)
        SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
        SELECT public.accept_join_request('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    $$,
    'Unauthorized: Only the team owner can accept join requests',
    'Non-owner cannot accept join requests'
);

-- 11. Scenario: Owner accepts join request -> added to team & notification generated
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT ok(
    (public.accept_join_request('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') ->> 'success')::boolean,
    'Team owner successfully accepts join request via concurrency-safe RPC'
);

SELECT is(
    (SELECT status FROM public.join_requests WHERE id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    'accepted',
    'Join request status updated to "accepted"'
);

SELECT is(
    (SELECT recruitment_status FROM public.teams WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    'closed',
    'Team recruitment_status auto-closed when max capacity (2 members) reached'
);

-- 12. Scenario: Capacity check prevents exceeding max_members
INSERT INTO public.join_requests (id, team_id, requester_id, message, status)
VALUES (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '33333333-3333-3333-3333-333333333333',
    'Attempting to join full team',
    'pending'
);

SELECT throws_ok(
    $$
        SELECT public.accept_join_request('cccccccc-cccc-cccc-cccc-cccccccccccc');
    $$,
    'Team is not currently recruiting (status: closed)',
    'Acceptance into a full or closed team must be blocked'
);

-- 13. Scenario: Administrative report status cannot be modified by regular clients
INSERT INTO public.reports (id, reporter_id, reported_user_id, reason, status)
VALUES (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    '11111111-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333333',
    'Inappropriate behavior',
    'pending'
);

SELECT throws_ok(
    $$
        UPDATE public.reports
        SET status = 'resolved'
        WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'
    $$,
    'Clients are not permitted to modify reports or administrative report status',
    'Client modification of report status must be rejected'
);

SELECT * FROM finish();
ROLLBACK;
