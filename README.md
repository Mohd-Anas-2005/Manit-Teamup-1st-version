# MANIT TeamUp

A dedicated campus collaboration and teammate discovery mobile application for **Maulana Azad National Institute of Technology (MANIT Bhopal)**.

---

## Overview

**MANIT TeamUp** empowers students, developers, designers, and innovators across departments at MANIT Bhopal to:
- **Discover Teammates**: Find partners for Smart India Hackathon (SIH), internal hackathons, coding competitions, minor/major academic projects, and startup ventures.
- **Filter by Skills & Branches**: Filter by technical expertise (AI/ML, Mobile/Flutter, Web, Cloud, IoT, Robotics, UI/UX) and departments (CSE, IT, ECE, EE, Mech, Civil, Chem, MSME, Architecture, MCA, M.Tech, MBA).
- **Institutional Verification**: Auto-detects and verifies scholar credentials using institutional `@stu.manit.ac.in` and `@manit.ac.in` email addresses with distinctive Verified Scholar badges.
- **Roster & Request Management**: Publish team broadcasts, define vacancy requirements, submit joining pitches, approve/decline applications, and link directly to WhatsApp collaboration channels.

---

## Technology Stack

- **Framework:** Flutter (Channel stable, Dart 3.13+ with null safety)
- **UI & Design:** Material 3 with custom Design System tokens
- **Backend / Authentication:** Supabase Flutter SDK (`supabase_flutter`)
- **Architecture:** Feature-Oriented Modular Architecture
- **Navigation:** Android NavigationBar with edge-to-edge system UI and `PopScope` predictive back navigation
- **Testing:** Automated unit, token, and widget tests via `flutter_test`

---

## Design System Tokens

The application employs a dark atmospheric theme:

| Token | Hex / Color | Usage |
|---|---|---|
| **Midnight Navy Deep** | `#060912` | Bottom NavigationBar, deep backgrounds |
| **Midnight Navy** | `#0A0E1A` | Primary Scaffold background |
| **Charcoal Surface** | `#141926` | Card backgrounds, elevated components |
| **Charcoal Surface Variant** | `#1E2436` | Input fields, chips, secondary surfaces |
| **Electric Violet** | `#7C3AED` | Primary brand anchor, primary action buttons |
| **Electric Violet Glow** | `#A78BFA` | Selected icons, highlights, gradients |
| **Cyan Accent** | `#06B6D4` | Live active indicators, hackathon tags |
| **Coral Accent** | `#F43F5E` | Open vacancy alerts, urgent recruitment badges |
| **Magenta Accent** | `#D946EF` | Verified scholar gradient highlight |
| **Status Success** | `#10B981` | Verification approved, accepted requests |
| **Status Warning** | `#F59E0B` | Pending reviews, unconfigured status |

---

## Project & Package Structure

```
lib/
├── app/
│   └── app.dart                         # MaterialApp, root routes, theme binding
├── core/
│   ├── navigation/
│   │   ├── app_scaffold.dart            # Android NavigationBar & PopScope back handler
│   │   └── nav_destination.dart         # Navigation tabs definition
│   ├── services/
│   │   └── supabase_service.dart        # Production Supabase client & environment initialization
│   ├── theme/
│   │   ├── app_colors.dart              # Approved coordinated color palette & gradients
│   │   ├── app_theme.dart               # Material 3 ThemeData configuration
│   │   └── app_typography.dart          # Display, headline, body, label typography
│   └── widgets/
│       ├── app_button.dart              # Reusable gradient, solid, and outline buttons
│       ├── gradient_card.dart           # Atmospheric glassmorphic surface cards
│       ├── manit_badge.dart             # Verified Scholar, Scholar ID, & vacancy badges
│       └── state_views.dart             # Loading, Error, Empty, and Success state components
├── features/
│   ├── authentication/
│   │   ├── domain/auth_state.dart       # Authentication models & email verification logic
│   │   └── presentation/                # Login and Registration screens
│   ├── onboarding/
│   │   └── presentation/                # Campus discovery onboarding flow
│   ├── discovery/
│   │   ├── domain/discovery_filter.dart # Teammate and hackathon filters
│   │   └── presentation/                # Discovery feed and filter sheets
│   ├── teams/
│   │   ├── domain/team.dart             # Team, TeamMember, Role, and Category models
│   │   └── presentation/                # Teams workspace and Create Team broadcast
│   ├── joining_requests/
│   │   ├── domain/join_request.dart     # JoinRequest and RequestStatus models
│   │   └── presentation/                # Incoming and sent application management
│   ├── notifications/
│   │   ├── domain/notification_item.dart# NotificationItem & NotificationType models
│   │   └── presentation/                # Campus alerts & invitations screen
│   ├── profiles/
│   │   ├── domain/user_profile.dart     # UserProfile, MembershipStatus models
│   │   └── presentation/                # Scholar Profile and Edit Profile screens
│   └── settings/
│       └── presentation/                # Privacy, WhatsApp toggles, & connection status
└── main.dart                            # Application entry point with safe async init
```

---

## Environment & Supabase Configuration

This project enforces security best practices: **no secrets or API keys are committed to source control**.

Configure Supabase via `--dart-define` flags or a `.env` file:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For live Supabase dashboard configuration (email confirmation, URL redirects, templates, SMTP), see [`supabase/AUTH_CONFIGURATION.md`](supabase/AUTH_CONFIGURATION.md).

When run without parameters, the application automatically handles the unconfigured state gracefully by showing clean empty and configuration status indicators in Settings.

---

## Verification & Build Instructions

### 1. Fetch Dependencies
```bash
flutter pub get
```

### 2. Static Analysis & Lint Verification
```bash
flutter analyze
```

### 3. Run Automated Tests
```bash
flutter test
```

The test suite covers:
- `test/auth_service_test.dart`: Supabase `AppAuthState` domain models, institutional email verification logic, and `AuthService` state transitions.
- `test/auth_screens_test.dart`: Real auth widget tests for `LoginScreen`, `RegisterScreen` (password confirmation, visibility toggle), `ForgotPasswordScreen`, `EmailVerificationScreen`, and reactive `AuthGate`.
- `test/widget_test.dart`: App smoke test, navigation destinations, and Android back navigation (`PopScope`).
- `test/theme_test.dart`: Theme tokens, color palettes, typography, and Material 3 dark color scheme.
- `test/state_views_test.dart`: Reusable state views (`LoadingStateView`, `ErrorStateView`, `EmptyStateView`, `SuccessStateView`).
- `test/widgets_test.dart`: Core tokens (`ManitBadge`, `AppButton`, `GradientCard`).

### 4. Run Application
```bash
flutter run
```

---

## Supabase Backend & Database Security

The backend is version-controlled in the `supabase/` directory with defense-in-depth PostgreSQL migrations and Row Level Security:

- **Schema Migrations**: `supabase/migrations/`
  - `20261021000001_initial_schema.sql`: 7 core tables (`profiles`, `teams`, `team_members`, `join_requests`, `notifications`, `blocks`, `reports`), foreign keys, GIN/B-tree indexes, and constraints.
  - `20261021000002_security_functions_and_rpc.sql`: Concurrency-safe `accept_join_request()` RPC with row-level locks, mutual block helpers, explicit search path, and revoked public permissions.
  - `20261021000003_row_level_security.sql`: RLS enabled and forced across all tables with least-privilege policies.
  - `20261021000004_triggers_and_automation.sql`: Immutability triggers, membership verification status protection, auto-enrollment of team owners, and notifications.
- **Security Documentation**: [`supabase/SECURITY.md`](supabase/SECURITY.md)
- **Database pgTAP Tests**: `supabase/tests/database/`
- **Backend Verification Suite**:
  ```bash
  npm test
  ```
  Runs 50 automated checks across schema definitions, RLS enforcement, RPC concurrency safety, and secrets absence.

---

## Legacy Android Prototype

The earlier Jetpack Compose Android prototype is preserved in `app/` and `README_legacy.md` for domain reference and platform asset compatibility.
