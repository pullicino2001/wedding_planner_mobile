# Wedding Planner Mobile

## SNAPSHOT
**Status:** Active
**Last worked on:** 2026-05-06
**What works:** Full app + new Day Of tab — Schedule (running order), Team (roles + brief export), Checklist (church/venue items); all backed by Google Sheets (lazy tab creation); clean flutter analyze
**What's broken / in progress:** Day Of untested on device
**Next step:** Test Day Of on device; push to Firebase

## DECISIONS
- Japandi × Material You design system: teal palette, Cormorant Garamond + GoogleSans, 28px cards, pill nav
- Riverpod for state management; GoRouter for navigation
- Google Sheets as primary data backend (not a database)
- Home widget taps deep-link to /home/timeline

## DECISIONS
- Day Of tab: lazy sheet tab creation (_ensureTabExists) so existing spreadsheets not broken
- Day Of brief export: plain text via share_plus (more practical than image for WhatsApp/email)

## LOG
- 2026-05-06 Day Of section added — Schedule, Team, Checklist + brief export per person
- 2026-05-03 distribute.sh + guests + settings updated
- 2026-04-27 overview, venue detail, timeline, budget screens updated
- 2026-04-04 Gemini service, vendor screens, pubspec deps finalised
- 2026-04-01 assets dir added; onboarding + vendor screens scaffolded
- 2026-03-31 Project initialised; core theme, models, providers, services created
