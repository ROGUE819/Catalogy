# AI usage

> **Fill in the bracketed parts honestly.** Reviewers will ask about them.

## Tools & models
- GitHub Copilot (agent mode in VS Code), [model name]
- [Any others you used]

## Agent instruction files
- [`AGENTS.md`](AGENTS.md): conventions given to the agent (architecture boundaries, testing, no secrets).

## Plan / spec
1. Pick the stack: iOS (SwiftUI) + Node/TS.
2. Backend first, with ports and adapters: `ProductSource` and `EnquiryNotifier` interfaces, `CatalogService` for rules, a thin Express layer.
3. Test the backend's critical path (featured, category split, search, enquiry validation/delivery, upstream failure).
4. iOS: models mirroring the backend contract → `CatalogAPI` protocol → view models → views. Unit-test the view models, plus one end-to-end UI test.
5. Docs: README, DECISIONS, AI_USAGE.

## Key prompts / moments
1. Gave the agent the full challenge PDF and asked it to build the project in the existing repo.
2. [Your prompt about architecture or swappable data source / email]
3. [Your prompt about tests]
4. [...]

## Where the AI got things wrong (and how it was caught)
- **Wrong test expectation**: the agent expected product 6 in the top-rated fallback, but products 1 and 6 tie at 3.9 and the tie-break (rating count) correctly picks 1. A failing test caught it; the test was fixed, not the code.
- **Unsupported deployment target**: the project template targeted iOS 27.2, so the app couldn't run on most simulators. Lowered to iOS 17 (the minimum for `@Observable`).
- **TLS failure in the local environment**: the first live smoke test returned 502 because of `SELF_SIGNED_CERT_IN_CHAIN` (network TLS inspection). The typed `UpstreamError` mapping made the cause clear in the logs. Fixed with `NODE_OPTIONS=--use-system-ca` and documented it.
- [Anything you changed during your own review]

## Time spent
| Phase | Time |
|---|---|
| Planning | [ ] |
| Building | [ ] |
| Testing | [ ] |
| Reviewing | [ ] |
| **Total** | [ ] |

## Iteration 2 (after review)
- **Images never loaded.** The images came from `fakestoreapi.com` directly, so the iOS app was calling the third-party host, against the brief. Fix: added a backend image proxy (`GET /api/products/:id/image`) with an in-memory cache, and the API now rewrites `imageUrl` to it. Clients now only talk to our backend.
- **Clustered files.** All view models and screens were in single files. Split them into one type per file (Models, ViewModels, Views/Components, Views/Screens, Theme) and the tests into one file per subject.
- **UI refresh.** Featured carousel with rank badges, category chips with icons, shimmer placeholders, card-style detail page, inline form validation and an animated thank-you screen. All styling tokens live in `Theme.swift`.
- **AI mistake caught:** while splitting files, `Product.swift` ended up empty (0 bytes), and the build failed with "cannot find type 'Product'". Caught it by checking file sizes, then rewrote the file.
- **AI mistake caught:** the UI test failed because `.env` had `EMAIL_TRANSPORT=smtp` with no SMTP server running. The backend correctly returned 502, so I documented this in the README troubleshooting table.
