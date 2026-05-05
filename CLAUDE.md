# Wedding Planner Mobile

## SNAPSHOT
**Status:** Active
**Last worked on:** 2026-05-03
**What works:** Full app — overview, guests, budget, timeline, vendors, settings; Google auth + Sheets/Drive/Calendar/Gemini services; home-screen widget; local notifications; TestFlight distribution script
**What's broken / in progress:** Unknown — guests + settings screens touched last (May 3); no git history to diff against
**Next step:** Confirm what was last changed in guests/settings screens

## DECISIONS
- Japandi × Material You design system: teal palette, Cormorant Garamond + GoogleSans, 28px cards, pill nav
- Riverpod for state management; GoRouter for navigation
- Google Sheets as primary data backend (not a database)
- Home widget taps deep-link to /home/timeline

## LOG
- 2026-05-03 distribute.sh + guests + settings updated
- 2026-04-27 overview, venue detail, timeline, budget screens updated
- 2026-04-04 Gemini service, vendor screens, pubspec deps finalised
- 2026-04-01 assets dir added; onboarding + vendor screens scaffolded
- 2026-03-31 Project initialised; core theme, models, providers, services created
