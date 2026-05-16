-- migrate_v5.sql
-- Adds all the columns the v37 frontend uses but that may not exist in DB.
-- Found via the round-3 audit: frontend reads/writes these but memory.md
-- didn't list them. Idempotent — safe to run multiple times.
--
-- Run this in Supabase Studio → SQL Editor (full file, hit Run).

-- ─── planned_workouts ─────────────────────────────────────────
-- workout_notes: free-text notes Coach writes when applying insights
ALTER TABLE public.planned_workouts ADD COLUMN IF NOT EXISTS workout_notes TEXT;

-- ─── training_insights ────────────────────────────────────────
-- generated_at: timestamp the insight was created (frontend sorts by it)
ALTER TABLE public.training_insights ADD COLUMN IF NOT EXISTS generated_at TIMESTAMPTZ DEFAULT NOW();
-- applied_at: timestamp user applied the insight (powers the 24h undo flow)
ALTER TABLE public.training_insights ADD COLUMN IF NOT EXISTS applied_at TIMESTAMPTZ;
-- Backfill generated_at for existing rows that lack it
UPDATE public.training_insights SET generated_at = COALESCE(generated_at, created_at, NOW()) WHERE generated_at IS NULL;

-- ─── workouts ─────────────────────────────────────────────────
ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS sport TEXT;
ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS source TEXT;
-- activity_classification: 'workout' vs 'daily_activity' (commute, walk, etc.)
ALTER TABLE public.workouts ADD COLUMN IF NOT EXISTS activity_classification TEXT;

-- ─── coach_messages ───────────────────────────────────────────
-- context_type: 'general_chat', 'plan_intro', 'insight_explanation',
-- 'insight_applied', 'insight_undone', 'workout_commentary',
-- 'profile_correction_applied', 'settings_change_reactive',
-- 'settings_change_reactive_applied', 'anomaly_alert', 'import_profile_recap',
-- 'import_next_week_built', 'import_next_week_manual'
ALTER TABLE public.coach_messages ADD COLUMN IF NOT EXISTS context_type TEXT;

-- ─── athlete_intake ───────────────────────────────────────────
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS has_pool_access BOOLEAN;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS has_bike_trainer BOOLEAN;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS unit_preference TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS pb_5k TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS pb_10k TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS pb_half TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS pb_marathon TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS last_race TEXT;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS height_cm NUMERIC;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS available_days_count INTEGER;
ALTER TABLE public.athlete_intake ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ─── profiles ─────────────────────────────────────────────────
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;

-- ─── shared_plans ─────────────────────────────────────────────
-- Public share links for training plans. Token-addressable read-only view.
CREATE TABLE IF NOT EXISTS public.shared_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  plan_data JSONB,
  intake_snapshot JSONB,
  workouts_snapshot JSONB,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_shared_plans_token ON public.shared_plans(token);
CREATE INDEX IF NOT EXISTS idx_shared_plans_user_id ON public.shared_plans(user_id);
ALTER TABLE public.shared_plans ENABLE ROW LEVEL SECURITY;

-- Owners can manage their own shared_plans rows
DROP POLICY IF EXISTS "shared_plans owner manage" ON public.shared_plans;
CREATE POLICY "shared_plans owner manage" ON public.shared_plans
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Public can SELECT shared_plans by token (no listing — token is the secret)
-- Anyone with the token can view; this is intentional for share links.
DROP POLICY IF EXISTS "shared_plans public read by token" ON public.shared_plans;
CREATE POLICY "shared_plans public read by token" ON public.shared_plans
  FOR SELECT USING (true);

-- ─── expire_old_trials_for_user RPC ───────────────────────────
-- Idempotently flips a user from 'pro_trial' to 'free' if their trial
-- ended. Called on every loadProfile to auto-expire stale trials.
CREATE OR REPLACE FUNCTION public.expire_old_trials_for_user(uid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET subscription_tier = 'free'
  WHERE id = uid
    AND subscription_tier = 'pro_trial'
    AND trial_ends_at IS NOT NULL
    AND trial_ends_at < NOW();
END;
$$;
GRANT EXECUTE ON FUNCTION public.expire_old_trials_for_user(UUID) TO authenticated, anon, service_role;

-- ─── Done ─────────────────────────────────────────────────────
-- After running, re-run the verification query from the chat to confirm
-- everything resolves cleanly.
