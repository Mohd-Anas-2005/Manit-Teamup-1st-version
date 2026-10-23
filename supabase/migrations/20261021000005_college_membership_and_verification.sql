-- MANIT TeamUp: College Membership & Verification System
-- Migration: 20261021000005_college_membership_and_verification.sql
-- Description: Supports pending_review verification status, authorized verification workflow RPC,
-- student verification submission, and secure discoverable profiles view excluding sensitive PII.

-- =============================================================================
-- 1. UPDATE VERIFICATION STATUS CHECK CONSTRAINT
-- =============================================================================
ALTER TABLE public.profiles 
    DROP CONSTRAINT IF EXISTS profiles_membership_verification_status_check;

ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_membership_verification_status_check 
    CHECK (membership_verification_status IN ('unverified', 'pending', 'pending_review', 'verified', 'rejected'));

-- =============================================================================
-- 2. USER RPC: REQUEST VERIFICATION (SUBMIT FOR REVIEW)
-- =============================================================================
-- Ordinary MANIT students can transition their status from 'unverified' to 'pending_review'.
-- They can NEVER assign themselves 'verified'.
CREATE OR REPLACE FUNCTION public.submit_for_verification(
    p_scholar_number TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to submit for verification';
    END IF;

    SELECT * INTO v_profile 
    FROM public.profiles 
    WHERE id = v_caller_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found for authenticated user';
    END IF;

    IF v_profile.membership_status <> 'manitStudent' THEN
        RAISE EXCEPTION 'Only MANIT students are eligible for MANIT institutional verification';
    END IF;

    IF v_profile.membership_verification_status = 'verified' THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Account is already verified as a MANIT Scholar',
            'status', 'verified'
        );
    END IF;

    UPDATE public.profiles
    SET 
        membership_verification_status = 'pending_review',
        scholar_number = coalesce(p_scholar_number, scholar_number),
        updated_at = timezone('utc'::text, now())
    WHERE id = v_caller_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Verification request submitted for institutional review',
        'status', 'pending_review'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_for_verification(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_for_verification(TEXT) TO authenticated, service_role;

-- =============================================================================
-- 3. ADMINISTRATIVE WORKFLOW RPC: REVIEW MEMBERSHIP VERIFICATION
-- =============================================================================
-- Only authorized service_role or admin processes can grant 'verified' or 'rejected'.
CREATE OR REPLACE FUNCTION public.review_membership_verification(
    p_target_user_id UUID,
    p_new_status TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_profile RECORD;
BEGIN
    -- Strict authorization check: Only service_role or database admin can approve
    IF (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' 
       AND current_user NOT IN ('postgres', 'supabase_admin') THEN
        RAISE EXCEPTION 'Unauthorized: Only institutional verification authorities may review credentials';
    END IF;

    IF p_new_status NOT IN ('unverified', 'pending_review', 'verified', 'rejected') THEN
        RAISE EXCEPTION 'Invalid verification status: %', p_new_status;
    END IF;

    SELECT * INTO v_target_profile 
    FROM public.profiles 
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target scholar profile not found: %', p_target_user_id;
    END IF;

    UPDATE public.profiles
    SET 
        membership_verification_status = p_new_status,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_target_user_id;

    -- Generate notification for the user
    IF p_new_status = 'verified' THEN
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body
        ) VALUES (
            p_target_user_id,
            'teamAnnouncement',
            'Scholar Verification Approved! 🎓',
            'Congratulations! Your MANIT scholar verification is approved. You now hold the Verified Scholar badge.'
        );
    ELSIF p_new_status = 'rejected' THEN
        INSERT INTO public.notifications (
            recipient_id,
            type,
            title,
            body
        ) VALUES (
            p_target_user_id,
            'teamAnnouncement',
            'Verification Review Update',
            coalesce(p_notes, 'Your scholar verification could not be approved. Please check your credentials.')
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', p_target_user_id,
        'status', p_new_status
    );
END;
$$;

REVOKE ALL ON FUNCTION public.review_membership_verification(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.review_membership_verification(UUID, TEXT, TEXT) TO service_role;

-- =============================================================================
-- 4. SECURE DISCOVERABLE SCHOLAR PROFILES VIEW
-- =============================================================================
-- Protects sensitive student PII: Excludes scholar_number and private contact information
-- Exposes only public collaboration information.
CREATE OR REPLACE VIEW public.discoverable_profiles AS
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
