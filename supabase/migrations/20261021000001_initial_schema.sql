-- MANIT TeamUp: Supabase PostgreSQL Schema Migration
-- Migration: 20261021000001_initial_schema.sql
-- Description: Creates core database tables, constraints, foreign keys, and indexes.

-- Enable pgcrypto for UUID generation if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. PROFILES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    college_name TEXT NOT NULL DEFAULT 'MANIT Bhopal',
    membership_status TEXT NOT NULL DEFAULT 'manitStudent' 
        CHECK (membership_status IN ('manitStudent', 'otherCollege', 'nonStudent')),
    membership_verification_status TEXT NOT NULL DEFAULT 'unverified' 
        CHECK (membership_verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
    branch TEXT NOT NULL DEFAULT 'Computer Science & Engineering',
    academic_year TEXT NOT NULL DEFAULT '1st Year B.Tech',
    bio TEXT NOT NULL DEFAULT '',
    skills TEXT[] NOT NULL DEFAULT '{}',
    interests TEXT[] NOT NULL DEFAULT '{}',
    portfolio_url TEXT,
    scholar_number TEXT,
    github_url TEXT,
    linkedin_url TEXT,
    whatsapp_number TEXT,
    is_profile_public BOOLEAN NOT NULL DEFAULT true,
    allow_whatsapp_direct BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_college_name 
    ON public.profiles(college_name);
CREATE INDEX IF NOT EXISTS idx_profiles_verification_status 
    ON public.profiles(membership_verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_membership_status 
    ON public.profiles(membership_status);
CREATE INDEX IF NOT EXISTS idx_profiles_skills 
    ON public.profiles USING GIN (skills);
CREATE INDEX IF NOT EXISTS idx_profiles_interests 
    ON public.profiles USING GIN (interests);

-- =============================================================================
-- 2. TEAMS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 2),
    description TEXT,
    category TEXT NOT NULL CHECK (
        category IN ('hackathon', 'academicProject', 'startup', 'aiMl', 'openSource', 'competitiveProgramming')
    ),
    event_name TEXT,
    required_skills TEXT[] NOT NULL DEFAULT '{}',
    max_members INTEGER NOT NULL DEFAULT 4 CHECK (max_members >= 1 AND max_members <= 30),
    recruitment_status TEXT NOT NULL DEFAULT 'open' CHECK (
        recruitment_status IN ('open', 'closed', 'paused')
    ),
    whatsapp_group_link TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Teams Indexes
CREATE INDEX IF NOT EXISTS idx_teams_owner_id 
    ON public.teams(owner_id);
CREATE INDEX IF NOT EXISTS idx_teams_category 
    ON public.teams(category);
CREATE INDEX IF NOT EXISTS idx_teams_recruitment_status 
    ON public.teams(recruitment_status);
CREATE INDEX IF NOT EXISTS idx_teams_created_at 
    ON public.teams(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_teams_required_skills 
    ON public.teams USING GIN (required_skills);

-- =============================================================================
-- 3. TEAM MEMBERS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'lead', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_team_member UNIQUE (team_id, user_id)
);

-- Team Members Indexes
CREATE INDEX IF NOT EXISTS idx_team_members_team_id 
    ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id 
    ON public.team_members(user_id);

-- =============================================================================
-- 4. JOIN REQUESTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL CHECK (char_length(trim(message)) >= 1),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'accepted', 'rejected', 'withdrawn')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Prevent duplicate active (pending) requests for the same team by the same requester
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_join_request 
    ON public.join_requests(team_id, requester_id) 
    WHERE (status = 'pending');

-- Join Requests Indexes
CREATE INDEX IF NOT EXISTS idx_join_requests_team_id 
    ON public.join_requests(team_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_requester_id 
    ON public.join_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status 
    ON public.join_requests(status);

-- =============================================================================
-- 5. NOTIFICATIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (
        type IN ('joinRequest', 'requestAccepted', 'requestRejected', 'requestWithdrawn', 'teamAnnouncement', 'directMessage')
    ),
    title TEXT NOT NULL CHECK (char_length(trim(title)) >= 1),
    body TEXT NOT NULL CHECK (char_length(trim(body)) >= 1),
    related_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created 
    ON public.notifications(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
    ON public.notifications(recipient_id) 
    WHERE (read_at IS NULL);

-- =============================================================================
-- 6. BLOCKS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.blocks (
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (blocker_id, blocked_id),
    CONSTRAINT chk_no_self_block CHECK (blocker_id <> blocked_id)
);

-- Blocks Index
CREATE INDEX IF NOT EXISTS idx_blocks_blocked_id 
    ON public.blocks(blocked_id);

-- =============================================================================
-- 7. REPORTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 2),
    details TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'under_review', 'resolved', 'dismissed')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_report_target CHECK (reported_user_id IS NOT NULL OR team_id IS NOT NULL)
);

-- Reports Indexes
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id 
    ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id 
    ON public.reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_team_id 
    ON public.reports(team_id);
CREATE INDEX IF NOT EXISTS idx_reports_status 
    ON public.reports(status);
