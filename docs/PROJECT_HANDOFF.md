# OTKAT Games — project handoff

The full cross-project work report (including OTKAT AI Team, GitHub integration, provider status, Android build, OTKAT ID, monetization and next steps) is maintained in the OTKAT AI Team repository:

[Open the consolidated report](https://github.com/OTKAT628/otkat-ai-team/blob/feature/android-chat-control-ui/docs/DAILY_REPORT_2026-11-27.md)

## OTKAT Games links

- [Published website](https://otkat628.github.io/otkat-games/)
- [Games catalog](https://otkat628.github.io/otkat-games/games/)
- [Apps catalog](https://otkat628.github.io/otkat-games/apps/)
- [GitHub source archive](https://github.com/OTKAT628/otkat-games)
- [Driftline source](https://github.com/OTKAT628/otkat-games/tree/main/web/driftline)
- [Mini-app collection plan](https://github.com/OTKAT628/otkat-games/blob/main/docs/APP_COLLECTIONS.md)
- [OTKAT ID and donations plan](https://github.com/OTKAT628/otkat-games/blob/main/docs/OTKAT_ID_AND_DONATIONS.md)

The website deployment was confirmed successful by [GitHub Actions run #45908399979](https://github.com/OTKAT628/otkat-games/actions/runs/45908399979).


## Mobile 100 implementation update — 2026-11-27

Work branch: `feature/15-new-app-games`.

- 15 standalone browser-game prototypes are present.
- Mobile 100 collections 01–03 contain 30 mini-games.
- Mobile 100 collection 04 contains 60 short challenges across 12 base mechanics (five goal/configuration variants per mechanic).
- Total catalog plan represented in this branch: 105 new game entries (15 standalone + 90 mini-game entries).
- Updated apps catalog, offline service-worker cache, mechanic registry, and CI syntax/content checks.
- The fourth collection uses a data-driven browser engine and local device records. It is a prototype collection, not a store-ready release.
- Latest known branch commit after this handoff edit will need fresh CI verification. The GitHub connector did not return workflow/status records for the latest commits; this is not evidence of a passing build.
- Manual playtesting on real phones, accessibility, difficulty balancing, and bug fixing remain before publishing to `main`.

Useful links:
- [Apps catalog source](../web/apps/index.html)
- [Mobile 100 collection 04](../web/apps/mobile-100-04/index.html)
- [Mechanic registry](GAME_MECHANIC_REGISTRY.md)
