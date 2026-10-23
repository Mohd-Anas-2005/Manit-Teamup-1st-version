-- MANIT TeamUp: Team Discovery & Management Performance Indexes
-- Migration: 20261021000007_team_discovery_and_management.sql
-- Description: Adds indexes for team search, event filtering, and open team browsing.

-- =============================================================================
-- 1. FREQUENTLY SEARCHED TEAM FIELDS INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_teams_name 
    ON public.teams(name);

CREATE INDEX IF NOT EXISTS idx_teams_event_name 
    ON public.teams(event_name);

-- Composite index for browsing open recruitment teams sorted by newest
CREATE INDEX IF NOT EXISTS idx_teams_open_browse 
    ON public.teams(recruitment_status, created_at DESC);

-- Index on team members for fast membership queries
CREATE INDEX IF NOT EXISTS idx_team_members_team_role 
    ON public.team_members(team_id, role);
