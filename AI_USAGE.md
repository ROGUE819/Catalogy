# AI usage

## Tools & models
- **GitHub Copilot** (agent mode in VS Code), using **Claude Opus 5.5** as the model.
- Xcode and the iOS Simulator for building, running and checking the app by hand. No other AI tools were used.

## How I worked with the agent
- I gave it the full brief and an `AGENTS.md` with rules (clear boundaries, tests for the critical path, no secrets), then worked in short loops: prompt → read the diff → run the tests → run the app → push back.
- I treated its output like a pull request from a junior colleague: nothing was accepted without the tests passing and a look at the running app.
- When it was wrong, I asked it to explain the cause before fixing it, so the fix went in the right layer (see "Where the AI got things wrong").

## Agent instruction files
- [`AGENTS.md`](AGENTS.md): conventions given to the agent (architecture boundaries, testing, no secrets).

## Plan / spec
1. Pick the stack: iOS (SwiftUI) + Node/TS.
2. Backend first, with ports and adapters: `ProductSource` and `EnquiryNotifier` interfaces, `CatalogService` for rules, a thin Express layer.
3. Test the backend's critical path (featured, category split, search, enquiry validation/delivery, upstream failure).
4. iOS: models mirroring the backend contract → `CatalogAPI` protocol → view models → views. Unit-test the view models, plus one end-to-end UI test.
5. Docs: README, DECISIONS, AI_USAGE.

## Key prompts (paraphrased, in order)
1. **Kick-off:** "Here is the full challenge brief. Build it in this repo: an iOS SwiftUI app, a Node/TypeScript backend, and Fake Store as the product source. Keep the three clearly separated so the data source can be swapped. Write down any assumptions where the criteria are unclear."
2. **Architecture check:** "Before writing more code, show me how swapping Fake Store for another provider, or SMTP for SES, would work. Which files would change? The app must never call Fake Store directly."
3. **Tests:** "Cover the critical path: featured products, the category split, search, enquiry validation and delivery, and what happens when the upstream API is down. Add one end-to-end UI test: home → search → product → enquiry → thank you."
4. **Review feedback:** "Images don't load, and the view models and screens are all in one file. Fix the images without the app calling the third party, and split everything into one type per file."
5. **UI pass:** "Improve the home, category and product screens, and add loading and error states, a splash screen and an app icon. Keep the styling in one place so it's easy to reskin."
6. **Data sanity:** "The 'Top rated' section shows products rated 2.1. Fix it so the label is true."
7. **Criteria audit:** "Check the project against each of these five criteria and tell me honestly where it falls short."
8. **Hardening:** "What about error handling and edge cases? Do we have unit tests for them? Is there anything useful we can add that isn't in the brief? Also show prices in ₹ instead of $."
9. **Release check:** "Is this good enough to send to a recruiter? What would they see if they cloned it right now?"

## Where the AI got things wrong (and how it was caught)
- **Wrong test expectation**: the agent expected product 6 in the top-rated fallback, but products 1 and 6 tie at 3.9 and the tie-break (rating count) correctly picks 1. A failing test caught it; the test was fixed, not the code.
- **Unsupported deployment target**: the project template targeted iOS 27.2, so the app couldn't run on most simulators. Lowered to iOS 17 (the minimum for `@Observable`).
- **TLS failure in the local environment**: the first live smoke test returned 502 because of `SELF_SIGNED_CERT_IN_CHAIN` (network TLS inspection). The typed `UpstreamError` mapping made the cause clear in the logs. Fixed with `NODE_OPTIONS=--use-system-ca` and documented it.
- **Images loaded from the third party:** the first version sent the app straight to `fakestoreapi.com` for images, which broke the "only talk to our backend" boundary. I spotted it when images didn't load and had it routed through a backend image proxy.
- **"Top rated" wasn't top rated:** the configured featured ids included products rated 2.1 and 2.9. I spotted it on the home screen and changed the config, not the code.
- **₹ as just a symbol swap would have shown wrong prices:** changing only the symbol would show $109.95 as ₹109.95. I made sure the conversion happens in the backend at a configured rate, with that assumption documented.

## Review notes (what I checked myself)
- **Tests run after every change:** backend `npm test` (61 tests), iOS unit tests (23), and the end-to-end UI test on an iOS 17.2 simulator. All pass.
- **Boundaries:** confirmed the app only calls our backend (`HTTPCatalogAPI`), including for images, and that Fake Store's data format appears only in `FakeStoreProductSource.ts`.
- **Live API:** called `GET /api/products/12` against the running backend and got `"price":9519,"currency":"INR"` ($114 × 83.5), so the conversion works end to end.
- **Error paths:** checked that upstream failures return a generic 502 without internal details, and that invalid enquiries return field-level errors the app shows inline.
- **Security basics:** checked that `.env` is excluded from git, that no secrets are committed, that the email subject strips line breaks (header injection), and that the image proxy only fetches http(s) URLs.
- **Repo hygiene:** `git status` showed leftover draft files (`*.new.*`, `*.next.*`, old `Components.swift`/`Screens.swift`). Deleted them and rebuilt to confirm nothing depended on them.
- **Ownership:** I can explain every file and decision in `DECISIONS.md`. Anything I didn't understand, I asked the agent to explain before keeping it.

## Time spent
Approximate, over two sessions (one evening, then most of the next day).

| Phase | Time | What it covered |
|---|---|---|
| Planning | 45 min | Reading the brief, choosing the stack, writing `AGENTS.md`, listing assumptions |
| Building | 3 h 15 min | Backend, iOS app, image proxy, file split, UI pass, ₹ pricing |
| Testing | 1 h 30 min | Writing and fixing tests, simulator/UI-test issues, live API checks |
| Reviewing | 1 h 30 min | Reading diffs, checking the running app, criteria audit, docs, repo clean-up |
| **Total** | **~7 h** | |

**On the 2–3 hour guideline:** I went over it on purpose. The core brief (backend with a swappable product source, iOS app covering every acceptance criterion, critical-path tests, docs) took about **3 hours**. The rest was extra I chose to add, kept separate so it's easy to judge:
- **Review fixes:** image proxy, so the app never calls Fake Store directly; splitting files to one type per file.
- **Polish:** UI pass, splash screen, app icon.
- **Hardening:** edge cases, ₹ pricing, and the tests going from 32 to 61 (backend) and 12 to 23 (iOS).

If I had stopped at 3 hours, the app would have worked end to end. It would have lacked the image proxy, the hardening and the UI polish.

## Iteration 2 (after review)
- **Images never loaded.** The images came from `fakestoreapi.com` directly, so the iOS app was calling the third-party host, against the brief. Fix: added a backend image proxy (`GET /api/products/:id/image`) with an in-memory cache, and the API now rewrites `imageUrl` to it. Clients now only talk to our backend.
- **Clustered files.** All view models and screens were in single files. Split them into one type per file (Models, ViewModels, Views/Components, Views/Screens, Theme) and the tests into one file per subject.
- **UI refresh.** Featured carousel with rank badges, category chips with icons, shimmer placeholders, card-style detail page, inline form validation and an animated thank-you screen. All styling tokens live in `Theme.swift`.
- **AI mistake caught:** while splitting files, `Product.swift` ended up empty (0 bytes), and the build failed with "cannot find type 'Product'". Caught it by checking file sizes, then rewrote the file.
- **AI mistake caught:** the UI test failed because `.env` had `EMAIL_TRANSPORT=smtp` with no SMTP server running. The backend correctly returned 502, so I documented this in the README troubleshooting table.

## Iteration 3 (UI review)
- Reviewed screenshots. The curated "top rated" ids (`1,4,9,13,18`) included products rated 2.1 and 2.9, which contradicted the "Top rated" label. Changed the config to `12,3,18,5,19` (all rated 4.5+, from 4 different categories).
- Added a branded launch screen (static `UILaunchScreen` in `Info.plist`) and a matching animated `SplashView`, so the two hand off without a visual jump. UI tests skip it with `-skipSplash`.
- App icon is generated from code (`tools/generate-icons.swift`), so it is reproducible and easy to change once the real brand assets arrive.
- Caught a stale editor buffer re-creating the deleted `ViewModels.swift`; removed it.

## Iteration 4 (hardening & currency)
- **Prompt:** "What about error handling and other edge cases? Unit tests? Anything not in the doc we can add? Also make the currency ₹ instead of $."
- **Currency decision:** Rather than just changing the symbol in the app (which would show $109.95 as ₹109.95, a wrong price), conversion lives in the backend as a `ProductSource` decorator with a configured rate. The app only formats, using `en_IN` grouping. I checked the trade-off (fixed rate) and documented it in DECISIONS.md.
- **Edge cases added:** id validation (400), 413 for large bodies, a general API rate limit, an image-proxy SSRF guard plus bounded cache, fail-fast config, offline/timeout/429 messages in the app, protection against stale search responses, double-submit protection, and phone/message validation mirrored from the backend.
- **AI mistake caught:** the agent's simulator auto-pick chose an iOS 15.2 device (below the iOS 17 target), so the test run failed. Re-ran on an iOS 17.2 simulator.
- **AI mistake caught:** the agent tried to start a second backend while one was already on port 3000 (`EADDRINUSE`). Checked with `lsof` and used the running instance.
- **Cleanup:** leftover `*.new.*`/`*.next.*` drafts and pre-split `Views/Components.swift`/`Screens.swift` were found by `git status` and deleted. They were not in the build, but would have confused reviewers.
- Tests: backend 32 → 61, iOS unit 12 → 23, UI test still green.
- Checked by hand: ₹ prices with Indian digit grouping on the home, category, product and enquiry screens, and the inline phone validation message in the enquiry form.
