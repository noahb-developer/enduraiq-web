-- migrate_v6.sql
-- Adds locale support to profiles so users can pick their UI language
-- (English / French) at signup and switch in Settings later.
-- Coach already responds in the user's language (Layer A), this unlocks
-- the rest of the UI translating too (Layer B).
--
-- Idempotent — safe to run multiple times.
-- Run this in Supabase Studio → SQL Editor (full file, hit Run).

-- ─── profiles.locale ──────────────────────────────────────────
-- Two-letter language code: 'en' (default) or 'fr'. More languages
-- can be added later without a migration; UI just needs more translations.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS locale TEXT DEFAULT 'en';

-- Backfill any existing NULL rows to 'en' so the frontend never sees null
UPDATE public.profiles SET locale = 'en' WHERE locale IS NULL;

-- ─── Done ─────────────────────────────────────────────────────
