# Catalogy

Proof of concept for a product catalogue: an **iOS app (SwiftUI)** backed by a **Node.js + TypeScript API**. Product data and images come from the [Fake Store API](https://fakestoreapi.com/), always through the backend. Enquiries are emailed to a sales inbox.

```
iOS app (SwiftUI) ──HTTP/JSON──▶ backend (Express, TS) ──▶ ProductSource       ──▶ Fake Store API
                                                     ├──▶ ProductImageService ──▶ (image proxy + cache)
                                                     └──▶ EnquiryNotifier     ──▶ SMTP (Mailpit locally)
```

## Stack choice
- **iOS / Swift + SwiftUI**: a native mobile app fits customers browsing on a phone. SwiftUI + Observation needs no third-party dependencies, so a fresh clone builds without package resolution.
- **Node.js / TypeScript**: one typed language across the backend and its tests, a small dependency tree, and easy to containerise for AWS (ECS/Fargate, App Runner or Lambda).

---

## Running on a new machine

### Prerequisites
| Tool | Version | Check |
|---|---|---|
| macOS | one that runs Xcode 27 | `sw_vers` |
| Xcode | **27.2+** (the project uses Xcode 27's `project.xcproj` format) | `xcodebuild -version` |
| iOS Simulator | iOS 17+ runtime (Xcode → Settings → Components) | `xcrun simctl list runtimes` |
| Node.js | **22.15+** (for `--use-system-ca`) | `node -v` |
| Docker Desktop | optional; needed only for the fake email inbox | `docker info` |

No accounts, API keys or paid services are needed.

### Step 1: Clone
```sh
git clone <repo-url> catalogy
cd catalogy
```

### Step 2: Start the backend (choose one option)

**Option A: Docker** (recommended; includes a fake sales inbox)
```sh
docker compose up --build
```
- API health: http://localhost:3000/health
- **Sales inbox** (where enquiry emails arrive): http://localhost:8025

**Option B: Node, without Docker**
```sh
cd backend
cp .env.example .env
# Without an SMTP server, edit .env and set EMAIL_TRANSPORT=console.
# Enquiry emails will then be printed in this terminal instead.
npm install
npm run dev
```

Check that it works: `curl http://localhost:3000/api/categories` should return 4 categories.

### Step 3: Run the iOS app
1. Open `Catalogy/Catalogy.xcodeproj` in Xcode.
2. **Signing:** select the **Catalogy** target → *Signing & Capabilities* → set **Team** to your own (a free Personal Team works) or *None*. The Simulator doesn't need a paid account.
3. Choose an iPhone simulator (e.g. *iPhone 17*) and press **Run** (⌘R).

The app talks to `http://127.0.0.1:3000/api` by default. The Simulator shares your Mac's network, so this reaches the backend from Step 2.

### Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| App shows "Can't reach the server" | Backend not running | Start Step 2, then pull to refresh |
| Backend logs `SELF_SIGNED_CERT_IN_CHAIN` | Corporate proxy / TLS inspection | `npm run dev` already passes `--use-system-ca`; make sure Node is 22.15+ |
| Enquiry shows "downstream service is unavailable" | `EMAIL_TRANSPORT=smtp` but no SMTP server | Use Docker (Option A) or set `EMAIL_TRANSPORT=console` |
| Port 3000 already in use | Another process | Set `PORT=3001` in `backend/.env`, and set `API_BASE_URL=http://127.0.0.1:3001/api` under Xcode → *Edit Scheme* → *Run* → *Environment Variables* |
| Xcode can't open the project | Xcode older than 27 | Install Xcode 27.2+ |
| "No team selected" signing error | The original author's team id is in the project | See Step 3.2 |
| Running on a **physical iPhone** | `127.0.0.1` refers to the phone itself | Set `API_BASE_URL=http://<your-mac-LAN-IP>:3000/api` in the scheme (plain HTTP to a LAN IP would also need an ATS exception, which is not set up) |

---

## Tests
```sh
cd backend && npm test        # Vitest + Supertest: domain rules, adapter, HTTP API, image proxy, enquiry email
```
```sh
cd Catalogy
# Unit tests (view models, decoding), with no backend needed:
xcodebuild test -project Catalogy.xcodeproj -scheme Catalogy \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CatalogyTests
# End-to-end UI test (home → search → product → enquiry → thank you) needs the backend from Step 2:
xcodebuild test -project Catalogy.xcodeproj -scheme Catalogy \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CatalogyUITests
```

## API
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/products/featured` | 5 curated "top rated" products (home) |
| GET | `/api/categories` | Category list |
| GET | `/api/categories/:id/products` | `{ category, topRated, others }` |
| GET | `/api/products?search=term` | Search |
| GET | `/api/products/:id` | Product details |
| GET | `/api/products/:id/image` | Product image (proxied and cached by the backend) |
| POST | `/api/enquiries` | `{ productId, name, email, phone?, message? }` → email to sales |

## Project structure
```
backend/src
  domain/        Product & Category model (the API contract)
  products/      ProductSource port, FakeStore adapter, CatalogService, ProductImageService
  enquiries/     Validation schema, EnquiryService, EnquiryNotifier port + SMTP/console adapters
  http/          Presenters (shape domain → HTTP responses)
  app.ts         Express routes & error mapping; server.ts = composition root
Catalogy/Catalogy
  Models/        One type per file, mirroring the API contract
  Networking/    CatalogAPI protocol, HTTP implementation, APIError
  ViewModels/    One @Observable view model per screen
  Views/Theme    Brand tokens (colours, spacing, radii), the single place to reskin
  Views/Components  Reusable UI (tiles, cards, search bar, form fields…)
  Views/Screens  Home, Category, Search results, Product detail, Enquiry, Thank you
```

## Configuration
All backend settings are in [`backend/.env.example`](backend/.env.example) (featured product ids, cache TTL, SMTP, sales inbox address). No secrets are committed.

See [DECISIONS.md](DECISIONS.md) and [AI_USAGE.md](AI_USAGE.md).
