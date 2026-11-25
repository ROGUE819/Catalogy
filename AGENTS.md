# Agent instructions

- Monorepo: `backend/` (Node 22.15+, TypeScript, Express, Vitest) and `Catalogy/` (SwiftUI, iOS 17+, XCTest).
- Clients never call Fake Store directly; all product data goes through the backend.
- Keep boundaries: HTTP routes (`app.ts`) → services (`CatalogService`, `EnquiryService`) → ports (`ProductSource`, `EnquiryNotifier`). Provider-specific code lives only in adapters.
- The domain model (`src/domain/product.ts`) is the API contract; iOS `Models/Product.swift` mirrors it.
- Validate all external input (request bodies, upstream payloads) with zod.
- Every behaviour change needs a test. Run `npm test` in `backend/` and `CatalogyTests` in Xcode.
- Never commit secrets; add new config to `.env.example`.
- iOS: the Xcode project uses the JSON `project.xcproj` format, so new Swift files must be registered there. Keep one type per file.
