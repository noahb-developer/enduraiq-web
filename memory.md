# Stryxs — Project Memory

> **Read this first in every fresh chat. It captures everything you need to be productive immediately.**
>
> Last updated: 2026-05-15, end of pre-launch sprint round 3 (Coach v8 / Frontend v37 / send-followups deployed). Round 3 was a full audit + fix pass. See section 10 for what changed.

---

## 1. Who's working on this

**Noah Barbier** (sometimes goes by Alex in conversation).
- **Age 17**, IB Diploma student in Florida.
- Building Stryxs solo while also training for **Ironman Jacksonville (May 2027)**.
- Training data: Bike LTHR 168, Run LTHR 182, Swim CSS 1:56/100m. Triathlon schedule: one gym Thursday (leg press, no upper body), Sunday alternates between 2nd swim and 2nd run.
- Communication style: types fast on mobile, often with typos and dropped punctuation. Doesn't mind directness. Asks for "Do X" style answers, not lectures. Prefers I think for him and propose, not ask 10 questions.
- **Mom Nathalie Barbier** is the legal sole proprietor (Florida sole prop) because Noah is a minor. Stripe is registered in her name. Her email is the contact email on receipts.

---

## 2. What Stryxs is

**stryxs.com** — AI-powered endurance training app. $14.99/month subscription via Stripe live.

- **Target user:** endurance athletes (triathletes, marathoners, half-marathoners, short-distance runners, general fitness folks).
- **Core value prop:** an AI Coach that knows real endurance methodology (Friel, Daniels, Pfitzinger, Canova, Sutton, Seiler, Attia) and personalizes plans + answers questions in the user's chosen methodology's voice.
- **Tagline territory:** "AI coaching that actually knows how endurance athletes train."

### Personas

Coach uses 7 distinct "methodology personas" depending on the user's goal_event:

| persona_key | Methodology brain | Goal events |
|---|---|---|
| `ironman` | Joe Friel (Triathlete's Training Bible) | Ironman |
| `ironman_70_3` | Joe Friel + Brett Sutton | 70.3 / Half-Ironman |
| `short_tri` | Friel + multisport general | Sprint/Olympic tri |
| `marathon` | Pfitzinger + Daniels | Marathon |
| `half_marathon` | Daniels + Pfitzinger | Half marathon |
| `short_run` | Daniels VDOT | 5K, 10K, mile |
| `general` | Peter Attia + Seiler | Fitness & Health (no race) |

Picked via `pickPersona(goal_event)` in Coach. Each persona has its own intensity targets, pattern rules, methodology summary, plan principles, auxiliary work, voice.

---

## 3. Stack & architecture

### Frontend
- **Single `index.html` file** (~890 KB, ~19,700 lines). Yes really. One file, vanilla JS, Tailwind-ish utility CSS. No React, no build step.
- Deploys via **GitHub → Vercel auto-deploy**. Noah uploads `index.html` through the GitHub web UI to repo `noahb-developer/stryxs`. Vercel watches that repo.
- **Service worker:** `/sw.js` at repo root for push notifications.

### Backend
- **Supabase** project ID: `jubbxlnrwzgixbqlhjdd`
- Edge function base URL: `https://jubbxlnrwzgixbqlhjdd.supabase.co/functions/v1/{name}`
- Edge functions live in local repo: `C:\Users\noahb\enduraiq-functions\supabase\functions\{name}\index.ts`
- Edge functions are **TypeScript on Deno** runtime (supabase-edge-runtime).

### Active edge functions
- **`coach`** — main AI Coach (currently v8, 151,983 bytes). Has 17 actions: `generate_plan`, `generate_skeleton`, `assess_feasibility`, `review_imported_plan`, `workout_commentary`, `chat`, `import_plan`, `analyze_patterns`, `race_projections`, `plan_intro_message`, `apply_chat_correction`, `apply_insight`, `explain_insight`, `check_anomalies`, `apply_import_adjustments`, `build_profile_recap_message`, `generate_race_plan`, `get_persona`, `get_my_usage`, `export_my_data`.
- **`send-reminders`** — hourly cron. Sends Web Push to users whose local hour matches their reminder time.
- **`send-followups`** — daily 14:00 UTC cron. Lifecycle nudge emails via Resend.
- **`stripe`** (if asked) — payment & subscription webhook handler.
- **`strava`** (if asked) — Strava OAuth + workout sync.
- **`account`** (if asked) — account deletion (cascades through Stripe/Strava/storage/12 DB tables/auth).

### Integrations
- **Strava** — auto-sync workouts.
- **Stripe** — live mode billing, $14.99/mo (mom's account).
- **Resend** — domain `stryxs.com` verified. `FROM_EMAIL = "Stryxs <coach@stryxs.com>"`. API key stored in Supabase Edge Function secrets as `RESEND_API_KEY`.
- **Web Push** — VAPID configured. Public key in frontend, private key in `send-reminders` env vars.
- **Anthropic Claude API** — Coach uses prompt caching. Models:
  - `MODEL_FAST = "claude-haiku-4-5-20251001"`
  - `MODEL_SMART = "claude-sonnet-4-5-20250929"`

### Database tables (all in `public` schema)
- `profiles` — name, run_lthr, bike_lthr, subscription_tier, trial_ends_at, pro_until, **notif_workout_reminder, notif_workout_reminder_time, notif_timezone** (notif columns from migrate_v3)
- `athlete_intake` — full intake answers (goal_event, race_date, current_weekly_hours, available_days, equipment, experience_level, race_experience, injuries, age, sex, weight_kg, PBs, preferred_long_day, goal_time, lthr_choice, plan_path, completed, insights_last_generated_at)
- `workouts` — synced/imported workout data, `id` is **uuid**, `workout_data` is jsonb
- `planned_workouts` — `id` is **uuid**. Columns include `scheduled_date`, `sport`, `workout_type`, `duration_minutes`, `distance_km`, `description`, `intensity_target`, `completed`, **`skipped`, `skip_reason`, `skipped_at`** (skip cols from migrate_v2)
- `training_plans` — generated plans, `plan_data` jsonb
- `coach_messages` — chat history with Coach
- `training_insights` — pattern detection results. Columns: `pattern_type`, `severity` (urgent/actionable/info), `category`, `title`, `finding`, `recommendation`, `data_points` (jsonb), `status` (active/stale/dismissed)
- `race_plans` — race-day execution plans
- **`workout_feedback`** — exists from migrate_v2 but UNUSED (no UI captures it yet). Has `rpe`, `notes`, `felt_easy/hard/strong/flat/sore/sick` flags. Coach doesn't read it.
- **`api_usage`** — per-call AI cost tracking. Has `user_id`, `call_type`, `model`, `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`, `cost_usd`, `error`, `created_at`
- **`user_events`** — first-party analytics. Has `event_name`, `properties` jsonb, `utm_source/medium/campaign`, `user_agent`, `anon_session_id`. View: `user_events_funnel_30d`
- **`push_subscriptions`** — Web Push endpoints per device. `endpoint`, `p256dh`, `auth`, `user_agent`, `last_seen_at`. Unique (user_id, endpoint).
- **`feedback`** — beta feedback widget submissions. `rating` 1-5, `message`, `page`, `app_version`

### Usage limits (per user per month)
- Hard $5/month cost cap (returns 429 `USAGE_LIMIT_EXCEEDED`)
- 80 daily calls
- 300 chats/month
- 15 plan_gen/month
- 150 workout_commentary/month
- Frontend shows friendly modal via `showUsageLimitModal()` when hit.

### Cron jobs (Supabase Studio → Integrations → Cron, uses `pg_net`)
- **`send-workout-reminders`** — `0 * * * *` (hourly on the :00) → POST to `send-reminders`. Type: Supabase Edge Function.
- **`daily-lifecycle-emails`** — `0 14 * * *` (daily 14:00 UTC) → POST to `send-followups`. Type: Supabase Edge Function.

---

## 4. Deploy commands (CRITICAL — Noah uses these exactly)

### Frontend
Just upload `index.html` to GitHub via browser → Vercel auto-deploys in ~30 seconds.

### Edge function (substitute `<NAME>` with `coach`, `send-reminders`, `send-followups`, etc.)
```powershell
Copy-Item "C:\Users\noahb\Downloads\index.ts" "C:\Users\noahb\enduraiq-functions\supabase\functions\<NAME>\index.ts" -Force
cd C:\Users\noahb\enduraiq-functions
supabase functions deploy <NAME> --no-verify-jwt
```

**Gotcha**: when Noah downloads a file from chat that's already in his Downloads, it lands as `<NAME> (1).ts` or `<NAME> (2).ts`. Quote the path including parens:
```powershell
Copy-Item "C:\Users\noahb\Downloads\send-followups (1).ts" "..." -Force
```

If new edge function (folder doesn't exist):
```powershell
New-Item -ItemType Directory -Path "C:\Users\noahb\enduraiq-functions\supabase\functions\<NAME>" -Force
```

### Test trigger an edge function manually
```powershell
$serviceKey = "YOUR-SERVICE-ROLE-KEY"
Invoke-RestMethod -Uri "https://jubbxlnrwzgixbqlhjdd.supabase.co/functions/v1/<NAME>" -Method POST -Headers @{ Authorization = "Bearer $serviceKey" }
```
Service role key lives in Supabase Studio → Project Settings (gear icon) → API → "service_role".

### Migrations
SQL editor in Supabase Studio. Paste full file. Migrations applied so far: v1 (legacy), v2_fix, v3, v4. All idempotent (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`).

---

## 5. Important shared facts / hard-won learnings

### Operational gotchas
- **`state` is `let`, not `var`.** Don't use `window.state` — it's `undefined`. Use `state` directly (lexical scope). This bug burned ~3 rounds before being caught.
- **VAPID public key MUST always be in `index.html`.** It's in memory. Never ship `index.html` with empty `VAPID_PUBLIC_KEY`. Value: `BN00taH8qcUtNaGwakhKEC51maJg5t76qC5ijtc4W8QxSo98-QYEThaSd7H3eiETHzF_XESWOLik0DTJbX47GaU`
- **`workouts.id` and `planned_workouts.id` are `uuid`, not `bigint`.** Foreign keys must match.
- **Supabase `.rpc(...)` does NOT support `.catch()`** until awaited. PostgrestBuilder. Use plain `try/catch`.
- **Supabase `.update()` returns `error: null` even when 0 rows matched.** Use `.update().select()` to verify the write landed.
- **`auth.users` is not directly queryable via `from()`.** Use `sb.auth.admin.listUsers()` for service-role admin access.
- **iOS web push only works when PWA is installed to home screen.** Regular Safari = nothing. Code detects this in `getPushPermissionState()` and returns `'ios-not-installed'`.
- **Browser caches `index.html` aggressively.** Hard refresh (Ctrl+Shift+R) often needed after deploys. PWAs especially.
- **PowerShell variables disappear when you close the window.** Tell Noah to set `$serviceKey` first if using a new window.
- **`pg_net` extension must be installed** in Supabase before cron jobs of type HTTP/Edge Function work.

### Voice / writing rules
- Coach's voice depends on persona (each has its own `voice` field).
- App copy: friendly but direct. No exclamation overload. No marketing fluff. "Here's why" beats "Awesome!". Avoid em-dashes — use commas and periods.
- **NEVER use em-dashes (—)** in user-facing copy or Coach output. Noah catches them. Comma + period works.
- Reality-check rules: Coach must tell the truth even if it disappoints. Never validate impossible setups.

### Files arrive with `(1)`, `(2)` suffixes
Whenever Noah re-downloads a file from chat, it lands in Downloads as `name (1).ts`, `name (2).ts`, etc. Always tell him to either:
- Check what's actually there: `Get-ChildItem C:\Users\noahb\Downloads\NAME*.ts | Select Name, Length`
- Or just use the newest one with quoted path including parens

### Tooling style
- Noah is on **Windows + PowerShell + GitHub web UI + Supabase Studio web UI**. No Docker running. No supabase CLI from terminal except for `functions deploy`. He can run `supabase functions deploy <name> --no-verify-jwt` from inside `C:\Users\noahb\enduraiq-functions`.
- Use **forward-slashes or PowerShell-quoted paths** in instructions.
- Don't suggest CLI tools he doesn't have. Don't tell him to "git commit and push" — he uses the web UI for that.

---

## 6. Current state — what's deployed RIGHT NOW

### Versions
- **Frontend:** `index.html` v37 — 924,069 bytes (post round-3 audit; live in repo `noahb-developer/stryxs` as `index.html`)
- **Coach:** `coach_v8.ts` — 151,983 bytes
- **send-reminders:** 8,433 bytes, deployed, working
- **send-followups:** 18,677 bytes, deployed, working (returned `success: True` on test fire)
- **site.webmanifest:** 576 bytes (was 456 — fixed name from "MyWebSite" to "Stryxs", added start_url/scope/id)
- **sw.js:** 2,859 bytes (was 2,827 — fixed icon paths)
- **vercel.json:** 427 bytes (added SPA catch-all rewrite)
- **README.md:** 230 bytes (was 14 — actually says Stryxs now)
- **privacy.html:** 15,620 bytes (em-dash sweep)
- **terms.html:** 17,551 bytes (em-dash sweep)

### Crons live
- `send-workout-reminders` — hourly, sends Web Push when user's local hour matches their reminder time
- `daily-lifecycle-emails` — daily 14:00 UTC, sends nudge emails for 4 stuck-user buckets

### What's working end-to-end (verified)
- ✅ Push notifications (Noah confirmed buzz on his tablet)
- ✅ Lifecycle email function (test fire returned True with empty buckets = nobody currently stuck)
- ✅ Feedback widget (floating 💬 button, modal, saves to `feedback` table)
- ✅ Analytics events flowing to `user_events`
- ✅ Coach knows current date via clientToday from frontend (timezone-correct)
- ✅ Coach sees: injuries, age, sex, weight, equipment, experience, available_days, plan presence, 30-day trend summary, last 7 detailed workouts, next 7 planned with skipped flags
- ✅ Trends/insights now works (was completely broken — fixed in v8: returns `{patterns: [array]}`)
- ✅ Settings sync detects `available_days`, PBs, goal_time, `lthr_choice` (was broken — fixed in v36)
- ✅ Coach refuses impossible setups via `assessFeasibility` (race < minimum-weeks, too few days, absurd goals)
- ✅ Coach has explicit REALITY-CHECK RULES in system prompt
- ✅ Frontend shows feasibility warnings modal after plan generation
- ✅ Equipment adaptation in Coach (gym/pool/bike/trainer/treadmill rules)
- ✅ Skip/sick/injured/swap workout flow with multi-day batch
- ✅ Data export (Settings → Privacy & data → Download my data → JSON file)
- ✅ Friendly 429 USAGE_LIMIT_EXCEEDED modal
- ✅ Global error capture in user_events (js_error, promise_rejection)
- ✅ UTC→local dates everywhere (8 sites use `getClientToday()`)
- ✅ Per-user AI usage tracking + monthly limits

### Server-side hard guarantees
- **Blocked days become rest** — even if Coach LLM puts a workout on a blocked day, the server rewrites it to rest. Bulletproof. Lives in `generatePlan()` post-processing.
- **Usage limits enforced server-side** in Coach edge function before any Anthropic call.

---

## 7. Recently-deferred work (queue for next sessions)

### Item 6 from the May 2026 scan: `workout_feedback` UI
The table exists with RPE + felt_* flags but no UI captures it. Coach doesn't read it. Adding this gives Coach a subjective-effort signal (separate from HR/pace data) and unlocks better adjustments. ~30 min build:
1. Quick post-workout "How did that feel?" modal (RPE 1-10 + 1-tap chips: easy/hard/strong/flat/sore/sick)
2. Save to `workout_feedback` table
3. Add `feedback` data to Coach's chat context block (last 10-14 entries)
4. Update `workoutCommentary` to read it

### Streak celebrations
Deferred until Noah has 10+ active users with streaks of 5+ days. Pointless without users. Easy 20-min build at that point: animated streak counter on dashboard, "🔥 N day streak" badge, modal at every multiple of 5.

### Verify email branding
Noah said "I'm not sure" whether the signup verify email goes through Resend or Supabase's default. Not blocking launch. To check: Supabase Studio → Authentication → Emails → SMTP settings. If it says `smtp.resend.com` it's already on Resend. Otherwise it's using Supabase built-in (still works, just less branded).

### Marketing
The 2026-05-09 session ended mid-conversation about Instagram strategy with web search results loaded but no plan delivered. Reddit + IG was floated. Instagram brand account got banned. **Noah uses Linktree.** Marketing remains an open thread but isn't currently a build item.

### Known minor bugs (low priority)
- Frontend may still have minor edge cases where a workout filter uses UTC. Most were fixed in v36 but worth re-testing in beta.
- iOS Safari backdrop-filter compositing glitches in the onboarding tour (from May 9-10 sessions). Tour iterated v22→v26 but some repaint bugs may linger.

---

## 8. Common task patterns

### "Coach said X wrong"
1. Check the **system prompt** in `buildSystemPrompt()` — is the rule clear?
2. Check the **chat context block** in `chat()` — does Coach see the relevant data?
3. Check if it's a **persona-specific issue** — open `PERSONAS[<key>]` and look at `voice`, `intensity_targets`, `plan_principles`, `auxiliary_work`.
4. If it's a JSON-shape mismatch (like the trends bug), grep the frontend for what it expects vs what backend returns.

### "User can't do X in the app"
1. Search for the feature in `index_v36.html`. Most actions are in functions like `openX()`, `submitX()`, `renderX()`.
2. Check if the action calls Coach — if so, verify the edge function has a matching case in the dispatcher (look for `else if (action === "..."`).
3. Check **RLS policies** on the relevant table. Common breakage: INSERT/UPDATE policy missing.
4. Check `state.user` — many flows fail silently if the user isn't loaded.

### "Add a new edge function action"
1. Add the function (e.g. `async function newThing(...)`) in `coach_v8.ts`.
2. Add to the dispatcher: `else if (action === "new_thing") result = await newThing(...)`.
3. If it makes an Anthropic call, add to `ACTION_CALL_TYPE` map with a string key for usage tracking.
4. If it's a no-cost read action, leave it out of `ACTION_CALL_TYPE`.
5. Deploy via PowerShell command above.
6. Call from frontend: `await callCoach('new_thing', { ... })`.

### "Add a tracked event for analytics"
Just call `trackEvent('event_name', { property: value })` anywhere in the frontend. Writes to `user_events` automatically. Use snake_case event names. Add to the funnel query in `analytics_queries.sql` if it should be a funnel step.

### "Run a manual data query"
Supabase Studio → SQL Editor. Service role auth, no RLS. Common queries are in `analytics_queries.sql` (which Noah has).

---

## 9. Validation checklist before shipping any change

Before saying "ship it", verify:

```bash
# Frontend JS syntax
node -e "const fs=require('fs');const c=fs.readFileSync('PATH','utf-8');[...c.matchAll(/<script>([\s\S]*?)<\/script>/g)].forEach((m,i)=>{if(m[1].length<1000)return;try{new Function(m[1])}catch(e){console.log('Block',i,':',e.message)}})"

# Edge function syntax (TypeScript)
tsc --noEmit --target es2022 --module esnext --moduleResolution node --skipLibCheck PATH

# VAPID key still baked in
grep "const VAPID_PUBLIC_KEY = 'BN" index_vXX.html

# No window.state lurking (would fail silently)
grep "window\.state" index_vXX.html

# File sizes match expectations (write the new size in the response so user can verify after deploy)
wc -c PATH
```

If any of those fail, fix before shipping.

---

## 10. What we just did (so context lives across sessions)

**End of 2026-05-15 session (Round 3 — full audit + fix pass):** Ran 3 parallel scan agents, then fixed everything fixable in the frontend. Frontend bumped to v37 (924,069 bytes). Noah needs to commit + push `index.html`, `sw.js`, `site.webmanifest`, `vercel.json`, `README.md`, `privacy.html`, `terms.html`. After deploy, hit hard refresh.

### What got fixed in v37

**Critical bugs:**
- `coach_insights` table queries (4 sites) were silently 404ing — table never existed, only `training_insights` does. Neutered `renderCoachInsights`/`applyInsight`/`dismissInsight` to no-ops; the active path is `renderInsightsMiniCard` against `training_insights`.
- Chat history was selecting OLDEST 20 messages (`ascending: true, limit 20`) instead of newest. After 20 messages every Coach reply ran on stale ancient context with the user's current message dropped. Now `ascending: false, limit 20` then reversed.
- `loadProfile()` silently swallowed missing-row errors via `.single()`. Now uses `.maybeSingle()`, attempts a self-heal insert, surfaces a toast + analytics event if profile is broken. Stops paying users from being silently locked out of Pro.
- `sendChatMsg()` insert lived BEFORE the try/catch — RLS or network blip left input permanently disabled. Now wrapped, restores input + value + toasts on failure.
- 6 UTC-vs-local date bugs: added `toLocalYMD`, `localDayStartISO`, `localDayEndISO` helpers next to `getClientToday`. Fixed `renderDashTodayCard` query, `renderDashWeekStrip` (dateStr + workouts query + bucket-by-local-day), streak calc (`trainingDays`/`adherenceDays` Set), `markRangeSkipped`, starter-week generators (LTHR-untested + LTHR-known branches).

**Security / auth:**
- `callStripe` and `callStrava` were sending only the public anon key + `user_id` in body, no JWT. Now both pull `sb.auth.getSession()` and forward `Bearer ${access_token}` plus `apikey`. **The Stripe and Strava edge functions still need to verify identity from the JWT (not trust body.user_id).** This is on Noah — see manual list.

**UX / billing:**
- Stripe activation poll extended from 8s linear → ~30s with backoff + a 30-iteration background re-check that toasts when activation lands. Final fallback message tells user to email support@stryxs.com.
- Stripe error messages: 5xx with empty body used to surface as "Stripe undefined failed: 500"; now includes status code + best-effort body/text.
- Push unsubscribe (`disablePushNotifications`) used to swallow all errors. Now flips profile flag FIRST (so cron stops pushing even if browser-side fails), then attempts cleanup with per-step diagnostics in the analytics event.
- Strava OAuth callback router used to fire on ANY URL with `?code=&state=` — broke any future OAuth integration. Now requires `path === '/strava-callback'` AND both params.
- Path-based routing added: `/upgrade`, `/coach`, `/plan`, `/history`, `/trends`, `/race`, `/settings`, `/import` now navigate to the right SPA page on first load (was hard-coded to dashboard). Means deep links from terms.html, marketing emails, etc. work.
- `vercel.json` got a SPA catch-all rewrite `/((?!.*\\.|api/).*)` so non-asset paths land on index.html.

**Cosmetic / launch readiness:**
- `<head>` now has `og:title/description/image/url/type/site_name`, `twitter:card/title/description/image`, `link rel=canonical`, `meta robots`. og:image points at `web-app-manifest-512x512.png` as a placeholder; **Noah needs to make a real 1200x630 social preview PNG**.
- Removed `maximum-scale=1.0, user-scalable=no` from viewport (accessibility regression).
- `<title>` no longer has em-dash.
- `site.webmanifest`: rewrote with name "Stryxs", short_name "Stryxs", start_url/scope/id, theme_color matching `#0a0e1a`.
- `sw.js`: icon path now `/web-app-manifest-192x192.png` (was broken `/icon-192.png`).
- `README.md`: rewrote with real description.
- ~500 em-dashes purged via `' — '` → `, ` global replace + sentinel double-space cleanup. Privacy.html and terms.html also swept. ~16 em-dashes remain (typographic placeholders for empty values like `—min`/`—km`/`—`, plus end-of-line code comment ellipses — all developer-facing or visual stand-ins).
- `app_version` bumped from `'v35'` → `'v37'` in feedback widget.
- `crypto.randomUUID()` used for `anon_session_id` when available (Math.random fallback retained).
- One console.log that exposed user_id removed (`savePlanToDb`).

### Round 3 scan also flagged (NOT yet fixed — see section 7 + manual list)
- **Stripe/Strava edge function code** must be updated to validate identity from JWT (frontend now sends it, but the backend has to enforce). Until then any anon-key holder could spoof any user_id.
- **`shared_plans` table** referenced at lines ~15357/15466/15486/15536 but not in memory's table inventory. Either confirm exists in DB or this share-plan flow is broken.
- **Schema drift to verify in Supabase Studio:** `training_insights.generated_at`, `training_insights.applied_at`, `planned_workouts.workout_notes`, `workouts.sport/source/activity_classification`, `coach_messages.context_type`, several `athlete_intake` columns (has_pool_access, has_bike_trainer, unit_preference, pb_5k/10k/half/marathon, last_race, height_cm, available_days_count), `profiles.avatar_url/bio/display_name/stripe_customer_id/stripe_subscription_id`, RPC `expire_old_trials_for_user`. All used by frontend, none documented in memory's section 3 schema.
- **Coach actions `assess_feasibility` and `get_my_usage`** are documented in section 3 but never called from frontend. Either dead backend or unbuilt UI.
- **Verify `support@stryxs.com`** actually receives mail — Resend is configured outbound only.
- **Verify signup confirmation email** is on Resend not Supabase default `noreply@mail.app.supabase.io` (Supabase Studio → Auth → Emails).
- **iOS backdrop-filter onboarding tour glitches** still untested on device.

### What previous round (v36 / Coach v8) fixed (kept here for completeness)
**End of May 12 2026 session:** Ran full scan emphasizing Coach personalization and realism. Found 5 issues:

1. **Trends completely broken** (CRITICAL) — `analyzePatterns` backend returned flat single-pattern object `{needs_adjustment, severity, title, ...}`, frontend expected `{patterns: [array]}`. No insights had ever been saved. **FIXED in coach_v8.**
2. **Settings sync gaps** (HIGH) — `detectImportantSettingsChanges` missed `available_days`, `preferred_long_day`, `goal_time`, all PBs, `last_race`, `lthr_choice`. Plans would stay on old days if user changed availability. **FIXED in index_v36.**
3. **Impossible timelines accepted** (HIGH) — `Math.max(8, weeksToRace)` normalized 2-week prep windows to 8 weeks, pretending there was enough time. Coach would happily build "Ironman in 4 weeks for a beginner." **FIXED via new `assessFeasibility` function.**
4. **No "reality check" instruction in Coach** (MEDIUM) — vague "be honest" line, nothing forcing Coach to push back. **FIXED via explicit REALITY-CHECK RULES block in system prompt.**
5. **Frontend didn't surface backend feasibility flags** (MEDIUM) — even if backend wanted to warn, no UI for it. **FIXED via `showFeasibilityWarningsModal`.**

Noah said "not gonna test, beta users will test." Deployed Coach v8 + Frontend v36. Then he asked for this memory file.

---

## 11. How to start a fresh chat efficiently

Open a new conversation. First message: drop this file into the project's knowledge or paste the link. Then say something like:

> "Picking up Stryxs. Read memory.md. <topic>."

I'll have everything I need. If something's changed since this memory was written, you can mention it inline:

> "Picking up Stryxs. Read memory.md. Coach is now at v9 (added X). Need to fix Y."

If you ship a change between sessions and don't want to update the memory, just tell me at the start. Memory is a baseline, not a contract.

---

## 12. Hard rules I (Claude) should follow

1. **Always include the VAPID public key in any `index.html` I ship.** Never strip it.
2. **Never use em-dashes** in user-facing copy or Coach output.
3. **Don't introduce build steps.** Vanilla JS, single file. No React/Vue/build pipelines.
4. **Don't suggest CLI tools Noah doesn't use.** He's on PowerShell + GitHub web + Supabase Studio.
5. **Tell him the file size after every change** so he can verify the deploy lands the right bytes.
6. **Validate JS/TS syntax before shipping.** Always. Caught many bugs this way.
7. **Match what the frontend expects** — if changing a backend return shape, grep the frontend for consumers.
8. **Idempotent SQL only.** All migrations use `IF NOT EXISTS` and `DROP POLICY IF EXISTS`.
9. **When in doubt, ask one targeted question, not five.** Noah prefers I propose.
10. **No long preambles or postambles.** He doesn't need a wrap-up that re-explains what we just did.

---

## 13. Anti-patterns I've fallen into and should NOT repeat

- **Shipping `index.html` with empty VAPID key** (twice). Now in memory.
- **Using `.rpc(...).catch()` on Supabase** (PostgrestBuilder doesn't support .catch). Caught after a 500 in send-followups.
- **Using `window.state` instead of `state`** (let-declared, not on window). Caused the notifications toggle to never read DB state.
- **Asking too many clarifying questions** when I should propose.
- **Long marketing-style summaries at the end of responses** when Noah just wants to deploy.
- **Forgetting to update file sizes** when telling him deploy commands. He uses them to verify.

---

## 14. Persona quick reference (for Coach work)

When the user asks Coach to do something, the persona is picked from `goal_event`. To check what voice/methodology Coach uses for a specific goal:

```typescript
// In coach_v8.ts
const personaKey = pickPersona(intake.goal_event);
const persona = PERSONAS[personaKey];
// → persona.coach_brain, persona.voice, persona.methodology_summary, etc.
```

Common persona keys: `ironman`, `ironman_70_3`, `short_tri`, `marathon`, `half_marathon`, `short_run`, `general`.

---

## 15. The full file inventory in `/home/claude` (if needed)

Active versions:
- `coach_v8.ts` (151,983 bytes) — current Coach
- `index_v36.html` (896,707 bytes) — current frontend
- `send-reminders.ts` (8,433 bytes) — push reminders cron
- `send-followups.ts` (18,677 bytes) — lifecycle emails cron
- `migrate_v2_fix.sql` — skipped workouts + workout_feedback (uuid fk) + user_events tables
- `migrate_v3.sql` — push_subscriptions + notification preference cols + RPC
- `migrate_v4.sql` — feedback table
- `analytics_queries.sql` — 10 funnel queries
- `sw.js` — service worker

Older `coach_vN.ts` and `index_vN.html` versions exist as history but aren't deployed.

---

**End of memory.md. If you read this far, you have full context. Get going.**
