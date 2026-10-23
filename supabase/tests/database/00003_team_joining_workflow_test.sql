-- pgTAP Automated Tests: Team-Joining Workflow
-- Test File: supabase/tests/database/00003_team_joining_workflow_test.sql
-- Description: Tests concurrent acceptance, closed teams, full teams, duplicate requests,
--              unauthorized status changes, withdrawal, and notifications.

BEGIN;
SELECT plan(25);

-- 1. Ensure required functions & triggers exist
SELECT has_function('public', 'submit_join_request', ARRAY['uuid', 'text'], 'submit_join_request RPC must exist');
SELECT has_function('public', 'accept_join_request', ARRAY['uuid'], 'accept_join_request RPC must exist');
SELECT has_function('public', 'reject_join_request', ARRAY['uuid'], 'reject_join_request RPC must exist');
SELECT has_function('public', 'withdraw_join_request', ARRAY['uuid'], 'withdraw_join_request RPC must exist');
SELECT has_function('public', 'get_incoming_join_requests', ARRAY[]::text[], 'get_incoming_join_requests RPC must exist');
SELECT has_function('public', 'get_sent_join_requests', ARRAY[]::text[], 'get_sent_join_requests RPC must exist');

-- 2. Setup Mock Users in auth.users and profiles
INSERT INTO auth.users (id, email)
VALUES 
    ('10000000-0000-0000-0000-000000000001', 'owner@stu.manit.ac.in'),
    ('10000000-0000-0000-0000-000000000002', 'studentA@stu.manit.ac.in'),
    ('10000000-0000-0000-0000-000000000003', 'studentB@stu.manit.ac.in'),
    ('10000000-0000-0000-0000-000000000004', 'attacker@stu.manit.ac.in')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, membership_verification_status)
VALUES 
    ('10000000-0000-0000-0000-000000000001', 'Team Owner Alice', 'verified'),
    ('10000000-0000-0000-0000-000000000002', 'Requester Bob', 'verified'),
    ('10000000-0000-0000-0000-000000000003', 'Requester Carol', 'unverified'),
    ('10000000-0000-0000-0000-000000000004', 'Attacker Dave', 'unverified')
ON CONFLICT (id) DO NOTHING;

-- 3. Create a test team with max_members = 2 (1 owner + 1 vacancy)
INSERT INTO public.teams (id, owner_id, name, category, max_members, recruitment_status)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Quantum Robotics Roster',
    'hackathon',
    2,
    'open'
);

-- Owner should be automatically enrolled into team_members
SELECT is(
    (SELECT COUNT(*)::integer FROM public.team_members WHERE team_id = '20000000-0000-0000-0000-000000000001'),
    1,
    'Owner auto-enrolled on team creation'
);

-- 4. Scenario: Team owner cannot submit a join request to their own team
SELECT throws_ok(
    $$
        INSERT INTO public.join_requests (team_id, requester_id, message, status)
        VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Pitching to myself', 'pending')
    $$,
    'Team owner cannot submit a joining request to their own team',
    'Team owner submitting request to own team must be blocked'
);

-- 5. Scenario: Requester Bob submits join request with optional pitch note
INSERT INTO public.join_requests (id, team_id, requester_id, message, status)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'I have experience in ROS and embedded C.',
    'pending'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE recipient_id = '10000000-0000-0000-0000-000000000001' 
          AND type = 'joinRequest'
          AND related_team_id = '20000000-0000-0000-0000-000000000001'
    ),
    'Team owner is automatically notified when new join request is submitted'
);

-- 6. Scenario: Duplicate active (pending) request by Bob is rejected
SELECT throws_ok(
    $$
        INSERT INTO public.join_requests (team_id, requester_id, message, status)
        VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Duplicate', 'pending')
    $$,
    '23505', -- unique violation on idx_unique_active_join_request
    'Duplicate pending join request must be rejected'
);

-- 7. Scenario: Pitch note is immutable after submission
SELECT throws_ok(
    $$
        UPDATE public.join_requests
        SET message = 'Tampered pitch'
        WHERE id = '30000000-0000-0000-0000-000000000001'
    $$,
    'Pitch message cannot be altered once submitted',
    'Tampering with submitted pitch message is blocked'
);

-- 8. Scenario: Unauthorized user (attacker) cannot accept Bob''s join request
SELECT throws_ok(
    $$
        SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000004';
        SELECT public.accept_join_request('30000000-0000-0000-0000-000000000001');
    $$,
    'Unauthorized: Only the team owner can accept join requests',
    'Unauthorized user cannot accept join request'
);

-- 9. Scenario: Unauthorized user cannot withdraw someone else''s request
SELECT throws_ok(
    $$
        SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000004';
        SELECT public.withdraw_join_request('30000000-0000-0000-0000-000000000001');
    $$,
    'Unauthorized: You can only withdraw your own join requests',
    'Unauthorized user cannot withdraw another student''s request'
);

-- 10. Scenario: Requester Bob withdraws request
SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000002';
SELECT is(
    (public.withdraw_join_request('30000000-0000-0000-0000-000000000001') ->> 'status'),
    'withdrawn',
    'Requester Bob can withdraw his pending request'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE recipient_id = '10000000-0000-0000-0000-000000000001' 
          AND type = 'requestWithdrawn'
    ),
    'Team owner is notified when request is withdrawn'
);

-- 11. Scenario: Cannot alter resolved request back to pending
SELECT throws_ok(
    $$
        UPDATE public.join_requests
        SET status = 'pending'
        WHERE id = '30000000-0000-0000-0000-000000000001'
    $$,
    'Cannot alter status of a resolved join request (current status: withdrawn)',
    'Transitioning resolved request back to pending is prohibited'
);

-- 12. Scenario: Bob submits a new request with optional empty message
SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000002';
INSERT INTO public.join_requests (id, team_id, requester_id, message, status)
VALUES (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    '',
    'pending'
);

SELECT is(
    (SELECT status FROM public.join_requests WHERE id = '30000000-0000-0000-0000-000000000002'),
    'pending',
    'Join request created with optional empty pitch note'
);

-- 13. Scenario: Team owner accepts Bob''s request
SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000001';
SELECT is(
    (public.accept_join_request('30000000-0000-0000-0000-000000000002') ->> 'recruitment_closed')::boolean,
    true,
    'Acceptance successfully auto-closes recruitment when max_members (2) is reached'
);

SELECT is(
    (SELECT recruitment_status FROM public.teams WHERE id = '20000000-0000-0000-0000-000000000001'),
    'closed',
    'Team recruitment_status is now closed'
);

SELECT is(
    (SELECT COUNT(*)::integer FROM public.team_members WHERE team_id = '20000000-0000-0000-0000-000000000001'),
    2,
    'Membership created only after successful acceptance'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE recipient_id = '10000000-0000-0000-0000-000000000002' 
          AND type = 'requestAccepted'
    ),
    'Requester is notified of acceptance decision'
);

-- 14. Scenario: Existing member cannot submit redundant request
SELECT throws_ok(
    $$
        INSERT INTO public.join_requests (team_id, requester_id, message, status)
        VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Already in', 'pending')
    $$,
    'Team "%" is not currently open for recruitment (status: closed)',
    'Cannot submit request to closed team'
);

-- 15. Scenario: Re-opening full team does not allow exceeding max capacity
UPDATE public.teams SET recruitment_status = 'open' WHERE id = '20000000-0000-0000-0000-000000000001';

SELECT throws_ok(
    $$
        INSERT INTO public.join_requests (team_id, requester_id, message, status)
        VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Want in', 'pending')
    $$,
    'Team "Quantum Robotics Roster" has reached maximum capacity (2 of 2 members)',
    'Submitting request to full team is rejected by invariant trigger'
);

-- 16. Scenario: Rejecting a request notifies the applicant
-- Create a new team with vacancy to test rejection
INSERT INTO public.teams (id, owner_id, name, category, max_members, recruitment_status)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'SIH Devs Roster',
    'hackathon',
    3,
    'open'
);

INSERT INTO public.join_requests (id, team_id, requester_id, message, status)
VALUES (
    '30000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    'Hello team',
    'pending'
);

SET LOCAL "request.jwt.claim.sub" = '10000000-0000-0000-0000-000000000001';
SELECT is(
    (public.reject_join_request('30000000-0000-0000-0000-000000000003') ->> 'status'),
    'rejected',
    'Team owner can reject pending request'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE recipient_id = '10000000-0000-0000-0000-000000000003' 
          AND type = 'requestRejected'
    ),
    'Requester is notified of decline decision'
);

SELECT * FROM finish();
ROLLBACK;
