-- pgTAP Automated Tests for MANIT TeamUp
-- Test File: supabase/tests/database/00001_security_policies_test.sql
-- Description: Validates schema definitions, foreign keys, RLS enablement, and functions.

BEGIN;
SELECT plan(37);

-- 1. Test Schema & Extensions
SELECT has_extension('pgcrypto', 'pgcrypto extension should be enabled');

-- 2. Test Tables Existence
SELECT has_table('public', 'profiles', 'public.profiles table should exist');
SELECT has_table('public', 'teams', 'public.teams table should exist');
SELECT has_table('public', 'team_members', 'public.team_members table should exist');
SELECT has_table('public', 'join_requests', 'public.join_requests table should exist');
SELECT has_table('public', 'notifications', 'public.notifications table should exist');
SELECT has_table('public', 'blocks', 'public.blocks table should exist');
SELECT has_table('public', 'reports', 'public.reports table should exist');

-- 3. Test RLS is Enabled and Forced on Every Table
SELECT row_level_security_is_active('public', 'profiles', 'RLS should be active on profiles');
SELECT row_level_security_is_active('public', 'teams', 'RLS should be active on teams');
SELECT row_level_security_is_active('public', 'team_members', 'RLS should be active on team_members');
SELECT row_level_security_is_active('public', 'join_requests', 'RLS should be active on join_requests');
SELECT row_level_security_is_active('public', 'notifications', 'RLS should be active on notifications');
SELECT row_level_security_is_active('public', 'blocks', 'RLS should be active on blocks');
SELECT row_level_security_is_active('public', 'reports', 'RLS should be active on reports');

-- 4. Test Key Columns
SELECT has_column('public', 'profiles', 'membership_verification_status', 'profiles must have membership_verification_status');
SELECT has_column('public', 'profiles', 'membership_status', 'profiles must have membership_status');
SELECT has_column('public', 'profiles', 'college_name', 'profiles must have college_name');
SELECT has_column('public', 'teams', 'owner_id', 'teams must have owner_id');
SELECT has_column('public', 'teams', 'max_members', 'teams must have max_members');
SELECT has_column('public', 'teams', 'recruitment_status', 'teams must have recruitment_status');
SELECT has_column('public', 'team_members', 'role', 'team_members must have role');
SELECT has_column('public', 'join_requests', 'status', 'join_requests must have status');
SELECT has_column('public', 'reports', 'status', 'reports must have status');

-- 5. Test Functions & RPCs
SELECT has_function('public', 'are_users_mutually_blocked', ARRAY['uuid', 'uuid'], 'are_users_mutually_blocked function must exist');
SELECT has_function('public', 'is_team_owner', ARRAY['uuid', 'uuid'], 'is_team_owner function must exist');
SELECT has_function('public', 'accept_join_request', ARRAY['uuid'], 'accept_join_request RPC must exist');
SELECT has_function('public', 'reject_join_request', ARRAY['uuid'], 'reject_join_request RPC must exist');
SELECT has_function('public', 'withdraw_join_request', ARRAY['uuid'], 'withdraw_join_request RPC must exist');

-- 6. Test Security Definer Property
SELECT is_definer('public', 'accept_join_request', ARRAY['uuid'], 'accept_join_request must be SECURITY DEFINER');
SELECT is_definer('public', 'reject_join_request', ARRAY['uuid'], 'reject_join_request must be SECURITY DEFINER');
SELECT is_definer('public', 'withdraw_join_request', ARRAY['uuid'], 'withdraw_join_request must be SECURITY DEFINER');
SELECT is_definer('public', 'are_users_mutually_blocked', ARRAY['uuid', 'uuid'], 'are_users_mutually_blocked must be SECURITY DEFINER');

-- 7. Test Policies Exist
SELECT policies_are(
    'public',
    'profiles',
    ARRAY[
        'profiles_select_policy',
        'profiles_insert_policy',
        'profiles_update_policy',
        'profiles_delete_policy'
    ],
    'profiles policies should match specifications'
);

SELECT policies_are(
    'public',
    'teams',
    ARRAY[
        'teams_select_policy',
        'teams_insert_policy',
        'teams_update_policy',
        'teams_delete_policy'
    ],
    'teams policies should match specifications'
);

SELECT policies_are(
    'public',
    'team_members',
    ARRAY[
        'team_members_select_policy',
        'team_members_update_policy',
        'team_members_delete_policy'
    ],
    'team_members policies should match specifications (no direct client INSERT policy)'
);

SELECT policies_are(
    'public',
    'reports',
    ARRAY[
        'reports_select_policy',
        'reports_insert_policy'
    ],
    'reports policies should match specifications (no client UPDATE/DELETE policy)'
);

SELECT * FROM finish();
ROLLBACK;
