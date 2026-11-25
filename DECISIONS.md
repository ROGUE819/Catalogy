# Decisions & assumptions

## Assumptions (where the acceptance criteria were unclear)
1. **"I have chosen 5 products to be top rated"** means a merchandiser curates them. With no admin UI in scope, the choice is the `FEATURED_PRODUCT_IDS` config value. If it is empty or every id is invalid, the API falls back to the 5 highest-rated products. Unknown ids are skipped so a deleted product can't break the home page.
2. **"Top rated products for a category"** means the N highest-rated products in that category (`CATEGORY_TOP_RATED_COUNT`, default 3). The remaining products are listed below them as "additional products".
3. **Search** is case-insensitive and matches title, description and category name. With several words, every word must match. Search runs on an explicit Search button press or keyboard return, not as you type, as the criteria describe.
4. **Enquiry contact details** are name and email (required) plus phone and message (optional).
5. **"Sales inbox receives an email"**: locally this is Mailpit, a free fake SMTP inbox, so reviewers need no accounts. In production, SMTP settings point at the real provider.
6. **Prices are shown in Indian Rupees (₹).** Fake Store prices are USD, so the backend converts them at a fixed configured rate (`USD_TO_DISPLAY_RATE`, default 83.5) in `CurrencyConvertingProductSource`, a decorator around any `ProductSource`. The app formats ₹ with Indian digit grouping (₹1,23,456.50). Trade-off: a fixed rate is fine for a PoC; production would use a pricing/FX service or native INR prices from the catalogue.

## Edge cases handled
| Case | Behaviour |
|---|---|
| Upstream product API down, slow or returning bad data | 8 s timeout and zod validation → `UpstreamError` → generic 502. The app shows a retryable error. |
| Curated featured ids missing upstream | Skipped. If none are left, falls back to highest rated. |
| Unknown product/category | 404 (API) → "We couldn't find…" (app). |
| Malformed ids (`../`, spaces, >64 chars) | 400 before reaching the domain. The app also percent-encodes ids in paths. |
| Blank, whitespace or over-long search | Blank → empty list. >100 chars → 400. The app trims and caps at 100. |
| Out-of-order search responses | A stale response never overwrites a newer search or a clear. |
| Enquiry: invalid email/phone, over-long fields, whitespace-only optionals | Field errors from the backend (authoritative), mirrored inline in the app. Blank optionals are sent as absent. |
| Malformed JSON / oversized body | 400 / 413. |
| Double-tap submit / resubmit after success | Blocked in the view model. |
| Email delivery failure | 502 with a friendly retry message. Form contents are kept. |
| Abuse | 300 req/min per IP on the API, 10 enquiries per 15 min. The app shows a "too many requests" message on 429. |
| Offline / timeout on device | Distinct messages (`APIError.offline`, `.timeout`). |
| Image proxy | Only http(s) URLs (SSRF guard), image content types only, 5 MB cap, failures not cached, LRU-bounded cache (200 entries). |
| Invalid configuration | Server refuses to start, with a clear message (fail fast). |

## Dropped or simplified
- **No persistence of enquiries.** Email is the only record. Next step: save enquiries first, then send email (outbox pattern) so a delivery failure loses nothing.
- **Search and filtering run in memory** over a cached product list (Fake Store has about 20 products and no search endpoint). This is fine for a PoC; a real catalogue would use a search engine or database query behind the same `ProductSource` port.
- **No auth, admin UI or pagination**, which are out of scope for the MVP.
- **Basic styling.** The creative work is still in progress, so styling is centralised (`Theme.swift`, `Views/Components/`) to make reskinning cheap.

## How the design supports growth
- **Images** are proxied and cached by the backend (`ProductImageService`), so clients never call the provider and a CDN/S3 can replace it later.
- **Product data source** sits behind the `ProductSource` interface. Fake Store is one adapter (`FakeStoreProductSource`) that maps to our own domain model, so neither the clients nor the business rules ever see Fake Store's shape.
- **Email provider** sits behind the `EnquiryNotifier` interface (SMTP and console implementations). SES, SendGrid or a CRM would be a new class.
- **Business rules** (featured, top rated, search) live in `CatalogService` and `EnquiryService`, which don't depend on HTTP and are unit tested.
- **Composition roots** (`server.ts`, `ContentView`) are the only places that pick concrete implementations.
- **iOS** uses MVVM: views → view models → the `CatalogAPI` protocol. View models are tested with a stub, and the API base URL is configurable.
- **AWS-ready**: a stateless container with config from the environment fits ECS/App Runner, and SMTP can point at SES.
- **Security basics**: zod validation of input and upstream data, Helmet, a 10 kB body limit, rate-limited enquiries, a plain-text email body, CRLF stripped from the subject, and generic 5xx messages that don't leak internals.

## With another day
- Persist enquiries (Postgres/DynamoDB) and send email asynchronously from a queue (SQS).
- OpenAPI spec as the contract, with a generated Swift client.
- Image caching, pagination, accessibility pass, localisation.
- CI pipeline (GitHub Actions: backend tests and iOS build/test), plus IaC (CDK) for ECS + SES.
- Structured logging and request ids.
