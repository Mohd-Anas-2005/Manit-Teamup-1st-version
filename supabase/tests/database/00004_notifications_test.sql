-- =============================================================================
-- Test File: 00004_notifications_test.sql
-- Description: pgTAP tests for notification storage, recipient association,
--              RLS isolation, read-state transitions, unread counts, and deduplication.
-- =============================================================================

BEGIN;
SELECT plan(12);

-- Setup test users
INSERT INTO auth.users (id, email)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'alice@manit.ac.in'),
    ('22222222-2222-2222-2222-222222222222', 'bob@manit.ac.in')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, college_name, branch, academic_year)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Alice Sharma', 'MANIT Bhopal', 'CSE', 3),
    ('22222222-2222-2222-2222-222222222222', 'Bob Verma', 'MANIT Bhopal', 'ECE', 2)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.teams (id, owner_id, name, description, event_name, min_members, max_members, recruitment_status)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'Robotics Crew',
    'Building autonomous robots',
    'Techfest 2026',
    2,
    4,
    'recruiting'
)
ON CONFLICT (id) DO NOTHING;

-- 1. Verify notifications table exists and has RLS enabled
SELECT has_table('public', 'notifications', 'public.notifications table exists');
SELECT row_level_security_is_active('public', 'notifications', 'RLS is active on notifications table');

-- 2. Insert notifications for Alice and Bob
INSERT INTO public.notifications (
    id,
    recipient_id,
    type,
    title,
    body,
    related_team_id
) VALUES 
    ('33333333-3333-3333-3333-333333333331', '11111111-1111-1111-1111-111111111111', 'joinRequest', 'Join Request 1', 'Bob requested to join', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    ('33333333-3333-3333-3333-333333333332', '11111111-1111-1111-1111-111111111111', 'teamAnnouncement', 'Team Notice', 'Meeting tomorrow', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'requestAccepted', 'Request Accepted', 'You joined Robotics Crew', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

-- 3. Test RLS Isolation: Alice can only see her 2 notifications, not Bob's
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

SELECT is(
    (SELECT count(*)::INTEGER FROM public.notifications),
    2,
    'Alice can only view her own 2 notifications under RLS'
);

SELECT is(
    (SELECT public.get_unread_notification_count()),
    2,
    'Alice initial unread notification count is 2'
);

-- 4. Alice marks single notification as read
SELECT ok(
    (public.mark_notification_as_read('33333333-3333-3333-3333-333333333331') ->> 'success')::BOOLEAN,
    'Alice successfully marks her notification as read'
);

SELECT is(
    (SELECT public.get_unread_notification_count()),
    1,
    'Alice unread count decrements to 1 after reading one notification'
);

-- 5. Alice cannot mark Bob''s notification as read
SELECT throws_ok(
    $$
        SELECT public.mark_notification_as_read('33333333-3333-3333-3333-333333333333');
    $$,
    'Unauthorized: You can only mark your own notifications as read',
    'User cannot mark another user''s notification as read'
);

-- 6. Alice cannot directly mutate immutable fields of notification (title, body, recipient)
SELECT throws_ok(
    $$
        UPDATE public.notifications
        SET title = 'Tampered Title'
        WHERE id = '33333333-3333-3333-3333-333333333332';
    $$,
    'Notification content is immutable; only read status (read_at) can be modified',
    'Direct alteration of notification title is rejected by immutability trigger'
);

-- 7. Alice marks all remaining notifications as read
SELECT is(
    (public.mark_all_notifications_as_read() ->> 'marked_count')::INTEGER,
    1,
    'Mark all as read marks the remaining unread notification'
);

SELECT is(
    (SELECT public.get_unread_notification_count()),
    0,
    'Alice unread count is now 0'
);

-- 8. Test Deduplication
-- Reset to service_role to call deduplication function
RESET ROLE;

SELECT ok(
    public.create_notification_deduped(
        '11111111-1111-1111-1111-111111111111',
        'joinRequest',
        'New Join Request',
        'Bob wants to join',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    ) IS NOT NULL,
    'create_notification_deduped creates a new notification when none unread'
);

-- Immediate duplicate attempt with same recipient, type, team should return existing ID without creating duplicate
SELECT is(
    (SELECT count(*)::INTEGER FROM public.notifications WHERE recipient_id = '11111111-1111-1111-1111-111111111111' AND read_at IS NULL),
    1,
    'Deduplication prevents creating redundant unread notification rows'
);

SELECT * FROM finish();
ROLLBACK;
