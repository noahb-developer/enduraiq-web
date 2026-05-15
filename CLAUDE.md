# Stryxs Workspace

This folder contains the Stryxs frontend (stryxs.com — AI coaching SaaS for endurance athletes).

## Before doing anything: read memory.md

Full project context lives in `memory.md` in this folder. Read it before any work. It covers:
- The full stack and architecture
- Deploy commands Noah uses
- Current file versions
- Deferred work and known issues
- Hard-won lessons (let vs var, VAPID key, em-dashes, etc.)

## Quick rules
- Single `index.html` file, vanilla JS, no build step
- No em-dashes in user-facing copy
- Always preserve the VAPID public key (see memory.md section 5)
- After editing index.html, commit and push to deploy via Vercel auto-deploy

## Repository
This is the stryxs frontend GitHub repo (noahb-developer/stryxs). The edge functions live in a separate folder.
