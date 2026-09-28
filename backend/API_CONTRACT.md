# RepairConnect backend — implementation index

The live implementation is `backend-app/` (Laravel 13 + Sanctum, 24/24
tests green, 21/21 HTTP E2E green on a real database). This folder keeps
the original design notes:

- `database/schema.sql` — early schema sketch (superseded by
  `backend-app/database/migrations/`, which is authoritative).
- `SECURITY.md` — original security notes (superseded by
  `backend-app/docs/` + `backend/SECURITY.md` still applies as policy).

Canonical references (all real, all tested):

- Routes: `backend-app/routes/api.php` (`/api/v1/...`)
- Docs: `backend-app/docs/` (architecture, database, api,
  authentication, jobs, payments, technician-verification,
  local-development, environment) + `FLUTTER_MAPPING.md` (Flutter ↔
  API naming bridge: snake_case vs SCREAMING).
- Keys: `.env.example` files (Flutter root + `backend-app/`). No
  secrets committed. Local runs sqlite by default; MySQL 8 is the
  required local DB (`DB_CONNECTION=mysql`, see local-development doc).

Flutter integration: `USE_FAKE_BACKEND=false` +
`API_BASE_URL=http://127.0.0.1:8000` (`http://10.0.2.2:8000` on the
Android emulator). Live check:
`flutter test --dart-define=BACKEND_LIVE=true test/backend_live_test.dart`.
