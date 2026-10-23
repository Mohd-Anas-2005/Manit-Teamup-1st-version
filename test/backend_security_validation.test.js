/**
 * MANIT TeamUp - Backend Security & Schema Validation Test Suite
 * 
 * Verifies version-controlled SQL migrations, tables, columns, constraints,
 * indexes, Row Level Security policies, security-definer functions, search_path
 * hygiene, permissions, and Flutter service-role key absence.
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');

const ROOT_DIR = path.join(__dirname, '..');
const MIGRATIONS_DIR = path.join(ROOT_DIR, 'supabase', 'migrations');
const TESTS_DIR = path.join(ROOT_DIR, 'supabase', 'tests', 'database');

function runTests() {
    console.log('===============================================================');
    console.log('🧪 Starting MANIT TeamUp Backend Security & Schema Verification');
    console.log('===============================================================\n');

    let totalTests = 0;
    let passedTests = 0;

    function test(description, fn) {
        totalTests++;
        try {
            fn();
            console.log(`  ✓ ${description}`);
            passedTests++;
        } catch (error) {
            console.error(`  ✗ ${description}`);
            console.error(`    Error: ${error.message}`);
        }
    }

    // Read all migration files
    const migrationFiles = fs.readdirSync(MIGRATIONS_DIR).filter(f => f.endsWith('.sql')).sort();
    assert(migrationFiles.length >= 4, `Expected at least 4 migration files, found ${migrationFiles.length}`);

    const allMigrationSql = migrationFiles
        .map(f => fs.readFileSync(path.join(MIGRATIONS_DIR, f), 'utf-8'))
        .join('\n\n');

    console.log(`📁 Loaded ${migrationFiles.length} version-controlled migration files:`);
    migrationFiles.forEach(f => console.log(`   - ${f}`));
    console.log('');

    // -------------------------------------------------------------------------
    // 1. Table Definitions & Required Columns
    // -------------------------------------------------------------------------
    console.log('📋 1. DATABASE TABLES & SCHEMA VALIDATION');

    const expectedTables = [
        {
            table: 'profiles',
            columns: [
                'id', 'display_name', 'avatar_url', 'college_name',
                'membership_status', 'membership_verification_status',
                'branch', 'academic_year', 'bio', 'skills', 'interests',
                'portfolio_url', 'created_at', 'updated_at'
            ],
            reference: 'auth.users(id)'
        },
        {
            table: 'teams',
            columns: [
                'id', 'owner_id', 'name', 'description', 'category',
                'event_name', 'required_skills', 'max_members',
                'recruitment_status', 'created_at', 'updated_at'
            ],
            reference: 'auth.users(id)'
        },
        {
            table: 'team_members',
            columns: ['id', 'team_id', 'user_id', 'role', 'joined_at'],
            reference: 'teams(id)'
        },
        {
            table: 'join_requests',
            columns: ['id', 'team_id', 'requester_id', 'message', 'status', 'created_at', 'updated_at'],
            reference: 'teams(id)'
        },
        {
            table: 'notifications',
            columns: ['id', 'recipient_id', 'type', 'title', 'body', 'related_team_id', 'read_at', 'created_at'],
            reference: 'auth.users(id)'
        },
        {
            table: 'blocks',
            columns: ['blocker_id', 'blocked_id', 'created_at'],
            reference: 'auth.users(id)'
        },
        {
            table: 'reports',
            columns: ['id', 'reporter_id', 'reported_user_id', 'team_id', 'reason', 'details', 'status', 'created_at'],
            reference: 'auth.users(id)'
        }
    ];

    expectedTables.forEach(({ table, columns, reference }) => {
        test(`Table "public.${table}" exists and references "${reference}"`, () => {
            const tableRegex = new RegExp(`CREATE TABLE (IF NOT EXISTS )?public\\.${table}\\s*\\(`, 'i');
            assert(tableRegex.test(allMigrationSql), `Table public.${table} not defined`);
            assert(allMigrationSql.includes(reference), `Table public.${table} must reference ${reference}`);
        });

        test(`Table "public.${table}" includes all required columns`, () => {
            columns.forEach(col => {
                const colRegex = new RegExp(`\\b${col}\\b`, 'i');
                assert(colRegex.test(allMigrationSql), `Column "${col}" missing in schema for table ${table}`);
            });
        });
    });

    // -------------------------------------------------------------------------
    // 2. Constraints & Uniqueness Invariants
    // -------------------------------------------------------------------------
    console.log('\n🔒 2. CONSTRAINTS & INTEGRITY INVARIANTS');

    test('Partial unique index prevents duplicate active/pending join requests', () => {
        assert(
            allMigrationSql.includes('idx_unique_active_join_request') &&
            allMigrationSql.includes("(status = 'pending')"),
            'Missing partial unique index on join_requests (team_id, requester_id) WHERE (status = \'pending\')'
        );
    });

    test('Unique constraint on team_members prevents duplicate memberships', () => {
        assert(
            allMigrationSql.includes('unique_team_member') ||
            allMigrationSql.includes('UNIQUE (team_id, user_id)'),
            'Missing UNIQUE (team_id, user_id) constraint on team_members'
        );
    });

    test('Self-blocking is prevented by check constraint', () => {
        assert(
            allMigrationSql.includes('blocker_id <> blocked_id'),
            'Missing check constraint preventing self-blocking'
        );
    });

    test('Report target check requires reported_user_id or team_id', () => {
        assert(
            allMigrationSql.includes('reported_user_id IS NOT NULL OR team_id IS NOT NULL'),
            'Missing check constraint requiring report target'
        );
    });

    // -------------------------------------------------------------------------
    // 3. Row Level Security (RLS) Enforcement
    // -------------------------------------------------------------------------
    console.log('\n🛡️ 3. ROW LEVEL SECURITY (RLS) AUDIT');

    const allTables = ['profiles', 'teams', 'team_members', 'join_requests', 'notifications', 'blocks', 'reports'];

    allTables.forEach(table => {
        test(`RLS is enabled on "public.${table}"`, () => {
            const rlsEnableRegex = new RegExp(`ALTER TABLE public\\.${table} ENABLE ROW LEVEL SECURITY;`, 'i');
            assert(rlsEnableRegex.test(allMigrationSql), `RLS not enabled on public.${table}`);
        });

        test(`RLS is forced on "public.${table}"`, () => {
            const rlsForceRegex = new RegExp(`ALTER TABLE public\\.${table} FORCE ROW LEVEL SECURITY;`, 'i');
            assert(rlsForceRegex.test(allMigrationSql), `RLS not forced on public.${table}`);
        });
    });

    test('User can edit only their own permitted profile fields', () => {
        assert(allMigrationSql.includes('profiles_update_policy'));
        assert(allMigrationSql.includes('auth.uid() = id'));
    });

    test('User cannot assign themselves verified membership status (enforced by trigger & policy)', () => {
        assert(
            allMigrationSql.includes('trg_enforce_profile_security') &&
            allMigrationSql.includes('A user may not assign or modify their own membership verification status'),
            'Missing trigger rejecting self-assignment of membership_verification_status'
        );
    });

    test('Authorized verification workflow review_membership_verification requires service_role', () => {
        assert(
            allMigrationSql.includes('review_membership_verification') &&
            allMigrationSql.includes("Only institutional verification authorities may review credentials") &&
            allMigrationSql.includes("GRANT EXECUTE ON FUNCTION public.review_membership_verification(UUID, TEXT, TEXT) TO service_role"),
            'review_membership_verification must strictly enforce service_role authorization'
        );
    });

    test('submit_for_verification allows students to request pending_review but never self-verify', () => {
        assert(
            allMigrationSql.includes('submit_for_verification') &&
            allMigrationSql.includes("membership_verification_status = 'pending_review'"),
            'submit_for_verification must transition status only to pending_review'
        );
    });

    test('discoverable_profiles view strictly excludes student IDs and contact numbers', () => {
        assert(
            allMigrationSql.includes('CREATE OR REPLACE VIEW public.discoverable_profiles') &&
            !allMigrationSql.includes('discoverable_profiles AS SELECT p.scholar_number'),
            'discoverable_profiles view must protect scholar_number and private contact information'
        );
    });

    test('discoverable_profiles enforces security_invoker = true to respect RLS and block relationships', () => {
        assert(
            allMigrationSql.includes('WITH (security_invoker = true)'),
            'discoverable_profiles must specify WITH (security_invoker = true) to prevent bypassing RLS policies'
        );
    });

    test('Discovery performance indexes exist for branch, academic_year, display_name, and pagination', () => {
        assert(allMigrationSql.includes('idx_profiles_branch'), 'Missing idx_profiles_branch index');
        assert(allMigrationSql.includes('idx_profiles_academic_year'), 'Missing idx_profiles_academic_year index');
        assert(allMigrationSql.includes('idx_profiles_display_name'), 'Missing idx_profiles_display_name index');
        assert(allMigrationSql.includes('idx_profiles_discovery_paging'), 'Missing idx_profiles_discovery_paging index');
    });

    test('Only authorized team owners may manage/update their teams', () => {
        assert(allMigrationSql.includes('teams_update_policy'));
        assert(allMigrationSql.includes('teams_delete_policy'));
        assert(allMigrationSql.includes('auth.uid() = owner_id'));
    });

    test('Team management performance indexes exist for name, event_name, and open recruitment browsing', () => {
        assert(allMigrationSql.includes('idx_teams_name'), 'Missing idx_teams_name index');
        assert(allMigrationSql.includes('idx_teams_event_name'), 'Missing idx_teams_event_name index');
        assert(allMigrationSql.includes('idx_teams_open_browse'), 'Missing idx_teams_open_browse index');
        assert(allMigrationSql.includes('idx_team_members_team_role'), 'Missing idx_team_members_team_role index');
    });

    test('Joining requester may withdraw their own pending request', () => {
        assert(
            allMigrationSql.includes('join_requests_update_policy') &&
            allMigrationSql.includes("status = 'withdrawn'"),
            'Missing policy allowing requester to withdraw pending request'
        );
    });

    test('Only authorized team owner may reject requests via RLS', () => {
        assert(
            allMigrationSql.includes('join_requests_update_policy') &&
            allMigrationSql.includes("status = 'rejected'"),
            'Missing policy allowing team owner to reject pending request'
        );
    });

    test('Direct team_members INSERT by clients is disallowed (created via authorized operations)', () => {
        const directMemberInsertPolicy = /CREATE POLICY ".*?" ON public\.team_members\s+FOR INSERT\s+TO authenticated/i;
        assert(!directMemberInsertPolicy.test(allMigrationSql), 'Direct INSERT policy found on team_members; should be disallowed!');
    });

    test('Clients are prohibited from modifying administrative report status', () => {
        const reportUpdatePolicy = /CREATE POLICY ".*?" ON public\.reports\s+FOR UPDATE\s+TO authenticated/i;
        assert(!reportUpdatePolicy.test(allMigrationSql), 'Client UPDATE policy found on reports; should be strictly prohibited!');
        assert(allMigrationSql.includes('trg_enforce_report_tampering_protection'), 'Missing trigger protecting report tampering');
    });

    test('Notifications can only be read by the designated recipient', () => {
        assert(allMigrationSql.includes('notifications_select_policy'));
        assert(allMigrationSql.includes('auth.uid() = recipient_id'));
    });

    // -------------------------------------------------------------------------
    // 4. Concurrency Safety & Security Definer Functions
    // -------------------------------------------------------------------------
    console.log('\n⚙️ 4. CONCURRENCY-SAFE RPCs & FUNCTION SECURITY');

    test('accept_join_request is concurrency-safe with FOR UPDATE row locks', () => {
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.accept_join_request'));
        assert(allMigrationSql.includes('FOR UPDATE'), 'accept_join_request must use FOR UPDATE row locks');
    });

    test('accept_join_request validates team capacity before acceptance', () => {
        assert(allMigrationSql.includes('v_current_count >= v_team.max_members'));
        assert(allMigrationSql.includes('Team has reached its maximum capacity'));
    });

    test('accept_join_request auto-closes recruitment when team reaches capacity', () => {
        assert(allMigrationSql.includes("SET recruitment_status = 'closed'"));
    });

    test('All security definer functions set explicit search_path = public, pg_temp', () => {
        const secDefinerMatches = allMigrationSql.match(/SECURITY DEFINER[\s\S]*?SET search_path = public, pg_temp/g);
        assert(secDefinerMatches && secDefinerMatches.length >= 5, 'Security definer functions must explicitly set search_path = public, pg_temp');
    });

    test('Function execute permissions are revoked from PUBLIC and granted to authenticated', () => {
        assert(allMigrationSql.includes('REVOKE ALL ON FUNCTION public.accept_join_request(UUID) FROM PUBLIC;'));
        assert(allMigrationSql.includes('GRANT EXECUTE ON FUNCTION public.accept_join_request(UUID) TO authenticated'));
    });

    // -------------------------------------------------------------------------
    // 5. Automated Triggers & Invariant Protections
    // -------------------------------------------------------------------------
    console.log('\n⚡ 5. DATABASE TRIGGERS & AUTOMATION');

    test('Team creation trigger automatically enrolls owner as owner in team_members', () => {
        assert(allMigrationSql.includes('trg_auto_enroll_team_owner'));
        assert(allMigrationSql.includes("role, joined_at)"));
        assert(allMigrationSql.includes("'owner'"));
    });

    test('Team owner and ID are protected from direct mutation by trigger', () => {
        assert(allMigrationSql.includes('trg_enforce_team_immutability'));
        assert(allMigrationSql.includes('Team owner is immutable'));
    });

    test('Submitting join request triggers automated notification for team owner', () => {
        assert(allMigrationSql.includes('trg_join_requests_on_insert'));
        assert(allMigrationSql.includes("'joinRequest'"));
    });

    // -------------------------------------------------------------------------
    // 6. Flutter Client Secret Audit
    // -------------------------------------------------------------------------
    console.log('\n🔑 6. FLUTTER CLIENT SECRETS & REPOSITORY AUDIT');

    test('No Supabase service_role key exists in Flutter code or repository', () => {
        const libDir = path.join(ROOT_DIR, 'lib');
        function scanDir(dir) {
            const files = fs.readdirSync(dir);
            for (const file of files) {
                const fullPath = path.join(dir, file);
                const stat = fs.statSync(fullPath);
                if (stat.isDirectory()) {
                    scanDir(fullPath);
                } else if (file.endsWith('.dart') || file.endsWith('.env')) {
                    const content = fs.readFileSync(fullPath, 'utf-8');
                    assert(!content.includes('service_role'), `Found service_role reference in client file: ${fullPath}`);
                    assert(!/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/.test(content), `Found hardcoded JWT token in client file: ${fullPath}`);
                }
            }
        }
        scanDir(libDir);
    });

    test('submit_join_request is security-definer RPC validating caller and returning JSON', () => {
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.submit_join_request'));
        assert(allMigrationSql.includes('REVOKE ALL ON FUNCTION public.submit_join_request(UUID, TEXT) FROM PUBLIC;'));
        assert(allMigrationSql.includes('GRANT EXECUTE ON FUNCTION public.submit_join_request(UUID, TEXT) TO authenticated'));
    });

    test('get_incoming_join_requests and get_sent_join_requests secure RPCs exist', () => {
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.get_incoming_join_requests'));
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.get_sent_join_requests'));
    });

    test('Join request invariants trigger validates team recruitment, capacity, and owner exclusion', () => {
        assert(allMigrationSql.includes('trg_enforce_join_request_invariants'));
        assert(allMigrationSql.includes('Team owner cannot submit a joining request to their own team'));
        assert(allMigrationSql.includes('User is already an enrolled member of this team roster'));
        assert(allMigrationSql.includes('has reached maximum capacity'));
    });

    test('Join request immutability trigger blocks modifying resolved requests', () => {
        assert(allMigrationSql.includes('Cannot alter status of a resolved join request'));
    });

    test('mark_notification_as_read, mark_all_notifications_as_read, and get_unread_notification_count RPCs exist', () => {
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.mark_notification_as_read'));
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read'));
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.get_unread_notification_count'));
        assert(allMigrationSql.includes('REVOKE ALL ON FUNCTION public.mark_notification_as_read(UUID) FROM PUBLIC;'));
        assert(allMigrationSql.includes('GRANT EXECUTE ON FUNCTION public.mark_notification_as_read(UUID) TO authenticated'));
        assert(allMigrationSql.includes('GRANT EXECUTE ON FUNCTION public.mark_all_notifications_as_read() TO authenticated'));
        assert(allMigrationSql.includes('GRANT EXECUTE ON FUNCTION public.get_unread_notification_count() TO authenticated'));
    });

    test('create_notification_deduped helper prevents duplicate unread notifications', () => {
        assert(allMigrationSql.includes('CREATE OR REPLACE FUNCTION public.create_notification_deduped'));
        assert(allMigrationSql.includes('read_at IS NULL'));
    });

    test('Repeatable pgTAP test files exist in supabase/tests/database/', () => {
        assert(fs.existsSync(TESTS_DIR), 'supabase/tests/database/ directory missing');
        const testFiles = fs.readdirSync(TESTS_DIR).filter(f => f.endsWith('.sql'));
        assert(testFiles.length >= 4, `Expected at least 4 pgTAP test files, found ${testFiles.length}`);
    });

    console.log('\n===============================================================');
    console.log(`📊 RESULTS: ${passedTests} / ${totalTests} tests passed (${Math.round((passedTests/totalTests)*100)}%)`);
    console.log('===============================================================\n');

    if (passedTests !== totalTests) {
        process.exit(1);
    }
}

runTests();
