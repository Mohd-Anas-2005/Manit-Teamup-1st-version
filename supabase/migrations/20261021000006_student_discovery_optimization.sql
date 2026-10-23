-- MANIT TeamUp: Student Discovery Optimization & Privacy Hardening
-- Migration: 20261021000006_student_discovery_optimization.sql
-- Description: Adds indexes for frequently searched student fields (branch, academic_year,
-- display_name, pagination), and enforces security_invoker = true on discoverable_profiles
-- to ensure block relationships and Row Level Security are strictly respected.

-- =============================================================================
-- 1. FREQUENTLY SEARCHED DISCOVERY INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_branch 
    ON public.profiles(branch);

CREATE INDEX IF NOT EXISTS idx_profiles_academic_year 
    ON public.profiles(academic_year);

CREATE INDEX IF NOT EXISTS idx_profiles_display_name 
    ON public.profiles(display_name);

-- Composite index for paginated public discovery
CREATE INDEX IF NOT EXISTS idx_profiles_discovery_paging 
    ON public.profiles(is_profile_public, created_at DESC);

-- =============================================================================
-- 2. SECURITY-INVOKER DISCOVERABLE PROFILES VIEW
-- =============================================================================
-- Setting security_invoker = true ensures that queries execute under the caller's
-- authenticated role, strictly respecting profiles_select_policy:
-- - Mutual block relationships are enforced (are_users_mutually_blocked)
-- - Private profiles (is_profile_public = false) are never exposed to non-teammates
-- - Sensitive columns (scholar_number, whatsapp_number) are omitted from the projection
CREATE OR REPLACE VIEW public.discoverable_profiles 
WITH (security_invoker = true) AS
SELECT 
    p.id,
    p.display_name,
    p.avatar_url,
    p.college_name,
    p.membership_status,
    p.membership_verification_status,
    (p.membership_status = 'manitStudent' AND p.membership_verification_status = 'verified') AS is_manit_verified,
    p.branch,
    p.academic_year,
    p.bio,
    p.skills,
    p.interests,
    p.portfolio_url,
    p.github_url,
    p.linkedin_url,
    p.created_at
FROM public.profiles p
WHERE p.is_profile_public = true;

GRANT SELECT ON public.discoverable_profiles TO authenticated;
