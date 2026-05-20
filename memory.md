# Stryxs — Project Memory

> **Read this first in every fresh chat. It captures everything you need to be productive immediately.**
>
> **Round 10e (v70, 2026-05-20):** Chat composer redesigned to one Claude-style rounded pill that grows with the text — circular `+` on the left opens the device's NATIVE photo/file picker (custom drop-up removed; `coachPickAttachment()` just clicks the hidden `#coachFileInput accept="image/*"`), round up-arrow send (`.composer-send`, accent) appears only when there's text/attachment (`updateCoachSendState` toggles `disabled`→`display:none`). CSS class `.coach-composer` / `.composer-plus` / `.composer-input` / `.composer-send`. **Top bar pinned during chat** (`body.coach-chat-active .nav{position:fixed;top:0;padding-top:calc(12px+safe-top)}`) so it can't slide off-screen on iOS drag; chat page top uses JS-measured `--coach-nav-h` (`measureCoachNav()` on rAF + resize + orientationchange) so it's flush below the notch/Dynamic Island/Samsung hole on any device; added `overscroll-behavior:none`. Dashboard "This week" strip: skipped days now amber with a "Skipped" legend (loads `skipped` from planned_workouts), not red "Missed". **#Late-sync is already correct (verified):** strava edge sets `workouts.created_at = activity.start_date_local` (NOT sync time), and streaks/this-week/adherence all bucket by created_at, so a workout done Mon but synced Tue lands on Mon and recomputes on next load — no re-upload, Coach analyzes on sync.
>
> 🔜 **EQUIPMENT RESTRUCTURE — NEXT FOCUSED PASS (Noah asked, deferred for care):** Simplify equipment options (intake question `id:'equipment'` ~line 13351 + Settings ~line 20379). Remove **treadmill, indoor trainer, TT bike**; collapse bike to ONE "Bike / cycling setup" option; keep Pool + Open water (+ Gym); ADD a "Running gear" option. Coach should handle trainer/treadmill conversationally ("raining so I'll use my trainer"). **CARE NEEDED:** (1) migrate existing users' stored values — a Settings 'bike' toggle must read as selected if equipment includes legacy road_bike/tt_bike/trainer, and 'run_gear' if it includes treadmill; normalize on load + save. (2) `has_bike_trainer` column write (settings save line ~21664 + intake save line ~14294 `equipment.includes('trainer')`) needs rethinking — decide whether Coach should still assume a trainer. (3) Review the `coach` edge function's equipment-adaptation rules (gym/pool/bike/trainer/treadmill) so removed values don't leave dead logic; may need a coach edge deploy. Keep the per-sport adaptive filtering (isTri/runOnly/general by fh_primary_sports).
>
> Last updated: 2026-05-20 (round 10c + 10d). **Frontend v69.** Round 10c (v68): branded "Stryxs" boot splash (replaces the bare spinner; in-app spinner kept); Coach composer got a "+" attach menu (Photo/File, UI-only) + removable chips + a Send button that's grey until there's text/attachment then green; top nav shows the wordmark ONLY (logo icon removed) at a larger size; skip/didn't-do modal centers on desktop instead of running off the bottom; streak no longer breaks on excused (sick/injured) skips (they bridge the current training + adherence streaks); **FRENCH LEAK FIXED** — loadProfile was re-applying a stored profile.locale='fr' even though the language UI is disabled, so callCoach sent userLocale='fr' and Coach replied in French + generated French plans. Now gated behind !LANG_UI_DISABLED and the stale 'fr' is self-healed to 'en'. Round 10d (v69): proactive Coach plan-change awareness — skips/moves logged locally, and a repeated pattern across ≥3 weeks (e.g. Sat run→Mon) triggers ONE proactive Coach message offering to make it permanent (Yes routes through normal chat; deduped). Round 10b (v67) = full-screen Claude-style Coach chat. **Strava confirmed they'll respond to the quota increase request soon (awaiting).**
>
> ⚠️ **EXISTING FRENCH PLAN DESCRIPTIONS:** the locale fix makes Coach + NEW plans English, but planned_workouts generated while Coach was French still have French `description` text stored in the DB. Those only become English if the user regenerates the plan (Plan tab → Plan Management → Generate new plan). Can't auto-translate stored text without an LLM call. Tell Noah this if he still sees French workout details.
>
> 🔜 **COACH PHOTO/FILE VISION is the deferred next step:** the "+" menu attaches photos/files in the UI and the Send button responds, but on send we clear the attachment with a "coming soon" toast — Coach can't actually READ images yet. To make it real: add image content-block support to the `coach` edge function (Claude vision) + send base64 from the frontend. Noah chose UI-first this round.
>
> ⚠️ **LESSON (2026-05-19): the local clone was 13 commits / 11 versions BEHIND origin/main at session start (local v55, origin v66).** memory.md and index.html were both stale. Edits made against the stale file would have wiped rounds 8-10 if pushed. **ALWAYS `git fetch && git status` at the start of a session and reconcile before editing.** Noah deploys via git push → Vercel, AND sometimes via GitHub web UI, so origin can be ahead of local. Recovered by stashing the stale-base edits (stash + patch at C:/Users/noahb/stryxs_v55_coach_edits.patch), fast-forwarding to v66, and re-applying.
>
> **🔜 NEXT BIG TASK (round 10, started): MOBILE-FIRST REDESIGN.** Noah says the app looks good on PC/tablet but is "squished / overlapping / restricted on the sides" on phones. He wants a modern, clean, Apple-like feel — benchmark competitor is **RestOrTrain** (clean card-based layout, generous spacing, big touch targets). Keep Stryxs colors + brand + dark theme, just make the mobile layout breathe. This is a large multi-pass job — likely needs its own fresh session. Also: hide the floating feedback/rate widget during the onboarding tour (it overlaps). See round 10 section below.

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
- `workouts` — synced/imported workout data, `id` is **uuid**, `workout_data` is jsonb. As of 2026-05-17, Strava-sourced rows newly created can also carry `polyline`, `description`, `perceived_exertion`, `suffer_score`, `gear_name`, `gear_id`, `sport_type`, `splits` (per-km), `avgPower`, `maxPower`, `normalizedPower`, `avgWatts`, `avgTemp`, `total_photo_count`. Historical rows synced before 2026-05-17 don't have these fields yet (backfill action pending).
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
- **Frontend:** `index.html` v65 — ~1,054,000 bytes. Round 8 added the interactive chart toolkit + map toggle + auto-refresh + workout meta chips (calories/kilojoules/max-speed/max-cadence/PR/indoor). Round 9 fixed all the bugs: TDZ chart crash, history wrong-workout (now _dbId-based via `_resolveWorkoutRef`), classification race (backend re-reads before write), intensity dropdown (position:fixed), sync-now stuck button, swim per-lap table + chart, chart X/Y axis labels with bare-tick formatter to avoid overlap, history display caps (30 Pro / 5 free) with honest count text. KNOWN: history subtitle data-i18n still overrides the static text (round 10 todo).
- **Service worker:** `sw.js` v4 — unchanged from round 7.
- **Coach edge function:** ~167,563 bytes. Round 8 added: chat()'s "Recent (last 7 completed)" context line now includes cadence, power, NP, calories, elevation, RPE, suffer score, indoor flag, PR count, splits range (fastest/slowest km), gear name, description excerpt. `workoutCommentary` calls compactWorkoutForCoach() to strip the heavy per-second series arrays and replace with avg/min/max summary lines — saves 600-1200 tokens per call without losing reasoning value.
- **send-reminders:** 8,433 bytes, unchanged.
- **send-followups:** 26,676 bytes, unchanged.
- **strava edge function:** ~64,392 bytes. Round 8 added: captures kilojoules, max_speed, max_cadence, max_watts, pr_count, achievement_count, trainer/commute/manual_in_strava flags, device_name, workout_type_strava, timezone. NEW `attachStreamData()` helper runs HR-INDEPENDENT enrichment (series, maxes, splits) unconditionally — so workouts without HR still get the rich pace/cadence/elevation view. NEW `synthesizeSplitsFromStreams()` builds per-km splits from distance+time+HR+cadence+altitude streams when Strava doesn't return splits_metric. Each split now includes `distanceM` so bike speed-per-split is computed as (distanceM/elapsedSec)*3.6 instead of assuming 1km (which gave a false 63 km/h on partial last splits).
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

### 🔜 ROUND 10 — MOBILE-FIRST REDESIGN (the current big task)

Noah's verdict after using the app on his phone: PC/tablet looks good, but **mobile is cramped — things overlap, go off-screen, are mis-sized relative to neighbors, and feel restricted on the sides.** He wants a modern, clean, Apple-like redesign. Benchmark: **RestOrTrain** app (clean white card stack, generous padding, big legible type, clear touch targets, calendar-style plan view). Keep Stryxs's dark theme + accent green (#00e5a0) + Instrument Serif wordmark — just make the mobile layout breathe and look premium.

**Approach (multi-pass, probably needs a fresh session for the deep work):**
1. **Global shell**: audit `body` / app-container / `.page` horizontal padding on mobile. Noah says it feels "restricted on the sides" — likely too much or inconsistent side padding, or fixed-width elements overflowing. Establish a consistent mobile gutter (~16px) and max-width.
2. **Cards (`.panel`, `.analysis-card`, stat cards)**: consistent radius, padding, spacing. On mobile they should stack full-width with breathing room, not squish side-by-side.
3. **Grids that don't stack**: find every `display: grid`/`flex` row that keeps 2-3 columns on mobile and make them stack or scale. The Trends cards (Training Mix / Cardiac Drift / Intensity) and dashboard stat rows are suspects.
4. **Typography scale**: set up a mobile type ramp so headings aren't oversized next to body text. Noah specifically called out "too big compared to things right next to it".
5. **Touch targets**: buttons/chips ≥ 44px tap height on mobile.
6. **Charts**: already responsive (viewBox), but verify the new axis gutters don't crowd on narrow screens.
7. **Onboarding tour + feedback widget**: the floating 💬 feedback/rate button overlaps the welcome tour. Hide it during the tour and for ~1-2 days after signup (then let it appear).

**Files**: all in `index.html` (single file). Most of the work is in the `<style>` block (CSS) + some structural HTML. No build step — test by hard-refresh. Validate JS after any script touch.

**Mindset Noah asked for**: "adopt the mind of the best app developer in the world, reimagine the app to today's standards." He's OK with big changes / temporary breakage if the end result is materially better on mobile. Original brand + colors stay.

#### ✅ Round 10a DONE (frontend v66, pushed):
- **Mobile gutter fix (the big "restricted on the sides" win):** `.container` had 20px (14px mobile) side padding AND every in-app `.page` (#page-dashboard/coach/plan/upload/history/settings/race-planner) added ANOTHER 20px/14px → double padding squeezed content into a narrow column. Removed per-page horizontal padding (now vertical-only: `24px 0 40px` desktop, `12px 0 90px` mobile). `.container` is now the single horizontal gutter: 16px on mobile (was 14px), safe-area aware. Consolidated the two conflicting `.container` mobile rules (one was at ~line 580, canonical one at ~line 2730).
- Tightened analysis-card padding 20→18px mobile, section-sub margin/size on mobile.
- History subtitle finally fixed: removed `data-i18n="history.subtitle"` from the `#historyCount` element (the i18n pass was re-applying the old "Every workout…" string over renderHistory's dynamic text). Now renderHistory's count line is the source of truth.
- Feedback/rate widget held back during onboarding: `showFeedbackWidget()` now skips while `_spotlightState.active` or the `#tourOfferModal` is up, AND for the first 2 days after the account's first app-open (localStorage `stryxs_feedback_eligible_at_<uid>` timestamp). Reappears on a later session.

#### ✅ Round 10b DONE (frontend v67, pushed): Coach chat reborn + two form fixes
- **Coach tab → full-screen Claude-style chat.** When the Coach chat shows, `renderCoachChat` adds `body.coach-chat-active`; CSS turns `#page-coach.active` into a `position:fixed` flex column pinned under the top nav (`top: calc(var(--safe-top)+56px)`, `bottom: var(--coach-kb-inset)`). Messages scroll in a centered 780px column, composer floats at the bottom. AI replies render as **plain text (no bubble)** via `.chat-msg:not(.user) .msg-bubble{background:transparent;padding:0}`; athlete messages keep a neutral grey bubble, right-aligned. Avatars hidden. `renderIntake` + `navigate()` (when leaving coach) remove the body class so only the chat is locked.
- **Keyboard handling:** new `setupCoachKeyboardInset()` listens to `window.visualViewport` resize/scroll and sets `--coach-kb-inset` = keyboard height, so the composer lifts above the on-screen keyboard. CSS var defaults 0 in `:root`.
- **History cap:** loads the latest **300** messages (was 200, showing only last 20 behind a "Show older" toggle). Now renders all 300; older stay in the DB (Coach still queries full history for context), the toggle is gone. `toggleArchivedMessages` + `loadCoachPersonaBadge` are now dead/uncalled (left in place, guarded no-ops).
- **Two top boxes deleted:** the `.coach-hero.coach-hero-chat` ("Coach" hero) and `#coachPersonaBadge` (coaching-style card) were removed from the chat.
- **Plan Management MOVED** to the Plan tab, rendered after the "Share your plan" block (always shown when intake complete, since renderPlan early-returns otherwise). `initPlanMgmtHelpAutoOpen()` call moved with it. Markup identical (Import / Generate / Reset cards + ? help). New-chat button: Noah chose NOT to add one (chat stays one continuous thread).
- **Log-manually form fix** (the overlapping/misaligned boxes Noah reported): shortened the EN labels (`Duration (min)`→`Duration` with a "min" suffix box; dropped "(optional)" from Distance/Avg HR/Max HR) so they no longer wrap to different line counts and push the inputs to different heights; added `#logManualContent label{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}`. Also killed `<input type=number>` spinner arrows app-wide.
- **Workout-feedback RPE row** (the effort rating that "went off the page"): buttons changed from `flex:1;min-width:28px` to `flex:1 1 0;min-width:0;padding:9px 0`, gap 4→3px, so 10 buttons always fit narrow phones.
- **NOT tested live** — the Coach chat is behind auth + Supabase, can't run locally. Validated JS syntax + structure only. Noah verifies on iPhone after deploy (hard-refresh for PWA cache). If the fixed-position layout has an iOS quirk (gap under nav, keyboard covering input), that's the first thing to check.

#### ✅ Round 10c (v68) + 10d (v69) DONE — Noah confirmed v67 Coach chat "looking really better"
Shipped this session (all frontend, no edge deploy):
- **Branded boot splash:** `#appSplash` element + `body.app-loading #appSplash` CSS shows the "Stryxs" Instrument-Serif wordmark (pulsing) instead of the old `::before` spinner. In-app `.spinner` kept.
- **Coach "+" attach menu (UI-only):** `renderCoachInputRow` now has a `+` button → drop-up (`#coachAttachMenu`, Photo/File), hidden `#coachFileInput`, removable chips (`coachAttachments` array + `renderCoachAttachPreview`). Send button `#coachSendBtn` starts `disabled` (grey via `:disabled`/`.coach-send-muted`), `updateCoachSendState()` flips it green when there's text OR an attachment. `onChatInputChange` replaces the old `oninput`. On send, attachments are cleared with a "coming soon" toast (no real vision yet — see deferred note up top).
- **Top nav wordmark only:** removed the `.logo-mark` img from `#mainNav`, added `.logo-wordmark-only` class, bumped wordmark to 27px / 24px mobile. Landing nav left as-is.
- **Skip modal centers on desktop:** `openSkipWorkoutMenu` now branches on `window.innerWidth > 720` (centered dialog vs bottom sheet).
- **Streak preserves excused skips:** the trends streak calc loads `skipped, skip_reason`, builds `excusedDays`, and the current training + adherence streak walks bridge excused days instead of breaking.
- **French leak fixed** (see header). loadProfile gated on `!LANG_UI_DISABLED`, self-heals stored `fr`→`en`.
- **Proactive plan-change awareness (10d):** `logPlanChange` (localStorage `stryxs_plan_changes_<uid>`) hooked into `skipWorkout` + `swapWorkoutDate` (both now `.select()` the row for sport/date). `detectPlanChangePattern` finds a signature repeated across ≥3 distinct Monday-weeks; `maybeSuggestPlanPattern` inserts ONE coach_message (`context_type:'plan_pattern_suggestion'`) + sets unread. `renderMsg` renders Yes/No buttons for that context_type; `applyPlanPatternSuggestion` routes a request through normal `sendChatMsg`, `dismissPlanPatternSuggestion` dismisses; both flip context_type to `_done` + dedupe via `stryxs_plan_pattern_done_<uid>`. NOTE: pattern only fires after 3 weeks of real repeated behavior post-deploy (log starts empty), so it won't trigger immediately — that's intended.

#### ▶ START HERE NEXT SESSION
1. **Ask Noah how v68/v69 felt on his iPhone** (not testable locally — auth + Supabase). Specifically: the boot splash, the Coach "+" menu + grey/green send, the bigger wordmark, the centered skip modal on PC, and whether Coach is now fully English. If he still sees French workout *descriptions* in the Plan tab → that's stored data, he needs to regenerate the plan (see caveat up top).
2. Likely-next asks: make the "+" photo import actually work (Coach vision — edge-function change, see deferred note), and continue the round-10b items below (inline non-stacking grids, type ramp, touch targets, card polish, dashboard, plan calendar).

#### 🔜 Round 10b+ STILL TO DO (the deep redesign — continue here):
1. **Non-stacking inline grids**: several `grid-template-columns: 1fr 1fr` use INLINE styles (lines ~7909, ~16732, ~16745, ~22025 in v66) that don't stack on narrow phones. Inline styles beat CSS classes, so either convert them to a class (e.g. `.stat-2col` with a `@media(max-width:560px){grid-template-columns:1fr}`) or edit the inline style to be responsive. The `.trends-row` cards ALREADY stack correctly (good reference pattern). Check race-planner + dashboard stat rows + the auto-sync panel grid.
2. **Type ramp**: establish a coherent mobile type scale. Noah said headings look "too big compared to things right next to it." Audit `.section-title` (clamp 24-34px, fine), card titles, `.stat-value` (22px mobile), and big numeric displays — make sure neighbors are proportional.
3. **Touch targets**: ensure buttons/chips are ≥44px tap height on mobile. Many `.btn ghost` chips are ~28-32px.
4. **Card system polish**: RestOrTrain look = clean white-ish cards with generous padding, soft shadows, clear hierarchy. Ours are dark — keep dark but add consistent radius (we use 10-16px in different places — standardize), consistent internal padding, and more vertical rhythm between cards.
5. **Dashboard**: the recent-workouts sport-group cards + Today card + week strip — verify they breathe on mobile and don't overflow.
6. ~~**Coach chat**: message bubbles + input row on mobile.~~ ✅ DONE in round 10b (full-screen Claude-style rebuild, see above).
7. **Plan calendar**: RestOrTrain's calendar/day-card layout is a good benchmark for our Plan tab.
8. Reference screenshots Noah sent: RestOrTrain has a clean day-by-day card stack (date chip on left, white workout card on right with a mini chart + "Review"/"Guide" button), generous whitespace, big bold headings on the onboarding ("The Ultimate AI For Endurance Athletes", "Next Level Planning"). Don't copy — match the cleanliness/spacing.

**Verification**: Noah tests on a real iPhone (the screenshots are iPhone, 1170×2532 → displayed 924×2000). Test at ~390px CSS width. Hard-refresh after each deploy (PWA cache).

### What 2026-05-19 round 9 delivered (bug-fix sweep on round-8 features)

Frontend v61 → v65, Strava edge refreshed several times. All the round-8 features had bugs that surfaced once Noah used them on real data.

**Round 9a (v62, strava edge):** (1) Classification reset on refresh — `handleReanalyzeActivity` / `handleBackfillDetails` only read/wrote `workout_data`, never the `activity_classification` COLUMN, so they drifted. (2) Swim per-lap data — `stravaActivityToWorkout` now captures `pool_length` + `swim_laps` (per-lap distance, elapsed, pace/100m, HR, isRest flag for 0-distance rest laps). New `renderSwimLapsTable` + `renderSwimPaceChart`, wired into `renderSummaryWorkout` for swims. `renderDataAvailabilityHint` treats swim_laps as rich data.

**Round 9b (v63, strava edge):** (1) Classification RACE — auto-refresh fires +600ms after view; if user clicks Planned before the refresh write lands, the stale read clobbered it. (2) Chart axes — added X+Y axis labels via HTML overlay (SVG text stretches with preserveAspectRatio=none). (3) Sync-now stuck button — wrapped in try/finally so it always resets (renderConnections only re-renders the Settings panel, not the Analyze button). (4) Manage-connections target — new `openSettingsSection(id)` helper retries until the section mounts, force-expands, scrolls into view. (5) Intensity dropdown — removed max-height/overflow that forced a permanent scrollbar gutter.

**Round 9c (v64, strava edge):** THE BIG ONE — (1) **TDZ crash**: `renderStryxsLineChart` referenced `yGutter` in its data-cache object BEFORE the `const yGutter` declaration → ReferenceError that threw on EVERY line chart (all time-series, dual-line, swim pace, long-split lines). This is why the swim "Could not render analysis". Moved declaration up; verified all renderers via an extracted node harness. (2) **History wrong-workout**: items baked array INDEX into onclick; indices shift when loadWorkouts() rebuilds state.workouts (after auto-refresh). Switched to stable `_dbId` via new `_resolveWorkoutRef()`. viewHistoryDetail / classifyWorkout / showClassificationOptions all resolve by _dbId now. (3) Classification race — backend now RE-READS the row right before update (captures user clicks during in-flight enrichment), writes only workout_data (column = source of truth, never overwritten). (4) Today's-analysis inline refresh re-renders in place (dataset.dbid) instead of yanking to history detail. (5) Intensity dropdown — switched to position:fixed (was growing the document on the last card, spawning a stray scrollbar), closes on scroll.

**Round 9d (v65):** (1) Chart axis label overlap — Y-axis ticks showed value+unit ("2:27/100m") overflowing into the rotated title. Added `_stryxsBareFormatter` so ticks show value only ("2:27"), title carries the unit. Gutter 46→52px, fixed 16px title column with overflow:hidden, white-space:nowrap. (2) History limit text — subtitle "Every workout you've analyzed" → "Your recent workouts"; renderHistory caps display at 30 (Pro) / 5 (free), count line states "Showing your 30 most recent · N saved" + footer "All N saved and used by Coach". **NOTE: Noah reports the subtitle text still didn't change — likely because `data-i18n="history.subtitle"` re-applies the old I18N value over the static text. Round 10 fix: remove the data-i18n attr or update I18N.** (3) Data-preservation audit — confirmed regenerate plan deletes only planned_workouts + training_plans (keeps workouts + intake + profile); full reset also clears coach_messages + marks intake incomplete but KEEPS workouts + profile; no code path anywhere deletes workouts/profiles/athlete_intake (only account deletion does). Logged history + settings survive plan recreation. ✅

### What 2026-05-18 round 8 delivered (rich workout data + interactive chart toolkit + map color toggle + auto-refresh)

Six clean deploys over the same session, frontend v55 → v61, plus Strava + Coach edge refreshes. Noah asked for: more Strava data displayed, map color option, prettier interactive graphs, missing-data UX fix. All shipped.

**Round 8a (frontend v56, strava + coach edge):** First-pass — map dark/color toggle (floating button top-right of each Leaflet map, persisted in localStorage), per-split bar chart (color-graded green→red by relative variance), dual-line overlay charts (Pace+Cadence run, Speed+Cadence + Power+HR bike), workout meta chips expanded (calories, kilojoules, max speed/cadence, PR count, indoor). Strava edge captures kilojoules + maxes + pr_count + achievement_count + trainer/commute/manual flags + device_name + workout_type_strava + timezone. Stream-derived maxes as fallback. Coach chat() context line now includes cadence, power, NP, calories, elevation, RPE, suffer, indoor, PR, splits range, gear, description excerpt. `workoutCommentary` compacts series via new `compactWorkoutForCoach()` helper (saves 600-1200 tokens per call).

**Round 8b (frontend v57, strava edge):** Bug fixes after Noah tested: Carto Voyager URL was missing `rastertiles/` path (color tiles 404'd, rendered blank). `enrichWithDeepAnalysis` was bailing on `_no_hr_data` BEFORE downsampling streams, computing maxes, or patching split elevations — so any GPS run without HR strap got "no splits, no charts" even when Strava had everything. Restructured: HR-independent enrichment runs unconditionally now (new `attachStreamData()` helper), only HR-only stuff (zones, drift, classification) gates on HR. NEW `synthesizeSplitsFromStreams()` walks distance+time streams to build per-km splits when Strava's splits_metric is missing. Backend stores `_no_hr_data: true` but with `summary_only: false` so the frontend renders the rich-but-no-HR view.

**Round 8c (frontend v58):** Color map was too pale (Voyager). Switched to classic OpenStreetMap (`https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`) — much more saturated, easy to read. Inline "↻ Refresh this workout's data" button now appears in the data-availability hint on every Strava workout missing route/splits/charts. UN-GATED from Pro (reanalyzeStravaWorkout no longer pro-gated — refreshing your own data is not a premium feature). Exposed as `window.refreshStravaWorkout` alias. Friendlier toasts on success.

**Round 8d (frontend v59):** Three things: (1) `maybeAutoRefreshWorkout(w)` — when user opens a Strava workout missing splits/streams, silently kick off refresh in background, throttled per-session-per-workout via sessionStorage so it can't burn Strava quota (max 2 API calls/refresh × 1 attempt/workout/session). Called from `viewHistoryDetail` and `toggleTodaysAnalysis`. (2) Usage bars live update — `callCoach()` now re-renders `renderProUsageBars()` after every Coach call (excluding `get_my_usage`, `export_my_data`, `get_persona`) if the Subscription section is open. (3) Chart toolkit rewrite — replaced `renderTimeSeriesChart` / `renderDualLineChart` / `renderSplitsBarChart` with a unified system: Catmull-Rom-to-Bezier smoothing (`_stryxsSmoothPath`), subtle horizontal grid (25/50/75%), interactive crosshair + tooltip on hover (`_stryxsAttachChartHover`), touch support with 2.2s linger after touch-end, tooltip auto-anchors near edges so it doesn't clip, `vector-effect: non-scaling-stroke` keeps line widths consistent. Splits chart auto-switches to line/area when count > 25 (bars become illegible).

**Round 8e (frontend v60, strava edge):** Bug fixes: (1) Bike "speed per split" chart was computing `3600/elapsedSec` assuming each split = 1km. The last split is almost always partial — 480m in 27s read as 64 km/h. Strava edge now stores `distanceM` per split (both splits_metric AND synthesized-from-streams paths). Frontend uses `(distanceM/elapsedSec)*3.6` for true speed. Filter drops >80 km/h as backstop for old data. (2) Splits bar chart's dashed average line was drawn BEFORE bars (covered by them). Reordered to draw AFTER so it sits on top.

**Round 8f (frontend v61):** Final polish: (1) Split bar height for runs was using raw paceMin ratio, so slower splits = taller bars (counter-intuitive — looks like "tall = good" intuition is universal). Inverted for runs: `heightRatio = sport === 'run' ? (1 - r) : r`. Now taller = faster on BOTH sports. (2) Single accent green color for all split bars (color gradient had no real meaning without HR zones). Will layer in HR-zone-aware coloring later once we have zone data driving it. (3) "No heart rate data on this activity" copy changed from "Wear a HR monitor next time" (implies they weren't) to "No heart rate was recorded for this activity. Zone analysis and cardiac drift will appear when HR data is available." (4) "Open on Strava ↗" footer link now in Strava orange (#fc4c02), bold.

**Caveats / what to remind Noah:**
- Existing Strava workouts synced before round 8 don't have the new fields (kilojoules, distanceM, etc.). They auto-refresh on view (round 8d hook), OR he can hit Settings → Strava → "Refresh older workouts" for bulk.
- Refresh costs: 2 Strava API calls per workout (out of 100/15min, 1000/day budget), ZERO $$ / Anthropic credits. Auto-refresh is safe.
- For splits SYNTHESIS to give real km splits, the workout needs distance + time streams (which any GPS run/bike has). Treadmill / Zwift indoor without GPS may have streams without distance — splits will be synthesized from distance if available, otherwise empty.

### What 2026-05-18 round 7 delivered (English-only retreat + Strava view upgrades)

After 6 rounds couldn't fix Noah's PWA-cache-bound language picker bug, Noah called the right shot and asked to rip out the language code entirely. Done. Plus shipped the Strava view improvements he wanted (real maps + graphs).

**Language code stripped:**
- Added `<meta name="google" content="notranslate">` in head — biggest single fix. Chrome's auto-translate was the root cause of bizarre English-back-from-French gibberish ("Strava" → "Diet", "Log manually" → "Grasping by hand", etc.).
- Emptied `I18N.fr` dict (~200 strings) and `PHRASE_TRANSLATIONS_FR` dict (~200 phrases). Kept structure dormant — `t()` falls back to `I18N.en`, runtime walker gated on `locale !== 'fr'`.
- Stripped picker functions to no-op stubs: `showLanguagePickerModal`, `pickLanguage`, `renderLanguageButtons`, `pickLanguageFromSettings`.
- Removed Settings → Language section markup entirely.
- `state.locale` forced to 'en' on init via existing `LANG_UI_DISABLED` const.
- To restore language UI later: re-populate the two dicts, restore the function bodies (in git history at commit 22fabc0~1), unhide the Settings section, set LANG_UI_DISABLED=false.

**Real maps via Leaflet:**
- Added Leaflet 1.9.4 via CDN (CSS + JS in head)
- New `renderGpsMapPreview` returns a placeholder div; `mountStryxsMap()` mounts a real Leaflet map with Carto Dark OSM tiles + polyline route + start/end markers. Auto-fits bounds. No API key.
- One placeholder per workout (unique ID via `_stryxsMapCounter`), mounted via setTimeout for both sync and microtask-deferred insertions.

**Time-series mini-charts:**
- New `renderTimeSeriesChart(series, label, unit, color)` helper renders an SVG sparkline with gradient fill + avg/min/max stats. No-ops on missing/short series.
- `renderRun` now shows: HR, pace, cadence, elevation charts after splits
- `renderBike` now shows: HR, speed, power, cadence, elevation charts after splits + power stats
- All gracefully empty when the data isn't there.

**Strava edge function — capture stream data for charts:**
- `enrichWithDeepAnalysis` downsamples per-second streams to 80 points each: `hrSeries`, `paceSeries` (run), `speedSeries` (bike), `cadenceSeries`, `powerSeries`, `elevationSeries`. Stored on `workout_data`. ~2.5KB extra per workout.
- `stravaActivityToWorkout` now captures `elevation_difference` per split into the splits array, so the renderSplitsTable elevation column populates.
- Existing workouts won't have the new series until re-synced. Going forward, all new imports get the full data.

**Caveats:**
- Existing Strava workouts in DB don't have the new series fields. Backfill option: re-trigger sync, or wait for the next sync naturally. Noah's "Refresh older workouts" button in Settings → Strava already exists and will re-fetch with the new data.
- Leaflet tiles load from cartocdn.com — first visit on a slow connection takes ~1s for tiles. Acceptable.

### 🔜 NEXT SESSION PRIORITIES (round 8+)

**1. STRAVA 403 — beta blocker.** Noah needs to file the Strava API quota increase request at strava.com/settings/api. Form is on his app's developer page. Until approved (~2-7 days), beta testers beyond user #1 must use Manual Entry (Analyze → Log manually). Remind him on next session start if he hasn't filed it.

**2. Verify the language picker bug is GONE.** Round 6 took a nuclear approach — bumped SW to v4 (deletes ALL caches on activate, force-reloads navigations), rebuilt picker with DOM API + ASCII-distinct labels (ENGLISH/FRENCH primary + native qualifier), added runtime DOM translation walker. If Noah STILL sees buggy buttons after v54 deploy + PWA uninstall/reinstall, then the rendering itself has a hidden bug I can't see from code alone — at that point we'd need browser DevTools debugging with him.

**3. Expand the runtime translation dictionary (PHRASE_TRANSLATIONS_FR).** Currently ~200 phrases. Noah will report missing translations as he uses the app — each is a one-line add to the dict. Common future adds:
- Intake question text + option labels
- Plan calendar internals (workout type labels, weekly summary)
- Trends/insights card titles
- All modal bodies (Pro upsell, feasibility warnings, share plan, delete account)
- Toast messages (they call toast() with hardcoded strings; either tag or add to dict — but the walker only catches DOM text, not toast args, so toast calls still need t() conversion)

**4. When Noah is ready for Spanish/Italian/etc.** add a parallel PHRASE_TRANSLATIONS_ES (or _IT) dictionary + extend the I18N table with 'es' / 'it' branches + extend translateDOMWalker() to switch on state.locale. The infrastructure is set up for this.

### 🔜 OLDER PENDING — what's still pending

User explicitly said: continue in this same session tomorrow. Last note from Noah at end of session: "i [will] continue this tomorrow in this same session ok make sure everything is good before i leave."

**i18n completeness — the big remaining work.** Current coverage ~200 strings; app has ~600-800 total user-visible strings. Infrastructure is solid (data-i18n tags + applyI18nToDom on navigate + Coach gets locale on every call). What's still English:
- **Toast notifications** — most `toast('...')` calls still pass hardcoded English. Grep for `toast(` and convert to `toast(t('...'))`.
- **Buttons INSIDE settings sections** — "Save changes", "Disconnect", "Manage", "Generate plan", etc. Section HEADERS are tagged but inner content isn't.
- **Intake/onboarding flow** — none of the questions, options, or chat-style prompts are translated. Large surface (~50-80 strings).
- **Plan tab body** — calendar internal labels (Rest day, Easy run, Long ride, etc.), week strip labels, "Generate next week" button, plan management area.
- **Trends/insights cards** — patterns rendered from Coach are already in user's locale (Coach gets userLocale), but the SHELL around them ("Recent patterns", "No insights yet", filter chips) is English.
- **History list items** — workout type labels, date headers, source badges.
- **Modal text bodies** — Pro upsell card body (just the heading is tagged), feasibility warnings, skip-workout confirmation, delete-account flow, share-plan modal.
- **Coach feedback widget** — "How did this feel?", RPE labels, felt chips on the WORKOUT view (not the manual entry form, which IS translated).
- **The race planner** — entire surface area, large.
- **Pro pricing page body** — just heading is translated.
- **terms.html, privacy.html, help/FAQ content** — long form, defer.

**Approach for tomorrow:**
1. Grep all `toast(['"]` and convert to `t()` calls. Add the FR translations.
2. Grep all `>Save<`, `>Cancel<`, `>Save changes<`, `>Delete<` etc. — bulk-tag with `data-i18n` references to `common.*` keys.
3. Walk through the intake flow page by page, tag each question.
4. Plan tab body pass.
5. Modal bodies.
6. Last: race planner.

**Verification path Noah follows:** sets language to French, navigates through every screen, screenshots anything still in English. Then we knock those out batch by batch.

**Settings I changed for him this session (don't undo):**
- `~/.claude/settings.json` set to `{"permissions":{"defaultMode":"bypassPermissions"}}` so he never sees permission prompts again in any session.
- Two memory files in `~/.claude/projects/C--Users-noahb-stryxs/memory/`:
  - `feedback_autonomy.md` — push/deploy without asking
  - `feedback_chat_noise.md` — don't echo "is now visible in preview panel" hooks back to him

### What 2026-05-17 round 5 delivered (post-Phase i18n polish, 3 deployment rounds)

After the round-4 Phase 1+2+3 ship, Noah reported a series of specific issues he saw in the deployed app. Each fixed in a separate commit + deploy. All on main, Vercel auto-deployed each time.

#### Round 5a — Visual + layout fixes (frontend v49, coach edge refresh)
Noah's screenshots showed: Language section first (too prominent), language buttons used emoji flags that rendered as plain "GB"/"FR" text on Windows with bad vertical alignment, Account Deletion icon (`🗑`) was invisible on Windows, Analyze page "Or upload CSV manually →" link was a no-op (called `navigate('upload')` while already on upload page), manual entry form needed adapting per sport.

Fixes shipped:
- **Settings → Language**: moved from top to under Connections. Dropped emoji flags. New monogram badges (EN/FR styled). Click now swaps buttons in place (was rerenderActivePage which collapsed the section — the real bug behind "doesn't change anything").
- **Account deletion icon**: `🗑` → `⚠️` (visible warning triangle, fits red theme)
- **Auto-sync "Upload CSV manually →" link**: now calls `toggleAnalyzeSection('uploadCsv')` to open the panel on the same page
- **Manual entry form**:
  - "Strength" → "Gym" label (key stays 'strength' for back-compat)
  - French "Course" → "Course à pied" (disambiguates from "course"=race in French)
  - Variable fields per sport via new `renderManualVariableFields(sport, distUnit)`:
    - Gym: distance hidden (n/a for strength)
    - Other: new "What did you do?" text field (yoga, hiking, etc.)
    - All HR labels say "(optional)"
  - "Other" activity stored as `workout.activity_subtype` + prepended to description
- **Coach edge `workoutCommentary`**: detects `workout.source === 'manual'` and softens prompt — don't critique pace/zone, focus on RPE/notes/felt-flags, be supportive (data is estimated)

#### Round 5b — Language switch actually fixed (frontend v50)
After 5a, Noah reported clicking buttons "did nothing". Root cause traced:
- `setLocale` called `rerenderActivePage` which rebuilt full Settings innerHTML
- Only Profile section starts with `expanded` class — Language section collapsed mid-click, buttons vanished
Fix:
- Removed `rerenderActivePage` call from `setLocale`
- Tagged nav menu (Dashboard/Coach/Plan/Race plan/Analyze/History/Trends), avatar dropdown (Settings/Upgrade/Help/Log out), Settings page title + sub with `data-i18n`
- Added `nav.race_plan / nav.help / nav.logout / nav.upgrade_to_pro / settings.sub` keys for en + fr
- Signup picker now returns a Promise so doSignup awaits it BEFORE navigating to dashboard (so first paint is in chosen locale)

#### Round 5c — Permissions + chat-noise preferences saved (user-level)
Noah said: "i keep getting messages allowing you to do things, can you take them away for all future sessions" + "the preview panel link blocked message keeps appearing".

- Wrote `~/.claude/settings.json` with `permissions.defaultMode: 'bypassPermissions'` — applies to ALL Claude Code sessions on his machine, every project. He should never see permission prompts again.
- Saved `feedback_chat_noise.md` memory file telling me to NEVER echo "is now visible in Launch preview panel" back to him in user-facing replies. That message comes from a built-in Claude Code hook I can't disable via settings, but I can stop amplifying it.
- Added pointer to the memory index `MEMORY.md`.

#### Round 5d — Pass locale to Coach + expand translations (frontend v51, coach edge refresh)
Noah said language switch only changes a few phrases, Coach replies in English when he types short messages, the whole app must change.

- **callCoach()** now injects `state.locale` as `payload.userLocale` on every call (single chokepoint = every action gets it)
- **Coach dispatcher** attaches `payload.userLocale` to `payload.intake._locale` so `buildSystemPrompt` sees it
- **LANGUAGE block in buildSystemPrompt** now branches:
  - `fr` → hard-locks Coach to French regardless of message language ("even if they write a single English word like 'ok' or 'thanks', reply in French")
  - `en` → hard-locks to English
  - null/unknown → legacy infer-from-message
- Dashboard greeting now translates (time-of-day + sport-aware "nice work" + count-aware fallback)
- All static page titles tagged: Analyze, History, Trends, Help, Plan, Pro (you're-Pro + upgrade)
- All 14 Settings section headers + subtitles tagged with `data-i18n` (Profile/Personal/Goals/Benchmarks/Equipment/Subscription/Connections/HR/Help/Legal/Language/Notifications/Privacy/Account-deletion)

#### Round 5e — Bulletproof picker + applyI18nToDom on navigate + trial card translated (frontend v52, sw v2)
Noah reported "the top button stays English, the bottom one keeps flipping between English and French depending on what I'm on when I refresh". My read: most likely service-worker cache serving stale code (both labels were hardcoded, no `data-i18n` on them, no other code path could touch them). Defensively rewrote anyway.

- **Service worker CACHE_NAME bumped v1 → v2** to invalidate any stale-cached frontend
- **Bulletproof language picker UI**: radio-style cards with filled/empty dots, explicit "Active" / "Tap to switch" status text, native names "English"/"Français" (never translate), aria-pressed for accessibility, `console.log` on every render so we can diagnose if it ever recurs
- **applyI18nToDom() now runs on every `navigate()`** via `setTimeout(0)` — this is the big one. Was the ROOT CAUSE of "doesn't translate the whole app": render functions used inline `t()` calls so the FIRST render was correct, but after locale switch any newly-navigated page paint was in old locale. Now every tab switch retranslates fresh.
- **Trial welcome card translated** (title + body with {days} param + after-day-7 explainer + "Start with Coach" CTA)
- app_version: v48 → v52

### What 2026-05-17 round 4 delivered (Phase 1 + 2 + 3, full beta-readiness sprint)

All three phases from the round-3 punch list shipped, in this order. Each
phase committed + pushed to main + relevant edge function deployed in the
same turn (Noah set a "be autonomous with deployments" preference, saved as
feedback memory).

#### Phase 1 — Five audit fixes (frontend v46 + coach edge deploy)
- **3a.** "Free forever" copy → "7-day Pro trial, no card" across 3 sites
  (landing meta, landing CTA strip, signup auth-sub).
- **3b.** Free users get 3 Coach messages / 30 days before Pro wall.
  Frontend gate (`canSendCoachMsg`, `getFreeCoachMessagesUsed`,
  `renderCoachInputRow`, `refreshCoachInputRow`) + counter UI ("3 messages
  left" hint). Backend `checkFreeUserCoachLimit` in coach edge enforces
  same rule (check uses `>` not `>=` because frontend inserts the user
  message BEFORE calling chat — without that, the 3rd allowed msg would
  be wrongly rejected). New constant `LIMITS.free_coach_trial_messages = 3`.
- **3c.** Plan-gen loading: new `getMethodologyForGoal()` helper returns
  `{name, brain}` (e.g. Friel, Pfitzinger + Daniels). Loading hero now
  shows methodology brain name; 5-step progress bar advances; each
  `updateProgress(msg, step)` advances the bar.
- **3d.** Empty dashboard recent-workouts: 3 CTAs (Connect Strava / Log
  manually / Upload watch file) replace the static text-only hint.
- **3e.** Coach intro prompt: added explicit "OPEN WITH A 1-2 SENTENCE
  PERSONAL GREETING in your methodology's voice" instruction at top of
  `planIntroMessage` user prompt + same for post-LTHR-entry variant.
  Frontend chat fallback message (zero-message edge case) now uses
  `getMethodologyForGoal()` to say "Hey Alex, Friel in spirit. I built…"

#### Phase 2 — Manual workout entry form (frontend v47)
Third toggle "Log manually" on the Analyze page (alongside Auto-sync +
Upload file). Form fields: sport chips, date (defaults today), duration
(min, required), distance (unit-aware km/mi), avg HR, max HR, RPE 1-10,
felt easy/hard/strong/flat/sore/sick chips, notes textarea.

Helpers: `renderManualEntryForm`, `selectManualSport`, `selectManualRpe`,
`toggleManualFeltChip`, `submitManualWorkout`. State held in
`manualEntryState` object, reset on each open.

Save flow:
- Insert into `workouts` table via existing `saveWorkout()` with
  `source: 'manual'`.
- Classification auto-detected: if a `planned_workouts` row exists for
  the same date+sport, mark as `'plan'`, else `'extra_training'`.
- If RPE/felt/notes set, also insert a `workout_feedback` row (so Coach
  reads the subjective signal next chat).
- Triggers `loadWorkouts()` refresh so the dashboard picks it up.
- Tracks `manual_workout_logged` analytics event.

Also added a small "Got a Garmin/Coros/Apple Watch?" hint in the Upload
File panel pointing users at the Strava-bridge path OR the manual form.

#### Phase 3 — French i18n + signup picker + Settings → Language (frontend v48)
Layer B from the round-3 audit, plus the language-picker UX Noah asked for.

**i18n infrastructure** (vanilla JS, no library):
- `I18N` table with `en` + `fr` for ~120 keys (common buttons, landing,
  auth, language picker, nav, dashboard, coach, analyze, manual, settings,
  pro upsell).
- `t(key, params)` helper, falls back en > key, substitutes `{token}`.
- `applyI18nToDom(root)` walks `[data-i18n]` (textContent) and
  `[data-i18n-attr="placeholder:key"]` (attrs).
- `detectInitialLocale()`: localStorage > navigator.language > 'en'.
- `setLocale(loc, {skipDbWrite})`: persists to `profiles.locale`,
  localStorage, sets `<html lang>`, re-renders active page via
  `rerenderActivePage()`.
- `state.locale` set to detected value before first render.
- `loadProfile` reads `data.locale`, applies if it differs from current.

**Translated surfaces (v48):**
- Landing page: hero subtitle, both CTAs, meta strip, CTA strip
- Signup: title, subtitle, all field labels, placeholders, button,
  "have account" link
- Login: title, subtitle, email/password labels, button, "no account" link
- Coach chat: hero title + subtitle, input placeholder, Send button,
  free-trial hint + exhausted message
- Dashboard empty recent-workouts: title, subtitle, 3 CTAs
- Manual entry form: all labels, sport chip labels, felt chip labels,
  notes placeholder, submit button, status messages, error messages
- Analyze toggle labels (Auto-sync / Log manually / Upload file)
- Settings → Language section header + sub

**Signup language picker** (`showLanguagePickerModal`,
`showLanguagePickerIfFirstTime`): fires once per user after first signup,
gated by `stryxs_lang_picker_shown_${user.id}` localStorage flag. Two
big buttons (🇬🇧 English / 🇫🇷 Français). `pickLanguage(loc)` calls
`setLocale` + tracks `language_picked` event + closes modal.

**Settings → Language section**: pinned ABOVE Profile section in
Settings. Two buttons (English / Français), active one styled with
accent color + checkmark. `pickLanguageFromSettings(loc)` swaps live
and toasts confirmation.

**migrate_v6.sql:** RUN by Noah in Supabase Studio at end of session.
`profiles.locale TEXT DEFAULT 'en'` column is live. Language picks now
persist to the profile row, not just localStorage. No further DB work
needed for i18n.

**Deferred to future sessions** (infrastructure is in place, just need to
drop strings into I18N + tag HTML):
- Intake questions (huge surface, ~50 strings)
- Plan tab body content
- Trends/insights detail copy
- Race planner
- Long-form modal copy (feasibility warnings, trial welcome card, etc.)
- Emails (send-followups templates)
- terms.html, privacy.html

### 🔜 PENDING for next session — older audit items + Phase 3 expansion

Noah is gathering beta users. Three blockers came up at end of 2026-05-17 round-3 session, plus an audit identified some first-run-UX issues. Tackle in this order:

#### 1. Manual workout entry form (~4-6 hours, frontend + maybe Coach)
**Why:** Several of Noah's beta users use Coros / Garmin / Apple Watch and don't want to use Strava. The file picker on the Analyze page accepts .csv/.tcx/.gpx/.fit but the actual parser may be CSV-only. Garmin Connect / Coros app / Apple Watch all export to .fit, not .csv. Best v1 fix: manual workout entry form.

**Build:**
- Form on the Analyze page (alongside Auto-sync + Upload CSV toggles): "Log manually"
- Fields: sport (run/bike/swim/strength/other), date, duration (min), distance (km/mi), avg HR, max HR, notes, optional perceived effort (the same workout_feedback chips we already built)
- Save into `workouts` table with `source: 'manual'`, classification 'plan' or 'extra_training' based on whether a planned workout exists for that date+sport
- Frontend renders these in history / today / trends like any other workout
- Coach reads them like any other workout (already does — chat context just looks at workouts table)
- Bonus: also write a short doc page or in-app blurb: "Have a Garmin/Coros/Apple Watch? Connect it to Strava once (link to Garmin Connect → Strava settings, etc.), works automatically after that. Or log workouts manually below."

#### 2. Layer B — French i18n for ~150 critical UI strings (~8 hours, frontend only)
**Why:** Most of Noah's beta users speak French. Layer A (Coach French) shipped today, but the buttons around the chat still say "Generate plan" / "Save changes" etc.

**Build:**
- Add `profile.locale` field (or detect from `navigator.language` if not set)
- Add a Settings dropdown: Language → English / Français
- Build a lightweight `t(key)` function with `en.json` + `fr.json` lookup tables at the top of `<script>` (no external i18n library — keep it vanilla)
- Translate the ~100-150 strings on: landing page hero/CTAs, signup/login, intake questions, dashboard greeting + cards, Coach tab shell, Settings labels, Plan tab, key buttons, Pro upsell, empty states
- Defer: emails, help/FAQ, terms.html, privacy.html (those are full pages, do later)
- Test: switch language, every screen renders without layout breaking (French text is ~30% longer than English on average)

#### 3. Audit fixes — first-run UX (~4 hours, frontend mostly)
From the 2026-05-17 round-3 audit, here are the friction points worth fixing before beta:

**3a. "Free forever, no credit card required" on signup is misleading.** Free tier is effectively read-only (no Coach chat, no plan gen). New user creates account expecting AI coach, hits Pro wall immediately, bounces. Change to "Start free trial — no credit card required" (matches the actual auto-trial flow).

**3b. Coach chat trial: let logged-in free users send 3 Coach messages before Pro wall.** Noah agreed to this in the audit Q&A. Implementation: count user's coach_messages where role='user' in the past 30 days. If <= 3 AND user is free, allow the chat call. Frontend: replace the hard Pro-only gate with the same counter logic. Backend: same check in chat() before checkUsageLimit. Cost: ~$0.02 per free user, big psychological unlock for conversion.

**3c. Plan generation wait (20-90s) needs a confidence-building loading state.** Right now it's silent. Show "Building your week 1 (this takes ~30s)…" with the persona name appearing as soon as pickPersona runs. Progress dots or pulse animation. Anti-anxiety UX.

**3d. Empty dashboard friendlier copy.** User finishes intake + plan gen, sees Today card + plan but Recent Workouts panel says "No workouts yet". Add a row of CTAs: "Sync Strava" / "Log a workout manually" / "Upload a watch file". The Connect Strava CTA already exists elsewhere; bring it here.

**3e. Coach intro message warmer + persona-flavored.** First Coach message is currently generic: "Hey [Name]. I built your plan based on what you told me…" For a brand-new user this is their FIRST AI conversation in the product. A 1-2 sentence persona-flavored greeting that names the methodology ("Hey Alex, Joe Friel here in spirit. I built you a base-building week…") would meaningfully raise perceived quality. Modify `plan_intro_message` in coach edge function.

#### 4. Cost-of-beta-users (handle as it happens, no code)
The hard cap is $5/user/month (already enforced). Real usage averages 30-50% of cap = $1-3/user/month. For 10 beta users that's $10-30/month total — within tolerance. Use the existing manual Pro grant in Supabase Studio (set `subscription_tier='pro'` + `pro_until=future-date`). Monitor `api_usage` weekly; if a specific user is heavy, throttle them individually.

If it becomes an issue: add a `subscription_tier='beta'` variant that grants Pro features but caps at 150 chats / 8 plan_gens / 75 commentary per month (half the Pro limits). Don't build pre-emptively.

#### 5. (Carry-over) Pro upsell tuning, workout_feedback unique constraint, etc.

**1. Pro upsell tuning** (waits on beta feedback)
Pass 3b put a Pro upsell card at the bottom of free-user workout views, and Round-2 polish gated Coach's Read / drift / projections behind Pro. Beta testers used to see those for free. Risk: feels like a regression. If beta feedback says so: tone down to inline "✨" badge, OR roll back the gate entirely and find a different Pro lever, OR A/B test post-launch. No action until signal.

**2. Verify email branding** (still deferred — 30-second manual check Noah needs to do)
Noah still hasn't checked whether signup verify email is on Resend or Supabase default. Path: Supabase Studio → Authentication → Emails → SMTP settings. If `smtp.resend.com` is there, already on Resend. Otherwise needs Resend SMTP added with the existing RESEND_API_KEY.

**3. (Maybe later) unique constraint on workout_feedback (user_id, workout_id)**
Round-2 added the feedback UI with an update-or-insert pattern instead of upsert, because the table likely doesn't have a unique constraint. Two fast taps could in theory create duplicates. Not blocking, low-priority migration whenever convenient.

**4. (Maybe later) workout_commentary read feedback**
Round-2 wired chat() to receive workout_feedback. workoutCommentary doesn't currently — feedback isn't usually logged BEFORE commentary fires (commentary runs right after sync). If users start re-running commentary after logging RPE, worth adding. Not pressing.

### What 2026-05-17 round-3 delivered — audit + Layer A (Coach French)

After the polish punch list shipped (round 2), Noah said the new nav PRO pill "looked super bad", asked me to revert it, and asked for an honest first-run UX audit + thoughts on whether to start marketing.

**Reverted (frontend v45, commit `0565516`):**
- Removed `.nav-pro-pill` CSS, the `<span class="nav-pro-pill">` in nav HTML, the `refreshNavProPill()` function, and the call to it in `showApp()`. Top nav back to plain avatar. Pro signaling stays strong in Settings → Subscription tab (which Noah said looked good).

**Audit findings — first-run UX (full list documented in section "🔜 PENDING for next session"):**
1. "Free forever" signup copy is misleading (free tier is read-only)
2. Coach chat is locked for free users with zero "try it" affordance
3. Strava-or-nothing flow (file picker accepts .fit but probably parses only CSV)
4. Plan-gen 20-90s wait has no loading state
5. Empty dashboard for fresh users is bare
6. Coach intro message is generic, not persona-flavored
7. No language detection or selector

**Three real blockers Noah raised for beta:**
1. Cost of giving Pro to beta users (verdict: manageable, ~$1-3/user/month average, use manual Pro grant)
2. Non-Strava users (Coros/Garmin/Apple Watch) — needs a manual entry form or .fit parser
3. French language — Coach can speak French (shipped), but UI is English-only

**Layer A shipped this session (Coach speaks user's language):**
- Coach edge function `buildSystemPrompt` now ends with a LANGUAGE block:
  - "Respond in the language the athlete writes to you in." French → French, Spanish → Spanish, etc.
  - Methodology voice stays intact across languages
  - JSON enum keys stay English (pattern_type, severity, etc. — frontend reads them programmatically)
  - JSON human-readable values translate (title, finding, recommendation)
  - Free-text output (chat, workout commentary, plan intro, settings ack) translates end-to-end
  - Default English if unclear
- Verified: deployed to `coach` edge function

**Context-budget note from end of session:** Noah explicitly asked me to flag if I was running out of context. I was at ~70% used after the full day (Areas 1-3 + Strava backfill + round 2 polish + audit + this). Confidence was OK for Layer A (tiny change) but risky for the bigger items (manual entry form, full i18n, audit fixes). Handed off cleanly. Next session starts fresh with this memory as the briefing.

### What 2026-05-17 round-2 delivered — Noah's 15-item polish punch list

After the morning's Coach-quality sprint shipped (Areas 1-3 + Strava backfill), Noah came back with a screenshot-driven punch list of polish items. All shipped in 4 clean deploys + 1 memory commit. Beta users will exercise. Resend email check is the only outstanding item from this list (manual user task).

#### Deploy 1 — Settings polish + Pro signaling (frontend v42, commit `aeb4347`)
- **Upload CSV arrow** in the Connect-Strava CTA was wrongly wired to Settings; now goes to the Upload page (`page-upload`).
- **toggleSettingsSection** now `scrollIntoView`'s the just-opened section. Means "Connect Strava" / "Manage" buttons from elsewhere in the app actually land the user on the Strava block instead of dropping them at the top of Settings.
- **Settings section inner padding** bumped from 4px top to 20px desktop / 18px mobile (content was hugging the divider).
- **Modal-actions** footer padding bumped from 16px to 22px bottom (delete modal buttons felt crowded). Added mobile breakpoint at 16px / 20px.
- **"Danger zone"** renamed **"Account deletion"** with a trash icon instead of warning sign. Same red treatment, professional tone.
- **Subscription tab Pro view** rebuilt: ACTIVE pill, next-renewal date, member-since date, plus a new Usage-this-month block with progress bars for Coach chats / workout commentary / plan generations (wires up the previously-unused `get_my_usage` action). Bars colour-shift to yellow at 75% and red at 90%. New `renderProUsageBars()` helper called when subscription section opens.
- **PRO pill in top nav** beside the avatar (subtle green chip). Shows "TRIAL" during trial, "PRO" once active, hidden for free. Collapses to an 8px dot at very small screens. Wired into `showApp()` via new `refreshNavProPill()`.

#### Deploy 2 — Brand consistency (frontend v43, commit `10dd980`)
- Landing page had a generic abstract green ring as its brand mark; app nav had the actual favicon SVG. Wordmark text used different fonts/styles. Felt like "multiple brands."
- `.lv2-brand-mark` CSS rewritten: was a positioned div with green background + dark inner `::after` ring; now a bare wrapper hosting `<img src="/favicon.svg">` with the same accent-color glow animation. Removed `::after` rule.
- 3 landing nav HTML occurrences updated to inject the actual logo.
- App top-nav `.logo span` now uses Instrument Serif font (matching landing) with the same italic accent-color "s" treatment (`Stryx<em>s</em>`). Scoped to `.logo` so it doesn't bleed elsewhere. Mobile scales the wordmark at <=480px.
- Legacy `landingNav <span>Stryxs</span>` updated to the new wordmark too.
- `.lv2-compare-name` on the comparison card left as plain text (it's body content showing the brand name alongside competitors, not a brand display).

#### Deploy 3 — 90-day chat message cleanup (send-followups edge, no version bump)
- New `pruneOldChatMessages(sb, 90)` helper deletes coach_messages older than 90 days.
- Runs on every daily fire of the existing 14:00 UTC `send-followups` cron (cheap single delete with a head-count first for logging).
- Why 90 days: Coach only reads the most-recent 20 messages anyway, so older ones are dead DB weight + basic privacy hygiene. Frontend's "Show older" archive only sees what's in the table, so users gradually lose access to chats >90 days old.
- Results object adds `message_cleanup: { threshold_days: 90, deleted: N, errors: 0 }` so the daily run logs it.

#### Deploy 4 — workout_feedback UI + Coach chat reads it (Coach edge + frontend v44, commit `28719e3`)
Closes the workout_feedback item that's been deferred since May 2026.

Frontend (9 new helpers):
- `renderWorkoutFeedbackForm(workoutDbId)` renders an inline "💬 How did that feel?" trigger at the bottom of every workout view (`renderRun`, `renderBike`, `renderSwim`, `renderSummaryWorkout`).
- `openWorkoutFeedbackForm` lazy-fetches existing feedback (avoids per-workout pre-fetch overhead) and expands the form.
- `buildWorkoutFeedbackFormHtml` renders an RPE 1-10 scale + 6 felt-chips (easy/hard/strong/flat/sore/sick) + optional notes textarea.
- `selectFeedbackRpe`, `toggleFeedbackFeltChip` handle UI state.
- `saveWorkoutFeedback` does an update-or-insert into `workout_feedback` (no unique constraint assumed). Toasts and tracks `workout_feedback_saved` analytics event.
- `renderFeedbackSummary` shows post-save state with an Edit button.
- `reopenWorkoutFeedbackForm`, `cancelWorkoutFeedback` round it out.

Frontend chat wiring:
- `sendChatMsg` now also fetches the user's last 14 workout_feedback rows (joined to workouts) and passes them as `recentFeedback` in the chat payload. Non-blocking on failure.

Coach edge:
- `chat()` signature extended with `recentFeedback` (default `[]`).
- New `feedbackBlock` formatted into the context block between insights and the plan note. Each row reads like `2026-05-12 run: RPE 7/10 · felt strong + sore · note: "legs heavy after Friday brick"`. Coach explicitly told to *use* the feedback, not list it back.
- Dispatcher forwards `payload.recentFeedback` to `chat()`.

#### Items that turned out to already work
- **Chat scroll to last-read / new message on open:** Already implemented in `renderCoachChat` via `localStorage` last-read tracking + first-unread scroll target + smart subsequent-render anchoring. Reviewed the code, no changes needed. The mechanism was added during Round 3 and works correctly.

### What 2026-05-17 delivered — Coach quality deep-dive (full sprint)

**Three areas attacked end-to-end + a follow-on backfill:** Coach reactivity to settings changes, insights system, Strava data depth, plus a Strava backfill action for historical workouts. Each ships in clean independent deploys. Noah opted out of manual testing — beta users will catch issues. Total: 5 commits to main (frontend v38, v39, v40, v41 + memory) + 4 edge function deploys (coach, send-followups, strava twice).

#### Area 1 — Coach reactivity (frontend v38, commit `2198899`)
`detectImportantSettingsChanges` already caught everything, but `sendCoachReactiveMessage` was one-size-fits-all (every change spawned the same "want me to regen?" chat call). Now routes by bucket:
- **SILENT** (run_lthr, bike_lthr, weight_kg, lthr_choice, preferred_long_day): no message, no AI call. These are absorbed by storage. Saves ~1.5K tokens per save.
- **NOTIFY** (pb_5k, pb_10k, pb_half, pb_marathon, last_race, injuries): brief Coach acknowledgment via focused prompt, no regen button. Prompt explicitly instructs Coach not to celebrate slower PBs and not to propose plan changes for injuries.
- **ASK** (equipment, goal_event, race_date, experience_level, current_weekly_hours, available_days, goal_time): Coach proposes regen + button (existing flow), now also fetches next 7 planned workouts and passes to Coach so it can name specific impacted sessions.
- Combined ASK + NOTIFY in one save folds into a single message instead of two.

Net token effect: saves with only SILENT changes cost 0 tokens (was 1.5K). Average save is cheaper AND Coach feels more proactive.

#### Area 2 — Insights overhaul (Coach edge + send-followups + frontend v39, commit `5ef0b59`)
**Latent bug found and fixed:** Frontend sent `payload.allWorkouts` and `payload.userDismissalHistory`, but `analyze_patterns` dispatcher read `payload.recentWorkouts` and ignored dismissals. Net result: analyzePatterns got an empty workouts array and returned `{patterns: [], data_sufficiency: 'low'}` every time. **Insights were silently broken since v8.** Dispatcher now accepts both key names (`allWorkouts || recentWorkouts || []`) and forwards `userDismissalHistory`.

Other Area 2 changes:
- Severity rule strict-tuned in `analyzePatterns` prompt: `urgent` reserved for genuine safety (overtraining >=2 weeks, injury risk patterns, race readiness AND <4 weeks AND missed key workouts). Default `actionable`. `info` for positives only. Explicit "you are a coach, not an alarm system" tone rule.
- `workoutCommentary` now accepts `activeInsights` param. Frontend fetches up to 5 active insights before calling and passes them. Coach is instructed to tie an insight to the workout only when DIRECTLY relevant ("this run lines up with the drift pattern from last week"), and stay silent otherwise. Never list.
- **Sunday weekly insights cron:** `send-followups` (existing daily 14:00 UTC cron) now has an `isSunday` branch that runs `analyze_patterns` for every user who logged a workout in the past 7 days. Mirrors frontend's manual regenerate flow (TREND_PATTERN_TYPES marked stale, fresh ones inserted, `insights_last_generated_at` bumped, info-only generic patterns filtered out). New helpers `refreshInsightsForUser` + `getUsersWithRecentWorkouts`.

Token cost: ~5K per active user per week ≈ $2/week at 100 active users. Well under per-user $5 cap.

#### Area 3 — Strava data depth (strava edge + frontend v40, commit `0568dbb`)

**Pass 3a — backend data capture (strava edge function):**
- Streams request expanded: now also pulls `watts`, `latlng`, `temp` (per-second arrays from Strava)
- `synthesizeLaps` captures power per lap from `watts` stream
- `enrichWithDeepAnalysis` summary computes `avgPower`, `maxPower`, and a true Normalized Power (30-sec rolling avg, ^4, mean, ^0.25)
- `analyzeBike` surfaces those power numbers on the analysis output
- `stravaActivityToWorkout` now captures detail-endpoint fields: `polyline`, `description`, `perceived_exertion`, `suffer_score`, `gear_name`, `gear_id`, `sport_type`, `splits` (per-km, normalized from `splits_metric`), `total_photo_count`, `avgWatts`, `avgTemp`
- `importActivity` heuristically detects whether the passed activity is summary or detailed (looks for map.polyline / description / gear / splits_metric) and fetches detail endpoint when summary. Webhook path already had detail, skips the extra fetch. Bulk sync now upgrades automatically. Extra cost: 1 API call per NEW activity import.

**Pass 3b — frontend display (index.html v40):**
- New render helpers: `decodePolyline` + `renderGpsMapPreview` (SVG route, no map tiles needed), `renderHrZoneBars` (horizontal bars), `renderSplitsTable` (per-km/per-lap table), `renderPowerStats` (avg/max free, NP Pro), `renderWorkoutMeta` (RPE/suffer/gear/photos/temp chips + description block), `renderStravaFooter` (single tiny "Open on Strava"), `renderProUpsell` (single card per workout).
- `renderSummaryWorkout`, `renderRun`, `renderBike` all rewired to use the new helpers. Old layered "View on Strava" CTAs (4+ inline mentions across the diagnostic branches) collapsed to one footer link.
- **Pro gate v1:**
  - Free: HR zone bars/donut, splits, basic power (avg/max), GPS map, perceived effort, gear, description, key insights (math callouts), cadence (run)
  - Pro: Coach's Read narrative, cardiac drift number + verdict, race projection (bike), normalized power
- Diagnostic notices for no-HR / unsupported / streams-failed are quiet one-line callouts instead of the prior "go look at Strava" banners.

**Caveat resolved in same session:** historical Strava activities in DB didn't have the new fields after Pass 3b shipped. A `backfill_details` action was added to the strava edge function and a Settings button to invoke it (frontend v41, commit `9118681`). Users tap "✨ Refresh older workouts" in Settings → Strava and the server re-fetches up to 30 activities per call (1 detail + 1 streams API call each, stays under Strava's 100/15min limit), preserves classification + completed/skipped state, and updates in place. Toast reports updated/remaining counts; user taps again to continue if more remain.

### What 2026-05-17 reconsidered (not changed yet)
- Strava `getZones` LTHR fallbacks (`lthr || 170` for run, `lthr || 165` for bike) live in the strava edge function copy of `analyzeRun`/`analyzeBike`. The frontend has its own copies of those functions. Drift detection / classification works regardless, but fallback LTHR is a guess for users without one. Not a regression, just noting.

### What 2026-05-16 confirmed (brief verify-and-plan session)
- ✅ **Discord preview works.** Noah confirmed after pasting `https://stryxs.com/?social=1`. Hero card with green "train." accent renders.
- ✅ **Production HTML has correct og:/twitter: meta tags** (verified via raw `Invoke-WebRequest` against stryxs.com — `WebFetch`'s markdown stripping had falsely reported them missing).
- ✅ **og-image.png is 1200×630**, served as `image/png` from stryxs.com root.
- ⏭️ **Smoke test items from 2026-05-15 explicitly delegated to beta users** by Noah (login / Coach chat reply / Stripe portal open / no coach_insights 404s). He won't manually click through; will rely on beta user reports.
- 💬 Discussed but parked (no action taken): linking claude.ai chat ↔ Claude Code (Projects + paste workflow, both have web tools), multi-agent subagent setups (`.claude/agents/*.md`, manager-style delegation), and multi-business / transferable-scaffold strategy (user-level `~/.claude/CLAUDE.md` + one project folder per business). All deferred. May revisit once Stryxs has beta users and a real friction signal.

### What 2026-05-15 (Round 3) actually delivered

Ran 3 parallel scan agents, then fixed everything fixable in the frontend. Frontend bumped to v37 (924,069 bytes), then v37+ (og:image fix). All shipped to main.

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
