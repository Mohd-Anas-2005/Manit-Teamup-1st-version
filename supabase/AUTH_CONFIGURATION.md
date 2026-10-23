# MANIT TeamUp — Supabase Dashboard Authentication Setup Guide

This guide details the mandatory and recommended manual configuration steps in the **Supabase Cloud Dashboard** (`https://supabase.com/dashboard/project/<project-ref>`) to activate real authentication, deep linking, institutional verification, and password recovery.

---

## 1. Auth Providers Configuration

1. In the Supabase Dashboard, navigate to **Authentication** > **Providers**.
2. Select **Email**:
   - **Enable Email Provider**: `ON`
   - **Confirm email**: `ON` *(Mandatory for production security: forces users to verify institutional addresses before account activation)*.
   - **Secure email change**: `ON`
   - **Enable Email Signups**: `ON`
   - **Minimum password length**: `6` (recommended `8` for production).

---

## 2. URL & Deep Link Configuration (Android & Web)

When users click verification or password recovery links in their email, Supabase redirects them back into the application.

1. Navigate to **Authentication** > **URL Configuration**.
2. **Site URL**:
   Set this to your production web endpoint or default callback:
   ```
   io.supabase.manitteamup://auth-callback
   ```
3. **Redirect URLs**:
   Add the mobile application URI scheme and local testing URLs:
   ```
   io.supabase.manitteamup://auth-callback
   io.supabase.manitteamup://auth-callback/**
   http://localhost:3000/**
   ```

> **Note**: The Android intent filter is configured in `android/app/src/main/AndroidManifest.xml` with:
> - `android:scheme="io.supabase.manitteamup"`
> - `android:host="auth-callback"`

---

## 3. Email Templates Configuration

Navigate to **Authentication** > **Email Templates**.

### A. Confirm Signup (Email Verification)
- **Subject**: `Confirm your MANIT Scholar account | MANIT TeamUp`
- **Body**:
```html
<h2>Welcome to MANIT TeamUp! 🎓</h2>
<p>Hello Scholar,</p>
<p>Thank you for registering. Please confirm your email address to activate your account and receive your Verified MANIT Scholar status:</p>
<p>
  <a href="{{ .ConfirmationURL }}" style="display:inline-block;padding:12px 24px;background-color:#7C3AED;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:bold;">
    Verify My Institutional Email
  </a>
</p>
<p>If the button doesn't work, copy and paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>If you did not register for MANIT TeamUp, please ignore this email.</p>
```

### B. Reset Password (Password Recovery)
- **Subject**: `Reset your password | MANIT TeamUp`
- **Body**:
```html
<h2>MANIT TeamUp Password Recovery</h2>
<p>Hello Scholar,</p>
<p>We received a request to reset your password. Tap the link below to set a new password:</p>
<p>
  <a href="{{ .ConfirmationURL }}" style="display:inline-block;padding:12px 24px;background-color:#06B6D4;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:bold;">
    Set New Password
  </a>
</p>
<p>Or paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>This link expires in 1 hour.</p>
```

---

## 4. Custom SMTP Server (Recommended for Campus Production)

By default, Supabase sends up to 3 emails per hour on the free tier using default mailers. For campus-wide scale across thousands of students:

1. Navigate to **Project Settings** > **Authentication** > **SMTP Settings**.
2. **Enable Custom SMTP**: `ON`
3. Configure institutional or dedicated transactional SMTP provider (SendGrid, Resend, Amazon SES, or MANIT Mail Server):
   - **Sender Email**: `teamup-noreply@manit.ac.in` (or your verified domain)
   - **Sender Name**: `MANIT TeamUp Campus Collaboration`
   - **Host, Port, User, and Password**: Supplied by your SMTP provider.

---

## 5. Security Checklist

| Requirement | Implementation & Enforcement |
|---|---|
| **Zero hardcoded credentials** | Flutter client uses `--dart-define=SUPABASE_URL` and `SUPABASE_ANON_KEY`. |
| **No service-role key in client** | Strictly verified via automated test suite `npm test`. |
| **Passwords handled by Supabase** | Passwords are never stored in `profiles` or logs; handled via PBKDF2/bcrypt in GoTrue. |
| **Session persistence** | Managed via secure storage in `supabase_flutter`. |
| **Expired session handling** | Auto-detected; prompts user with clean re-authentication message. |
| **Protected navigation** | Enforced by `AuthGate`; no premature routing to authenticated tabs. |
