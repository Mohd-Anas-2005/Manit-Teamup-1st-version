# MANIT TeamUp — Supabase Backend Architecture & Security Specification

This document details the database schema, Row Level Security (RLS) policies, concurrency controls, integrity invariants, and verification plan implemented for **MANIT TeamUp**.

---

## 1. Architecture Overview

MANIT TeamUp's backend foundation is engineered with **PostgreSQL**, **Supabase Auth**, **Version-Controlled Migrations**, and **Defense-in-Depth Row Level Security**.

### Core Tenet
> **UI controls are not security boundaries.** All access control, verification integrity, capacity limits, immutability, and state transitions are strictly enforced at the database layer through PostgreSQL constraints, RLS policies, explicit triggers, and transaction-isolated RPC functions.

---

## 2. Database Tables & Entity Relationships

| Table | Primary Key | Foreign Key References | Constraints & Invariants |
|---|---|---|---|
| **`public.profiles`** | `id UUID` | `auth.users(id)` ON DELETE CASCADE | `membership_status` check, `membership_verification_status` check, GIN indexes on `skills` and `interests`. |
| **`public.teams`** | `id UUID` | `owner_id -> auth.users(id)` ON DELETE CASCADE | `max_members` (1–30), `recruitment_status` ('open', 'closed', 'paused'), GIN index on `required_skills`. |
| **`public.team_members`** | `id UUID` | `team_id -> teams(id)`, `user_id -> auth.users(id)` | `UNIQUE (team_id, user_id)`, `role` check ('owner', 'lead', 'member'). |
| **`public.join_requests`** | `id UUID` | `team_id -> teams(id)`, `requester_id -> auth.users(id)` | Partial unique index `(team_id, requester_id) WHERE (status = 'pending')` prevents duplicate active requests. |
| **`public.notifications`** | `id UUID` | `recipient_id -> auth.users(id)`, `related_team_id -> teams(id)` | `type` check, immutability trigger protecting content. |
| **`public.blocks`** | `(blocker_id, blocked_id)` | `auth.users(id)` | `CHECK (blocker_id <> blocked_id)` prevents self-blocking. |
| **`public.reports`** | `id UUID` | `reporter_id -> auth.users(id)`, `reported_user_id`, `team_id` | `CHECK (reported_user_id IS NOT NULL OR team_id IS NOT NULL)`. |

---

## 3. Version-Controlled SQL Migrations

Located in `supabase/migrations/`:

1. **`20261021000001_initial_schema.sql`**
   - Enables `pgcrypto`.
   - Defines all 7 tables with explicit column types, foreign keys, cascade rules, and check constraints.
   - Creates B-Tree and GIN indexes for query performance and skill matching.

2. **`20261021000002_security_functions_and_rpc.sql`**
   - Helper functions: `are_users_mutually_blocked(UUID, UUID)` and `is_team_owner(UUID, UUID)`.
   - Concurrency-safe transactional RPC: `accept_join_request(UUID)`.
   - Status transition RPCs: `reject_join_request(UUID)` and `withdraw_join_request(UUID)`.
   - Explicit `SET search_path = public, pg_temp` on all functions.
   - Permissions: `REVOKE ALL FROM PUBLIC; GRANT EXECUTE TO authenticated;`.

3. **`20261021000003_row_level_security.sql`**
   - `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY` across all 7 exposed tables.
   - Granular, least-privilege policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE`.

4. **`20261021000004_triggers_and_automation.sql`**
   - Immutability enforcement triggers for identifiers and timestamps.
   - Self-assignment prevention for `membership_verification_status`.
   - Automatic team owner enrollment into `team_members` on team creation.
   - Automated notification triggers for join requests.
   - Supabase Auth signup hook (`handle_new_auth_user`) for institutional email detection (`@stu.manit.ac.in` and `@manit.ac.in`).

---

## 4. Security Policies Matrix

### `public.profiles`
- **SELECT**: Accessible if viewer is owner (`auth.uid() = id`), or profile is public and neither user has blocked the other, or users share a team roster.
- **INSERT**: Authenticated users can insert their own profile (`auth.uid() = id`). Trigger forces `membership_verification_status = 'unverified'`.
- **UPDATE**: Users can only update their own profile (`auth.uid() = id`). Trigger `trg_enforce_profile_security` aborts any client attempt to modify `membership_verification_status` or `id`.
- **DELETE**: Restricted to owner (`auth.uid() = id`) and cascades on auth user deletion.

### `public.teams`
- **SELECT**: Viewable by authenticated users unless blocked by team owner.
- **INSERT**: Authenticated user sets `owner_id = auth.uid()`. Trigger automatically adds owner to `team_members`.
- **UPDATE**: Only team owner (`auth.uid() = owner_id`). Trigger rejects modifications to `id` and `owner_id`.
- **DELETE**: Only team owner (`auth.uid() = owner_id`).

### `public.team_members`
- **SELECT**: Visible to authenticated users who can view the parent team.
- **INSERT**: **NO DIRECT CLIENT INSERT POLICY**. Memberships are exclusively created via authorized server operations (`trg_auto_enroll_team_owner` and `accept_join_request` RPC).
- **UPDATE**: Team owner can update roles of existing non-owner members (`lead`, `member`).
- **DELETE**: A member can voluntarily leave (`auth.uid() = user_id AND role <> 'owner'`). A team owner can remove a member (`role <> 'owner'`).

### `public.join_requests`
- **SELECT**: Visible only to applicant (`auth.uid() = requester_id`) or team owner.
- **INSERT**: Allowed only when `auth.uid() = requester_id`, `status = 'pending'`, team recruitment is `'open'`, user is not already a member, and not mutually blocked.
- **UPDATE**: 
  - Requester can update status to `'withdrawn'`.
  - Team owner can update status to `'rejected'`.
  - Acceptance is prohibited via raw table `UPDATE`; owner must call `accept_join_request()` RPC.
- **DELETE**: Requester can delete past `'withdrawn'` or `'rejected'` requests.

### `public.notifications`
- **SELECT**: Only recipient (`auth.uid() = recipient_id`).
- **INSERT**: Driven automatically by database triggers on join request lifecycle events.
- **UPDATE**: Recipient can only modify `read_at`. Trigger aborts modifications to body, type, title, or recipient.
- **DELETE**: Recipient can delete their notification.

### `public.blocks`
- **SELECT**: Blocker only (`auth.uid() = blocker_id`). Users cannot inspect who blocked them.
- **INSERT**: Blocker only (`auth.uid() = blocker_id AND blocker_id <> blocked_id`).
- **DELETE**: Blocker can unblock (`auth.uid() = blocker_id`).

### `public.reports`
- **SELECT**: Reporter can view their submitted reports (`auth.uid() = reporter_id`). Service role can view all.
- **INSERT**: Authenticated user can submit with initial `status = 'pending'`.
- **UPDATE**: **NO CLIENT UPDATE POLICY**. Trigger rejects non-service-role updates to report status.
- **DELETE**: **NO CLIENT DELETE POLICY**. Reports are permanently retained for moderation review.

---

## 5. Concurrency & Race Condition Mitigation

### Simultaneous Join Acceptance Protection
When two team co-leads or simultaneous client requests attempt to accept join requests for the last remaining slot:
1. `accept_join_request(p_request_id)` issues `SELECT ... FROM public.join_requests WHERE id = p_request_id FOR UPDATE`, acquiring an exclusive row lock on the request.
2. It then issues `SELECT ... FROM public.teams WHERE id = v_team_id FOR UPDATE`, acquiring an exclusive lock on the team record.
3. Within this locked transaction:
   - Queries `SELECT COUNT(*) FROM public.team_members WHERE team_id = v_team.id`.
   - Aborts with exception if `count >= max_members`.
   - Inserts into `team_members`.
   - Marks request `accepted`.
   - If `count + 1 >= max_members`, automatically transitions `recruitment_status` to `'closed'`.
4. As a secondary safeguard, a `BEFORE INSERT` trigger on `team_members` enforces team capacity independently of the caller path.

---

## 6. Service Role Key Safeguard

- The Flutter client (`lib/core/services/supabase_service.dart`) utilizes **only** `--dart-define=SUPABASE_ANON_KEY` or environment configuration.
- No `service_role` key or administrative token is committed or referenced in the client code.
- Automated tests audit the client codebase to verify absence of privileged credentials.

---

## 8. College Membership & Verification Architecture

### Membership Categories & Verification States
Users select from three distinct membership categories:
1. **MANIT Student (`manit_student`)**
2. **Student from another college (`other_college`)** — allows entry of specific college name
3. **Not currently a student (`non_student`)**

For MANIT students, institutional verification is tracked via a discrete state machine:
- `unverified`: Default state upon self-declaration.
- `pending_review`: Student has submitted scholar credentials for verification.
- `verified`: Institutional identity confirmed by authorized reviewer.
- `rejected`: Verification rejected due to invalid or unverified credentials.

### Defense-in-Depth Verification Security
Ordinary users are strictly prohibited from granting themselves `verified` status:
1. **Client Model Sanitization:** The Dart `UserProfile.toUpdateJson()` serialization excludes `membership_verification_status` and `is_manit_verified`, ensuring client profile payloads never transmit verification status changes.
2. **Database Trigger Guard (`trg_enforce_profile_security`):** A PostgreSQL `BEFORE UPDATE` trigger on `public.profiles` inspects modifications to `membership_verification_status`. If caller is not `service_role`, the transaction is aborted with an exception: `Self-assignment of verification status is prohibited.`
3. **Student Submission RPC (`submit_for_verification`):** Authenticated students invoke `submit_for_verification(p_scholar_number)`. This function is strictly constrained: it can only transition status from `unverified` or `rejected` to `pending_review`. It can never grant `verified` status.
4. **Administrative Verification RPC (`review_membership_verification`):** Only callable by administrative reviewers (`auth.role() = 'service_role'`). Transitions status to `verified` or `rejected` with recorded audit notes. Ordinary authenticated users are denied execution.

### Privacy Safeguards & PII Protection
Student privacy is enforced at both presentation and database levels:
1. **Secure View (`public.discoverable_profiles`):** Exposes discovery fields (`display_name`, `bio`, `college_name`, `membership_status`, `membership_verification_status`, `branch`, `academic_year`, `skills`, `interests`, `portfolio_url`) while completely excluding `scholar_number` and `whatsapp_number`.
2. **Strict Client Roster Masking:** Scholar discovery displays identity badges, branch, academic year, and technical skills while hiding private contact numbers and student identification numbers.

### Profile Display Rules
- **Verified MANIT Student:** Displays the green `MANIT Verified` badge with shield icon.
- **Unverified MANIT Student:** Displays `MANIT Student — Unverified` in amber styling.
- **Student from another college:** Displays the student's declared college name with school icon.
- **Non-student:** Displays `Non-student` tag.
- **Unselected:** Displays `Not specified`.

---

## 9. Repeatable Verification Plan

### Test Suite 1: Automated Node.js Security & Schema Validation
Run the test suite:
```bash
npm test
```
**Coverage (53 automated checks):**
- Schema definitions, foreign keys, cascades, and constraints.
- Partial unique index on active join requests.
- RLS enablement and forced RLS verification across all tables.
- Immutability triggers and verification status self-assignment prevention.
- Verification RPC security: ordinary users cannot self-verify via `submit_for_verification`.
- Service-role isolation: `review_membership_verification` rejected for ordinary users.
- PII privacy boundary: `discoverable_profiles` view strictly excludes `scholar_number` and `whatsapp_number`.
- Team capacity validation and concurrency row locking checks.
- Function search_path hygiene (`SET search_path = public, pg_temp`).
- Function permission revocation (`REVOKE ALL FROM PUBLIC`).
- Scan of client codebase for service-role token absence.

### Test Suite 2: pgTAP Database Unit Tests
Located in `supabase/tests/database/`:
- `00001_security_policies_test.sql`: pgTAP assertion tests validating tables, columns, extensions, active RLS, functions, and policy structures.
- `00002_rls_scenarios_test.sql`: assertion tests validating real-world attack and authorization scenarios.

To run with Supabase CLI against local or remote Supabase instance:
```bash
supabase test db
```

### Test Suite 3: Flutter Application Unit & Widget Tests
```bash
flutter test
```
**Coverage (81 automated tests across unit and widget suites):**
- Membership category and verification status parsing from JSON.
- Safe serialization via `toUpdateJson()` omitting verification fields.
- Form validation in `EditProfileScreen` preventing client-side bypass.
- Badge rendering matching all 5 specified display conditions.
- Discovery filter matching for MANIT students, verified status, other colleges, branch, year, and skills.
- Sensitive PII omission in scholar discovery lists.
- Complete team-joining workflow domain serialization and copyWith state transitions.
- Authentication boundaries across all JoinRequestRepository methods.
- UI widget state rendering for Incoming & Sent collaboration requests with immediate UI updates.
- Real-time team roster display and capacity tracking.

---

## 10. Complete Team-Joining Workflow Specification

### Request Lifecycle States
Every join request transitions strictly through defined states:
- `pending`: Application submitted by authenticated student, awaiting review by authorized team owner.
- `accepted`: Team owner approved application; student is atomically enrolled into `team_members`.
- `rejected`: Team owner declined application; requester is notified of decision.
- `withdrawn`: Applicant voluntarily cancelled their pending request before owner decision.

### Security Invariants & PostgreSQL Enforcements

| Workflow Step | PostgreSQL Security Mechanism |
|---|---|
| **1. Validate Open Team & Vacancy** | `trg_enforce_join_request_invariants` verifies `teams.recruitment_status = 'open'` and `COUNT(team_members) < max_members`. Fails with exception if team is closed or full. |
| **2. Prevent Duplicate Active Requests** | Partial unique index `idx_unique_active_join_request` on `(team_id, requester_id) WHERE (status = 'pending')` prevents duplicate active requests at PostgreSQL engine level. |
| **3. Prevent Existing Member Redundancy** | `trg_enforce_join_request_invariants` and `join_requests_insert_policy` ensure requester is not team owner (`teams.owner_id <> requester_id`) and not in `team_members`. |
| **4. Notify Team Owner on Request** | `trg_join_requests_notify_insert` automatically writes a notification (`type = 'joinRequest'`) to the team owner's inbox. |
| **5. Authorized Acceptance / Rejection** | Only the authenticated team owner can accept or reject (`is_team_owner(team_id, auth.uid())`). Direct client `UPDATE status = 'accepted'` is blocked by RLS policy. |
| **6. Atomic Membership Enrollment** | `accept_join_request(UUID)` acquires exclusive `FOR UPDATE` row locks on both request and team. It verifies capacity, inserts into `team_members`, updates status to `'accepted'`, and auto-closes recruitment if full. Direct client INSERT on `team_members` is disabled. |
| **7. Notify Requester of Decision** | `accept_join_request` generates `'requestAccepted'` notification; `reject_join_request` generates `'requestRejected'` notification. |
| **8. Voluntary Withdrawal by Requester** | Requester can invoke `withdraw_join_request(UUID)` or update status to `'withdrawn'`. Team owner is notified via `'requestWithdrawn'` alert. |
| **9. Immediate UI Updates** | Flutter UI (`JoiningRequestsScreen` and `TeamDetailScreen`) immediately reflects the confirmed state change without requiring full page reload. |

### Database Functions & RPCs
- **`public.submit_join_request(p_team_id UUID, p_message TEXT DEFAULT '')`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Validates caller authentication (`auth.uid()`).
  - Inserts row with optional pitch message.
  - Returns JSON object with request ID, team ID, and status.
- **`public.accept_join_request(p_request_id UUID)`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Acquires exclusive row locks `FOR UPDATE` on join request and team.
  - Confirms caller is owner, request is pending, team is open, and capacity is available.
  - Inserts into `public.team_members`.
  - Sets request status to `accepted`.
  - If team capacity reached, auto-sets team `recruitment_status = 'closed'`.
  - Notifies requester and returns JSON status.
- **`public.reject_join_request(p_request_id UUID)`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Locks request `FOR UPDATE`, verifies owner authorization, transitions status to `rejected`, and notifies applicant.
- **`public.withdraw_join_request(p_request_id UUID)`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Locks request `FOR UPDATE`, verifies requester identity, transitions status to `withdrawn`, and notifies team owner.
- **`public.get_incoming_join_requests()`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Securely returns incoming requests for teams owned by `auth.uid()` with applicant profile and verification status.
- **`public.get_sent_join_requests()`**:
  - `SECURITY DEFINER`, `search_path = public, pg_temp`
  - Securely returns sent requests submitted by `auth.uid()` with target team details.
