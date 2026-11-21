# REMIND ME — V0.3 (Static PWA)

This repository is configured to update the **existing** Cloudflare Worker named `quiet-silence-73ff` via Workers Builds / Git integration. It does not create a separate app.

## Cloudflare Workers Builds
- Repository root: `/`
- Production branch: `main`
- Build command: `npm install` (or leave empty if the UI permits)
- Deploy command: `npx wrangler deploy`
- Existing Worker: `quiet-silence-73ff`

Only the static PWA is in this package. It does **not** implement background Web Push, D1 or scheduled reminders. Those require a separate backend release and configuration. Data are local to the browser. The floating Glass Dock is within the PWA, not above the iOS home screen.

Do not upload credentials or API tokens.