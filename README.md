# RepairConnect™ — Service Marketplace

Production Flutter marketplace (Customer / Technician / Admin) built on the
**approved Figma/Stitch design as visual source of truth** — deep-navy
`#0A1A2E`, surgical teal `#2AB6CE`, off-white, 12/10/6px radii.

## Architecture — Feature Clean
```
lib/app/ (app.dart, router.dart, providers.dart)
lib/core/ (auth/role_guards, constants, config/env, errors, network/dio_client+connectivity,
  security/input_safety, storage/session_store, theme, utils/validators, widgets/rc_widgets+offline_banner+location_picker)
lib/shared/models/ (User, Technician, Category, Service, Request, Booking, Message,
  Notification, Payment, Review + Address, Transaction, Invoice, Complaint, Favorite, Attachment, AuditLog)
lib/features/auth|customer|technician|admin|marketplace|bookings+domain/job_machine|
  chat|payments+domain/payment_machine|reviews|design_system|landing/
lib/services/location|chat|notifications|payments/
lib/widgets/ + lib/theme.dart (approved board preserved 1:1)
backend/database/schema.sql + backend/API_CONTRACT.md + backend/SECURITY.md
```
- State: **Riverpod** only (`select` where hot). No mixing.
- Nav: **go_router** + centralized `guardRoute` (unauth→login; tech/admin gates).
- Network: **Dio** (`ApiResponse` envelope + `Paged<T>`, bearer + single-flight 401 refresh, one retry, idempotency headers).
- Storage: `flutter_secure_storage` (tokens) + `shared_preferences` (role/profile flags).
- Backend: Flutter → REST (`/api/v1/...`) → Laravel → MySQL. Never direct DB.
- Location/Chat/Push/Payments behind swappable abstractions (Fake dev ↔ Api prod, no UI change).
- Appearance: dark blueprint default + light surfaces per Figma spec (`ThemeMode`, persisted). Separator lives in Profile (switch) and header icons on Landing/Home/Dashboards; screen text uses mode-aware tokens. The `/design-system` board stays dark intentionally.
- Navigation: every non-root page has a back arrow (`RcBackAppBar` pops the stack, else a role-aware fallback).

## Product map (§5–8)
- Public: splash (branded, 8s fallback) → landing → login/signup+role/forgot/verify-OTP/reset.
- Customer: home (badge, active booking, location chip, categories, techs) → discovery (keyword/category/rating/available/near-me) → categories/services → tech profile (+reviews) → request (GPS picker) → booking (role-gated transitions, history, chat, payment, review) → history/invoices → notifications (type filters).
- Technician: dashboard (today/active/earnings) → requests (verification gate) → profile/earnings/availability/register.
- Admin: dashboard → users/verify/services/jobs/payments(+refunds)/complaints/audit.
- Design system: `/design-system` preserves the approved board.

## Setup
Flutter 3.47.5 / Dart 3.13.4.
```
cp .env.example .env   # API_BASE_URL, MAP_PROVIDER, MAP_TILE_URL, USE_FAKE_BACKEND=true
flutter pub get
flutter analyze        # expect: No issues found!
flutter test           # 18 files, all passing
flutter run -d chrome  # or: flutter run (Android emulator, lib/main.dart)
```
Backend prod: scaffold Laravel per `backend/API_CONTRACT.md`, import
`backend/database/schema.sql`, harden per `backend/SECURITY.md`
(bcrypt-12, Sanctum rotation, policies, throttles, signed uploads, audit_logs).
Then set `USE_FAKE_BACKEND=false` + production `API_BASE_URL` in `.env`.

> LIVE STATUS: `backend-app/` is a runnable Laravel 13 + Sanctum API
> (migrations, services, policies, events, wallet ledger, PHPUnit 24/24).
> Serve: `php backend-app/artisan serve --host=127.0.0.1 --port=8000`
> (SQLite dev DB; MySQL 8 required per `backend-app/docs/local-development.md`).
> Full HTTP E2E (register → verify → accept → lifecycle → payment-honesty →
> chat → review → withdrawal): 21/21 green. Naming bridge:
> `backend-app/docs/FLUTTER_MAPPING.md`.

## Testing & build
- Unit: state machines (jobs/payments), validators, guards, filters, envelope/paged, geo, notifications, earnings.
- Widget: AsyncStateView states, RcButton/Field, design-system render, router boot.
- Flows: booking lifecycle, tech gate, payment verify, auth routing, chat persist, cancellation.
- `flutter build web` verified. `flutter build apk` needs Android SDK (CI).
- Deps pruned (`cupertino_icons`, `intl` removed — unused). No TODOs/prints.

## Security
Server-authoritative everything; client mirrors for UX. Sanitized inputs,
normalized emails, upload allowlist + safe filenames, secret redaction helper,
`.env.example` only — no secrets committed (`.gitignore` covers `.env`, keys,
firebase configs, build outputs).

## Deployment
Web: `flutter build web` → serve `build/web` over HTTPS. Android: bump
`version` in `pubspec.yaml`, `flutter build appbundle`. Configure FCM +
`MAP_TILE_URL` + API URL via `--dart-define` or `.env` per environment.
