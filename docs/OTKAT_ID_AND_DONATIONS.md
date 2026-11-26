# OTKAT ID, online services and donations — implementation plan

## Product direction

Prioritize these releases: Hide and Seek, Survival, Driftline: Apex Circuit, then the five offline-first mini-game collections. Keep each game's offline core playable without login; sign-in unlocks cloud saves, global leaderboards, friends and social features.

## OTKAT ID — recommended zero-budget starting architecture

Use one Supabase project as the shared identity and data layer for the OTKAT Games website and all games:
- Supabase Auth for email/password and OAuth sign-in; one user UUID across all titles.
- PostgreSQL tables for profiles, game-specific leaderboard entries, cloud saves, friends, reports and donation/supporter flags.
- Row Level Security on every player-owned table; a player can edit only their own profile/save, and leaderboard writes must be validated server-side.
- Supabase Realtime for presence, chat and lobby events only after moderation, rate limits and abuse controls exist.
- Never put the Supabase service-role key in a browser, game build or Android APK. Client uses the public anon/publishable key with RLS.

Current published Free plan lists two active projects, 50,000 monthly active users, 500 MB database, 1 GB file storage and 5 GB egress. Free projects may pause after a week of inactivity. This is suitable for an MVP, not a guaranteed always-on production service. Keep backups/export procedures and expect to upgrade if users depend on it.

Official pricing: https://supabase.com/pricing
Free-project pause policy: https://supabase.com/kb/faqs/platform/free-project-pausing

## AI Team hosting is separate

Do not expose the current FastAPI/SQLite OTKAT AI Team backend publicly. It has no owner authentication or durable cloud database yet. A free Render web service can be used for a temporary preview, but it sleeps after 15 minutes of inactivity and its local filesystem is ephemeral; free Render Postgres expires after 30 days. First migrate persistence to managed Postgres, add owner-only authentication, secure secrets and backups, then connect a host.

Render free-tier limitations: https://render.com/docs/free

## Donations and payments

### First version: donation/support page

Start with a hosted creator page and a simple Support OTKAT button on the website and in each game's pause/settings screen. The button opens the payment provider's hosted checkout page; the game never handles card numbers. Do not promise in-game rewards for donations until verified payment webhooks and refund handling exist.

Boosty's official FAQ (updated December 2025) states 11.7% service/payment commission plus a separate withdrawal fee, mandatory creator KYC, card support in RUB/USD/EUR, RUB card withdrawals for Russian residents and USD/EUR card withdrawals for non-residents. It also warns that some foreign card payments can fail depending on the payment partner and 3-D Secure. This is a plausible first hosted donation page, but the creator must verify their own eligibility and payout route.

Boosty FAQ: https://boosty.to/boosty/posts/de1e6f32-3a80-4824-95bd-a264ff1b00aa

### Direct checkout later

YooKassa is oriented to Russian merchants and accepts Russian-issued cards; its current documentation lists only a limited set of foreign-issued cards (including Belkart, APRA, certain Tajikistan cards and MIR). Do not assume it accepts ordinary Visa/Mastercard cards issued anywhere in the world.

YooKassa accepted methods: https://yookassa.ru/docs/support/payments/accept-methods
YooKassa foreign-card limits: https://yookassa.ru/questions/q397/

Stripe can be considered only if the merchant is legally based in a Stripe-supported country and meets its KYC/business requirements. Russia is not on Stripe's supported-country list; Russian-issued cards are unlikely to work due to network restrictions.

Stripe supported countries: https://stripe.com/global
Stripe Russia/Belarus restrictions: https://support.stripe.com/questions/sanctions-on-russia-and-belarus

Do not route payments through another person's account or misstate country/residency. The correct processor depends on the actual payout country, legal status and bank account. Tax reporting remains the creator's responsibility.

## Release order

1. Build OTKAT ID and profile UI; keep offline play anonymous.
2. Add server-validated per-game leaderboards and cloud saves.
3. Add friends, invite codes, text chat and report/block controls.
4. Add realtime lobbies and multiplayer after server-authoritative game logic and anti-cheat.
5. Add hosted donation page and Support buttons; add payment webhooks and supporter cosmetics only after merchant verification.
6. Expand Driftline with original fictional 3D car models and a real 3D garage; do not ship unlicensed real-world badges, copied vehicle blueprints or branded superhero cars.

## Current status

- OTKAT ID is not implemented yet; this document records the recommended architecture, not a live identity service.
- No payment account, merchant profile, payout card or donation page has been connected.
- Existing Driftline is still a 2D top-down browser prototype. A 3D garage/model viewer is the next concrete milestone; it must not be described as a complete 3D racing game until driving, physics, tracks and camera are 3D too.