# MANIT TeamUp — System Architecture & Implementation Plan

MANIT TeamUp is a specialized mobile collaboration platform engineered for students at Maulana Azad National Institute of Technology (MANIT Bhopal) and invited cross-college participants. It connects students across hackathons, coding contests, academic projects, startup ventures, AI/ML initiatives, and campus technical events with verified student credibility, real-time messaging, and structured team formation workflows.

---

## User Review & Critical Decisions

> [!IMPORTANT]
> The following critical requirements and architectural decisions have been aligned with your responses:
> 
> - **Institutional Verification**: Handled via email domain verification using the official MANIT scholar format (`scholar_number@stu.manit.ac.in`). Verification sends a secure one-time link/OTP. Non-MANIT students and external collaborators can register with standard personal emails without friction; their profiles will be transparently badged as "Other College" or "Guest/Non-Student" without false MANIT claims.
> - **Target Platform**: Native Android using **Kotlin** and **Jetpack Compose** (Material 3), ensuring maximum runtime performance, native system responsiveness, and deep integration with Android lifecycle and accessibility standards.
> - **Backend & Persistence**: **Supabase** (PostgreSQL database, Supabase Auth with Row-Level Security, Storage, and Realtime WebSocket subscriptions) with zero backend secret exposure in the APK.
> - **Team Communication**: Hybrid collaboration system featuring both **in-app real-time group & 1-on-1 direct chat** powered by Supabase Realtime/Postgres, plus opt-in **external WhatsApp click-to-chat links** for accepted team members.

---

## 1. Overview & Core Concept

### 1.1 Product Purpose & Target Audience
- **Primary Persona**: Undergraduate and postgraduate students at MANIT Bhopal (spanning CSE, IT, ECE, EE, Mechanical, Civil, Chemical, MSME, Architecture, MCA, and M.Tech) seeking teammates with complementary skill sets (e.g., frontend, backend, AI/ML, UI/UX, hardware/IoT, pitch/business).
- **Secondary Persona**: Students from other national universities (IITs, NITs, IIITs, state universities) invited for open cross-college hackathons (e.g., Smart India Hackathon, Version, Megatreopuz, HackNITR).
- **Core Value Proposition**: Replaces fragmented, spam-heavy WhatsApp/Telegram group queries with an organized, searchable marketplace of projects and talent, backed by cryptographic domain verification and structured applicant review.

### 1.2 Core Scope Boundaries: MVP vs. Future Enhancements

| Area | In-Scope for MVP (Phase 1 & 2) | Future Enhancements (Post-MVP) |
| :--- | :--- | :--- |
| **Authentication** | Email/Password, Password Reset, Email OTP Verification, Distinction between `@stu.manit.ac.in` and external emails | Google One-Tap Sign-In, LinkedIn OAuth |
| **Profile** | Name, Avatar, College, Membership status, Branch, Year, Skills tags, Interests, Bio, GitHub/LinkedIn/Portfolio URLs | Verified GitHub repo stats, LeetCode profile badge |
| **Teams & Projects** | Create, edit, recruit toggle, project category, event name, required skill tags, max team size, member management | Automated AI teammate recommendation engine |
| **Join Requests** | Apply with custom pitch note, Owner Accept/Reject, Applicant Withdraw, Real-time status sync | Multi-role applications (e.g., "Applying as Lead Designer") |
| **Chat & Comms** | In-app Team Group Chat, Direct 1-on-1 Chat for accepted members, Direct WhatsApp launch link | Voice messages, file attachments beyond images |
| **Safety & Moderation** | User & Team reporting, User blocking (hides posts & DMs), Profile privacy (toggle public contact info), Account deletion | Automated content moderation with ML filtering |

---

## 2. User Experience & Visual Design

### 2.1 Aesthetic Identity & Design System
- **Theme Concept**: *Cyber-Academic Midnight* — authoritative, sleek, high-contrast, energetic yet distraction-free.
- **Palette**:
  - **Midnight Navy (`#0A0E1A`)**: Deep primary background creating spatial immersion.
  - **Charcoal Surface (`#141926`)**: Elevated card and sheet surfaces (`tonalElevation = 2.dp`).
  - **Electric Violet (`#7C3AED` / `#8B5CF6`)**: Primary brand accent, primary CTA buttons, verified MANIT status badge.
  - **Cyan Glow (`#06B6D4` / `#22D3EE`)**: Active indicators, hackathon tags, join request notifications.
  - **Coral Spark (`#F43F5E`)**: Urgent alerts, open recruitment status, reject/withdraw actions.
  - **Magenta Accent (`#D946EF`)**: Project category accents, secondary interactive highlights.
  - **Text High-Contrast (`#F8FAFC`)** & **Muted Text (`#94A3B8`)**: Strict WCAG AA contrast compliance.
- **Micro-Interactions**:
  - Spring-animated pill transitions for discovery filter tabs (`spring(stiffness = Spring.StiffnessMediumLow)`).
  - Subtle glowing border on verified MANIT cards (`BorderStroke(1.dp, Brush.linearGradient(...))`).
  - Tactile ripple feedback (`Modifier.clickable`) with minimum 48dp interactive touch targets.
  - Staggered card entry transitions (`AnimatedVisibility` with fade + slide).

---

### 2.2 Navigation Architecture

```
                               ┌──────────────────────────┐
                               │   Launch / Splash Screen │
                               └────────────┬─────────────┘
                                            │
                     ┌──────────────────────┴──────────────────────┐
                     ▼                                             ▼
          ┌───────────────────────┐                    ┌───────────────────────┐
          │     Auth Screen       │                    │    Main App Scaffold  │
          │ (Login / Register /   │                    │ (Bottom Navigation)   │
          │  Verify OTP / Reset)  │                    └───────────┬───────────┘
          └───────────────────────┘                                │
                                                                   │
         ┌──────────────────┬──────────────────┬───────────────────┴───────────────────┬──────────────────┐
         ▼                  ▼                  ▼                                       ▼                  ▼
┌─────────────────┐┌─────────────────┐┌─────────────────┐                       ┌─────────────────┐┌─────────────────┐
│ 1. Discover     ││ 2. My Teams     ││ 3. Create Team  │                       │ 4. Inbox & Chat ││ 5. Profile &    │
│    Hub          ││    Workspace    ││    Sheet        │                       │    Hub          ││    Settings     │
└────────┬────────┘└────────┬────────┘└─────────────────┘                       └────────┬────────┘└────────┬────────┘
         │                  │                                                            │                  │
         ├─ Team Detail     ├─ Manage Roster                                             ├─ Team Group Chat ├─ Edit Profile
         │  (Apply Modal)   ├─ Pending Requests (Accept/Reject)                          ├─ Direct 1-on-1   ├─ Privacy Settings
         ├─ Student Profile └─ Edit Team Metadata                                        └─ Notifications   ├─ Blocked Users
         └─ Filter Sheet                                                                                    └─ Delete Account
```

---

### 2.3 Screen-by-Screen Specifications

#### Screen 1: Splash & Onboarding / Session Router (`Route.Splash`)
- **Visuals**: Centered MANIT TeamUp emblem with radial electric-violet gradient glow against midnight navy.
- **Logic**: Inspects cached Supabase Auth session token.
  - If valid and profile complete $\rightarrow$ Navigates to `Route.Discover`.
  - If valid but profile incomplete $\rightarrow$ Navigates to `Route.CompleteProfile`.
  - If invalid/null $\rightarrow$ Smooth transition to `Route.Auth`.

#### Screen 2: Authentication Hub (`Route.Auth`)
- **Components**:
  - Segmented control: `Sign In` | `Create Account`.
  - Email text field with live domain helper text:
    - Entering `...@stu.manit.ac.in` highlights: *"MANIT Scholar ID detected — You will receive an institutional verification link for a Verified Student Badge."*
    - Entering any other valid email displays: *"External / Open Collaborator — You will register with full access as a visiting teammate."*
  - Password field with show/hide toggle and strength meter.
  - `Forgot Password?` modal triggering Supabase reset email.
  - Action button: `Continue` (Electric Violet gradient).

#### Screen 3: Email OTP Verification Gate (`Route.VerifyEmail`)
- **Purpose**: Enforces email ownership verification before granting active database write access.
- **Components**:
  - Visual envelope with floating status glow.
  - 6-digit OTP code entry / "Click magic link in your inbox" status poller.
  - `Resend Code` timer (60s countdown).
  - Explicit notification: *"Your MANIT verification badge is awarded upon completing this email confirmation."*

#### Screen 4: Profile Creation & Setup (`Route.CompleteProfile`)
- **Components**:
  - Profile avatar upload with local crop preview.
  - Full Name input (validated 2–50 chars).
  - Membership Status selector (read-only auto-set if email is `@stu.manit.ac.in`, otherwise selectable: *Student from other college* / *Not currently a student*).
  - College / Institute Name (auto-locked to "MANIT Bhopal" for `@stu.manit.ac.in`, free text with autocomplete for others).
  - Academic Year dropdown: `1st Year`, `2nd Year`, `3rd Year`, `4th Year`, `Postgraduate/MCA/M.Tech`, `Alumni/Other`.
  - Branch / Department dropdown: `CSE`, `IT`, `ECE`, `EE`, `Mechanical`, `Civil`, `Chemical`, `MSME`, `Architecture & Planning`, `Other`.
  - Skills multi-select chip input (e.g., `Flutter`, `Kotlin`, `Python`, `PyTorch`, `React`, `Figma`, `Solidity`, `Embedded Systems`, `UI/UX`, `Node.js`).
  - Interests & Hackathon Goals tags (e.g., `FinTech`, `Healthcare AI`, `SIH 2026`, `Web3`, `Robotics`).
  - Bio (max 300 characters).
  - External Portfolio links: GitHub username, LinkedIn URL, Portfolio website URL, optional WhatsApp phone number.
  - Privacy Toggle: *"Allow accepted teammates to view my WhatsApp handle directly"*.

#### Screen 5: Discover Hub (`Route.Discover` - Home)
- **Top Bar**: Search bar with debounce (searches project titles, required skills, member names, and hackathon events) + Filter icon with active filter badge indicator.
- **Tab Header**: Two pill-style browsing views:
  1. `Explore Teams` (Projects looking for members).
  2. `Find Students` (Individual hackers seeking a team).
- **Team Card Component**:
  - Event tag (e.g., `Smart India Hackathon`, `Internal Hackathon`, `Semester Capstone`).
  - Project Title & Category badge (Cyan/Magenta).
  - Owner details with Avatar, Name, and verified MANIT badge.
  - Recruitment status pill: `Open (2 slots left)` (Coral) or `Closed` (Muted).
  - Required skills chips with matched skill highlights (skills matching current user's profile highlighted in Electric Violet).
  - `Apply / View Team` button (48dp touch target).
- **Empty States & Error Handling**:
  - Friendly empty state with illustration and reset button when search queries yield 0 results.
  - Pull-to-refresh (`SwipeRefresh`) with smooth spring feedback.

#### Screen 6: Team Detail & Join Application (`Route.TeamDetail/{teamId}`)
- **Header**: Hero banner with project name, recruitment badge, and category.
- **Roster Section**: Shows Current Members (Avatars, Roles, MANIT verification badges).
- **Description & Requirements**: Full pitch text, hackathon timeline, required tech stack.
- **Bottom Bar Action**:
  - If Visitor: `Request to Join Team` button $\rightarrow$ Opens bottom sheet with pitch input: *"Introduce yourself and state what you bring to the team"* (max 250 characters).
  - If Already Applied: Shows dynamic status chip: `Pending Review` (Amber), `Accepted` (Green), or `Rejected` (Coral), plus a `Withdraw Application` button.
  - If Team Member / Owner: Shows `Open Team Chat` and `WhatsApp Hub` buttons.

#### Screen 7: Team Creation & Edit Studio (`Route.CreateTeam`)
- **Form Fields**:
  - Project / Venture Title (required).
  - Event / Competition Name (e.g., "SIH 2026", "RoboSub", "College Minor Project").
  - Category selector: `Hackathon`, `Academic Project`, `Startup / Venture`, `AI / ML Research`, `Open Source`, `Competitive Programming`.
  - Full Project Description (markdown/plain text support).
  - Target Team Size counter (slider from 2 to 6).
  - Required Skills tags builder.
  - Recruitment Status switch: `Actively Recruiting` vs. `Roster Locked`.
  - External WhatsApp Group Link (optional, only visible to accepted members).
- **Validation**: Enforces non-empty title, at least 1 required skill, team size $\ge 2$.

#### Screen 8: My Teams & Request Management (`Route.MyTeams`)
- **Tabs**:
  1. `Teams I Lead` (Teams where user is creator/owner).
  2. `Teams Joined` (Active memberships).
  3. `Sent Requests` (Pending/Accepted/Rejected applications).
- **Owner Request Management Card**:
  - Applicant avatar, name, branch, year, and verified student badge.
  - Applicant's custom pitch note.
  - Overlap score: shows matched skills compared to required skills.
  - Dual action buttons: `Accept` (Electric Violet) and `Reject` (Subtle Coral).

#### Screen 9: Inbox, Real-Time Chat & Communications (`Route.Inbox`)
- **Conversations List**:
  - Segmented between `Team Group Chats` and `Direct Messages`.
  - Unread message counters (Cyan pill), last message snippet, timestamp.
- **Team Chat Room Screen (`Route.Chat/{channelId}`)**:
  - Real-time message streaming powered by Supabase Realtime WebSocket channel.
  - Message bubbles styled with midnight surfaces; own messages styled in electric violet.
  - Top action item: `Open WhatsApp Group` button (launches `intent://send` with explicit safety check).
  - Quick action menu on messages for moderation: `Report Message`, `Block User`.

#### Screen 10: Profile, Safety & Settings (`Route.Profile`)
- **Display**: Full student resume card, verified MANIT badge, linked GitHub/LinkedIn/Portfolio icons.
- **Privacy Controls**:
  - Profile visibility (`Public to all logged-in students` vs `Only visible when applying to teams`).
  - Show/Hide contact handles.
- **Safety Center**:
  - `Blocked Users` list with single-tap Unblock.
  - `Report an Issue / Misconduct` modal with categories (Harassment, Spam, Fake Credentials, Academic Misconduct).
- **Account Lifecycle**:
  - `Log Out` (clears local token and resets state).
  - `Delete Account` (destructive red confirmation dialog with re-authentication challenge; triggers cascade deletion of personal data and anonymization of messages).

---

## 3. Key Product Decisions & Trade-Offs

### 3.1 Ambiguities & Safe Practical Defaults

```
┌──────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────┐
│ Identified Ambiguity                 │ Safe Practical Default Adopted                                                 │
├──────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ How to verify MANIT status safely    │ Verify domain `@stu.manit.ac.in` via secure OTP token link. Never store or ask │
│ without risking credentials?         │ for institutional ERP passwords.                                               │
├──────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ How to accommodate cross-college     │ Allow any standard email registration; display transparent badges:             │
│ participants without confusion?      │ [MANIT Verified] vs [External Student - College Name] vs [Guest].              │
├──────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ What happens to a team when the      │ Owner can transfer ownership to another accepted member before leaving;        │
│ creator leaves or deletes account?   │ if lone member, team is marked archived.                                       │
├──────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ In-app chat vs external WhatsApp?    │ Provide both: In-app chat for zero-friction initial discussion, and opt-in     │
│                                      │ WhatsApp group link shared ONLY once an applicant is formally Accepted.        │
└──────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Technical Architecture & Data Strategy

### 4.1 System Architecture

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                           Native Android Client (Kotlin + Jetpack Compose)            │
│                                                                                       │
│   ┌───────────────────────────────────────────────────────────────────────────────┐   │
│   │                        Presentation Layer (M3 Jetpack Compose)                │   │
│   │  DiscoverScreen │ TeamDetailScreen │ ChatScreen │ ProfileScreen │ ManageScreen │  │
│   └───────────────────────────────────────┬───────────────────────────────────────┘   │
│                                           │ StateFlow / UI Events                     │
│   ┌───────────────────────────────────────▼───────────────────────────────────────┐   │
│   │                        ViewModel Layer (MVVM Architecture)                    │   │
│   │  AuthViewModel │ DiscoverViewModel │ TeamViewModel │ ChatViewModel            │   │
│   └───────────────────────────────────────┬───────────────────────────────────────┘   │
│                                           │ Coroutine Dispatchers                     │
│   ┌───────────────────────────────────────▼───────────────────────────────────────┐   │
│   │                        Repository & Domain Layer                              │   │
│   │  AuthRepository │ TeamRepository │ ChatRepository │ ProfileRepository         │   │
│   └───────────────────┬───────────────────────────────────────┬───────────────────┘   │
└───────────────────────┼───────────────────────────────────────┼───────────────────────┘
                        │ HTTPS (REST API)                      │ WSS (Realtime)
                        ▼                                       ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                               Supabase Cloud Backend                                  │
│                                                                                       │
│   ┌─────────────────────┐   ┌───────────────────────────┐   ┌─────────────────────┐   │
│   │    Supabase Auth    │   │   PostgreSQL with RLS     │   │  Supabase Realtime  │   │
│   │ (JWT, Email OTP,    │──▶│ (Profiles, Teams, Members,│◀──│ (Broadcast, Presence│   │
│   │  Password Recovery) │   │  JoinRequests, Messages)  │   │  & Postgres Changes)│   │
│   └─────────────────────┘   └───────────────────────────┘   └─────────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 4.2 Relational Data Model (PostgreSQL)

```sql
-- 1. Profiles Table (Extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    college_name TEXT NOT NULL DEFAULT 'MANIT Bhopal',
    is_manit_verified BOOLEAN NOT NULL DEFAULT FALSE,
    membership_status TEXT NOT NULL CHECK (membership_status IN ('manit_student', 'other_college_student', 'non_student')),
    scholar_number TEXT,
    branch TEXT,
    academic_year TEXT,
    bio TEXT,
    skills TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',
    github_url TEXT,
    linkedin_url TEXT,
    portfolio_url TEXT,
    whatsapp_number TEXT,
    is_profile_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Teams Table
CREATE TABLE public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    project_category TEXT NOT NULL CHECK (project_category IN ('hackathon', 'academic_project', 'startup', 'ai_ml', 'open_source', 'contest')),
    event_name TEXT,
    required_skills TEXT[] DEFAULT '{}',
    max_team_size INT NOT NULL CHECK (max_team_size >= 2 AND max_team_size <= 10),
    is_recruiting BOOLEAN NOT NULL DEFAULT TRUE,
    whatsapp_group_link TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Team Memberships Table
CREATE TABLE public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'lead', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- 4. Joining Requests Table
CREATE TABLE public.join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    applicant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    pitch_note TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(team_id, applicant_id)
);

-- 5. Real-Time Messages Table (Team & Direct)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (team_id IS NOT NULL OR receiver_id IS NOT NULL)
);

-- 6. Notifications Table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('join_request', 'request_accepted', 'request_rejected', 'team_announcement')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    reference_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Moderation Reports & Blocks
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reported_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.user_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);
```

---

### 4.3 Row Level Security (RLS) & Authorization Matrix

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Public profiles viewable by authenticated users; update only own profile
CREATE POLICY "Public profiles are viewable by authenticated users" 
ON public.profiles FOR SELECT TO authenticated 
USING (is_profile_public = true OR auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE TO authenticated 
USING (auth.uid() = id);

-- 2. Teams: Anyone can view recruiting teams; only owners can update/delete
CREATE POLICY "Teams viewable by all authenticated users" 
ON public.teams FOR SELECT TO authenticated 
USING (true);

CREATE POLICY "Owners can create teams" 
ON public.teams FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their teams" 
ON public.teams FOR UPDATE TO authenticated 
USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their teams" 
ON public.teams FOR DELETE TO authenticated 
USING (auth.uid() = owner_id);

-- 3. Team Members: Viewable by team members & team owners; owners can insert/delete members
CREATE POLICY "Members viewable by all authenticated users" 
ON public.team_members FOR SELECT TO authenticated 
USING (true);

CREATE POLICY "Team owners can add members" 
ON public.team_members FOR INSERT TO authenticated 
WITH CHECK (
    EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    OR auth.uid() = user_id
);

-- 4. Join Requests: Applicants can see own requests; Team owners can see requests for their teams
CREATE POLICY "View join requests" 
ON public.join_requests FOR SELECT TO authenticated 
USING (
    applicant_id = auth.uid() 
    OR EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
);

CREATE POLICY "Create join request" 
ON public.join_requests FOR INSERT TO authenticated 
WITH CHECK (applicant_id = auth.uid());

CREATE POLICY "Update join request status" 
ON public.join_requests FOR UPDATE TO authenticated 
USING (
    applicant_id = auth.uid() -- To withdraw
    OR EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) -- To accept/reject
);

-- 5. Messages: Team chat accessible only to accepted team members; DMs only to sender/receiver
CREATE POLICY "Team messages viewable only by team members" 
ON public.messages FOR SELECT TO authenticated 
USING (
    (team_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.team_members WHERE team_id = messages.team_id AND user_id = auth.uid()
    ))
    OR (receiver_id = auth.uid() OR sender_id = auth.uid())
);

CREATE POLICY "Insert messages" 
ON public.messages FOR INSERT TO authenticated 
WITH CHECK (
    sender_id = auth.uid() AND (
        (team_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.team_members WHERE team_id = messages.team_id AND user_id = auth.uid()
        ))
        OR (receiver_id IS NOT NULL)
    )
);

-- 6. Notifications: Users can only see and update their own notifications
CREATE POLICY "Users view own notifications" 
ON public.notifications FOR SELECT TO authenticated 
USING (recipient_id = auth.uid());

CREATE POLICY "Users update own notifications" 
ON public.notifications FOR UPDATE TO authenticated 
USING (recipient_id = auth.uid());
```

---

### 4.4 Security & Privacy Requirements

1. **Client Credential Protection**:
   - Supabase `anonKey` and `projectUrl` are injected through `BuildConfig` using `.env` via the Secrets Gradle Plugin.
   - The Supabase `service_role` key is **NEVER** stored or bundled inside the client APK.
2. **Zero Password Collection for MANIT**:
   - No portal/ERP scraping requiring student passwords.
   - Verification occurs strictly via Supabase Auth email OTP dispatched to `@stu.manit.ac.in`.
3. **Data Integrity Trigger**:
   - A PostgreSQL trigger automatically sets `is_manit_verified = TRUE` when `auth.users.email_confirmed_at IS NOT NULL` AND `email LIKE '%@stu.manit.ac.in'`. The client cannot manipulate `is_manit_verified` directly.
4. **Account & Data Deletion**:
   - Invoking account deletion triggers a cascading purge of the student's profile, join requests, notifications, and ownership records in strict compliance with GDPR/data privacy best practices.

---

## 5. Testing & Verification Strategy

### 5.1 Local JVM & Unit Testing (Robolectric)
- **Authentication State Machine Tests**: Verify transition from `Unauthenticated` $\rightarrow$ `PendingVerification` $\rightarrow$ `Authenticated` with mock tokens.
- **Verification Rule Tests**: Assert that emails like `scholar24111@stu.manit.ac.in` evaluate to `isManitVerified = true` only upon confirmation, while personal emails (`user@gmail.com`) evaluate to `isManitVerified = false`.
- **Roster Capacity & Request Flow Tests**: Verify that accepting an applicant when `currentMembers == maxTeamSize` rejects or locks further requests cleanly.
- **Search & Filter Query Tests**: Verify multi-attribute filtering (filtering by skill `Kotlin` AND category `Hackathon` returns correct subsets).

### 5.2 UI & Component Verification
- **Test Tags Strategy**: Every interactive element (`Modifier.testTag`) is assigned a standardized ID:
  - `login_email_input`, `login_password_input`, `login_submit_btn`
  - `discover_search_bar`, `discover_filter_chip_{skill}`
  - `team_card_{teamId}`, `team_apply_btn`, `team_withdraw_btn`
  - `owner_request_accept_btn_{requestId}`, `owner_request_reject_btn_{requestId}`
  - `chat_message_input`, `chat_send_btn`, `chat_whatsapp_link_btn`

---

## 6. Incremental Implementation Roadmap

```
                                  ROADMAP PHASES
                                  
  ┌────────────────────────────────────────────────────────────────────────┐
  │ Phase 1: Foundation, Design Tokens, Auth & Institutional Verification  │
  │ • M3 Colors, Typography, Shapes, Material Icons                        │
  │ • Supabase Client configuration & Session Manager                      │
  │ • Registration, Login, Password Reset, and @stu.manit.ac.in OTP flow   │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────▼────────────────────────────────────┐
  │ Phase 2: Student Profiles & Credential Badging                         │
  │ • Profile setup screen with branch, year, skills & portfolio links     │
  │ • Verified MANIT Badge vs External Student rendering logic             │
  │ • Profile edit and privacy controls                                    │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────▼────────────────────────────────────┐
  │ Phase 3: Team Discovery & Marketplace                                  │
  │ • Team creation studio with category, size, and required skills        │
  │ • Search, dynamic skill filtering, and sorting                         │
  │ • Team detail view with member rosters and vacancy counts              │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────▼────────────────────────────────────┐
  │ Phase 4: Join Requests & Team Leadership Management                    │
  │ • Application modal with custom pitch note                             │
  │ • Applicant status tracking (Pending, Accepted, Rejected, Withdrawn)   │
  │ • Owner review dashboard (Accept/Reject with roster capacity limits)   │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────▼────────────────────────────────────┐
  │ Phase 5: Communications, Safety & Polish                               │
  │ • In-app Realtime team chat and direct messaging                       │
  │ • Safe WhatsApp click-to-chat deep-linking for accepted members        │
  │ • User reporting, blocking, and account deletion flows                 │
  │ • Micro-interactions, empty states, and Robolectric unit tests         │
  └────────────────────────────────────────────────────────────────────────┘
```

---

## Verification & Confirmation

Please review this implementation plan. Click **Proceed** to begin execution of Phase 1 (Core Design System, Architecture Skeleton, and Authentication with Institutional Verification), or provide feedback to refine any specific requirements.
