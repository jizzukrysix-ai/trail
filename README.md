# Vaultgram

A premium **Telegram Mini App file downloader** with an admin panel. Every file is
locked behind **6 rewarded ads** (Adsgram). Watch all six, and the file is
unlocked for that account forever — no signup, no payment.

- **Premium dark theme** (plus a daylight theme) with animated aurora background,
  gold accents, glass surfaces and motion on every card.
- **Image thumbnails for folders**: generated cover art, ken-burns zoom, sheen
  sweep and a mosaic of the folder's own image previews.
- **Every file shows its name, size, format, download count and unlock progress.**
- **6 ad slots per file**, each mapped to its own Adsgram block id.
- **Admin panel**: stats, recent ad activity, folder CRUD, cover art picker,
  multi-file uploads to R2, rename/move/delete, ad configuration, announcement
  banner and a stats reset.
- Runs on **Cloudflare Workers** with **D1** (metadata) and **R2** (files), or
  locally with Wrangler's local bindings.

## How the unlock works

1. `POST /api/bootstrap` creates a session (a signed-in Telegram user once
   `TELEGRAM_BOT_TOKEN` is set) and returns the catalog and per-file progress.
2. The unlock sheet plays a rewarded ad through Adsgram. On a fully watched ad,
   the client calls `POST /api/ads/complete { fileId, slot }`.
3. The server records the slot in `ad_events`, rejects duplicates via a unique
   index, enforces a 3 second minimum gap between slots, and writes an `unlocks`
   row when the count reaches the configured requirement (default 6).
4. `GET /api/files/:id/download` re-checks the unlock server-side and streams the
   file from R2 (or the demo inline content) with an attachment header.

The gate is enforced on the server, so you cannot download by skipping the UI.
Reward verification itself is client-trusted though: Adsgram's client SDK cannot
prove server-side that an ad was watched. For a hard guarantee, plug Adsgram's
server-to-server reward postback into `POST /api/ads/complete` behind a shared
secret if your plan provides one.

## Local development

```bash
npm install
npm run covers          # regenerate folder cover art (already committed)
npm run dev:api         # Worker + local D1/R2 on http://127.0.0.1:8787
npm run dev             # Mini app with HMR on http://127.0.0.1:5173 (proxies /api)
```

First run seeds six collections and eighteen demo files, so the app is never
empty. Admin panel: open `#/admin` (or Profile → Admin panel). Default local
password is `admin123`.

### Environment (`wrangler dev`)

`wrangler.jsonc` sets `ADMIN_PASSWORD=admin123` for local development. Override
with `.dev.vars` (see `.dev.vars.example`, git-ignored):

```
ADMIN_PASSWORD=a-long-password
ADMIN_SECRET=a-long-random-signing-key
TELEGRAM_BOT_TOKEN=123456:ABC...
```

Without `TELEGRAM_BOT_TOKEN`, Telegram `initData` is not verified and rewarded
ads are **simulated** so the unlock flow is testable in a browser preview. Set
the token before going live.

## Telegram Mini App setup

1. Create a bot with [@BotFather](https://t.me/BotFather) and copy its token into
   the `TELEGRAM_BOT_TOKEN` secret.
2. Deploy to HTTPS (Telegram requires HTTPS).
3. In @BotFather: `/setmenubutton` → choose the bot → paste the deployed URL.
4. The Worker verifies `initData` with HMAC-SHA256 over the sorted
   `key=value` payload and binds the session to the Telegram account id, so
   unlocks follow the user across devices.

## Adsgram configuration

1. Create a mini app and rewarded ad blocks at
   [partner.adsgram.ai](https://partner.adsgram.ai).
2. Open the admin panel → **Ads & settings** and paste up to six block ids, one
   per slot. Empty slots fall back to the first block id.
3. Choose how many ads unlock a file (1–6). The product default is 6.

The SDK is loaded from `https://sad.adsgram.ai/js/sad.min.js` and initialised
once per block id, as the Adsgram docs require.

## Deploy to Cloudflare

```bash
npm run build                                   # dist/ + dist-worker/index.js
wrangler d1 create vaultgram
wrangler r2 bucket create vaultgram-files
wrangler d1 execute vaultgram --remote --file=./schema.sql
# point wrangler.jsonc at the created database id, then deploy dist-worker/index.js
```

Set `ADMIN_PASSWORD`, `ADMIN_SECRET` and `TELEGRAM_BOT_TOKEN` with
`wrangler secret put` instead of keeping them in `wrangler.jsonc`, and remove the
`vars` block before publishing.

## Project layout

```
worker/          Cloudflare Worker API (D1 + R2), session + initData verification
src/             React mini app (pages, components, styles)
public/covers/   Generated SVG folder art
scripts/         Cover generator and Worker bundler
schema.sql       D1 schema (the Worker also applies it idempotently)
```

## Live deployment

- App (published preview): https://site-9341ed6120fe436e8c84133a7e8312ad.freebuff.page
- Admin panel: append `/#/admin`
- Hosting: Freebuff Sites (Cloudflare Worker + D1 `DB` + R2 `FILES`)

The admin password used by the deployment is stored as a Sites secret and is
deliberately **not** included in this archive. Locally the fallback password is
`admin123`; set `ADMIN_PASSWORD` before sharing a deployment.

## Scripts

| Command | Purpose |
| --- | --- |
| `npm run dev:api` | Worker + local D1/R2 (Wrangler) |
| `npm run dev` | Mini app with HMR (proxies `/api`) |
| `npm run build` | Build `dist/` and `dist-worker/index.js` |
| `npm run typecheck` | Typecheck app + Worker |
| `npm run covers` | Regenerate folder cover art |
| `node scripts/api-test.mjs` | 22 API checks (ads, gate, admin CRUD) |
| `node scripts/verify-deploy.mjs` | Check a deployed URL |

`screenshots/` contains reference renders of the finished UI.
