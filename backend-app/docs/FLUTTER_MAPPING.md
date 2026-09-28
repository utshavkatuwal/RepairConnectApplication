# Flutter ↔ Laravel contract map (§52)

Implementation: `backend-app/`. This file maps the two naming worlds.
Translation lives in `lib/core/network/api_mapper.dart` — never in widgets.

## Roles

| API (backend truth) | Flutter domain |
|---|---|
| `customer` | `CUSTOMER` |
| `technician` | `TECHNICIAN` |
| `admin`, `super_admin` | `ADMIN` (super_admin collapses client-side; server still distinguishes) |

Outbound (register): `apiRole()` lowercases. Inbound: `normalizeRole()`.

## Job / request statuses

| API | Flutter | Notes |
|---|---|---|
| `requested`, `searching`, `offered` | `REQUESTED` | open pool, no job row |
| `accepted` | `ACCEPTED` | job exists |
| `scheduled` | `SCHEDULED` | Flutter-side plan state |
| `technician_arriving` | `EN_ROUTE` | GPS en route |
| `arrived` | `ARRIVED` | Flutter-side |
| `in_progress` | `IN_PROGRESS` | work started |
| `completed` | `COMPLETED` | reviews unlock |
| `cancelled` | `CANCELLED` | terminal, reason required |
| `disputed` | `DISPUTED` | terminal-ish, reason required |
| anything else | `RAW.toUpperCase()` | visible but inert (no transitions match) |

## Catalog

Flutter "services/categories" map to backend **specialties**
(`GET /api/v1/specialties`, DB-driven). There is no services table by
design — a service request carries `specialty_id + title + description`.

## Create request

Flutter `BookingsRepository.createRequest` builds
`serviceRequestBody()`: `specialty_id` (= selected service id), `title`
(service name or first 40 chars), `description`, `address` with the
`[lat, lng]` suffix split into real `latitude`/`longitude`,
`scheduled_at` from preferred date.

## Auth envelope

Backend: `{success,message,data:{token,user}}` (no refresh tokens —
Sanctum bearer; `refresh_token` reads are null-safe). `/users/me` →
`GET /api/v1/auth/me`. 401 → client wipes secure storage → login.

## Bookings, chat, payments, reviews

- Booking detail: `GET /api/v1/jobs/{id}` (Flutter `ApiRoutes.bookings`
  points at `/jobs`); transition:
  `POST /api/v1/jobs/{id}/transition {status,reason?}`; my bookings:
  `GET /api/v1/jobs?mine=1`.
- Technicians directory: `GET /api/v1/technicians`
  (`q,category_id,available,lat,lng,page,per_page`, distance-sorted).
- Conversation: `GET /api/v1/jobs/{id}/conversation`.
- Payments: `POST /api/v1/payments` with `Idempotency-Key` header +
  body `idempotency_key`; status: `GET /api/v1/payments/{id}`;
  history: `GET /api/v1/jobs/{id}/payments`; invoice:
  `GET /api/v1/jobs/{id}/invoice` (404 until a successful payment exists).
- Reviews: `GET /api/v1/reviews?booking_id|technician_id`,
  `POST /api/v1/reviews {job_id,rating,comment?}` (unique per
  job, COMPLETED only — server enforces 409/422).
- Auth: `forgot-password` / `reset-password` (email + token +
  confirmation), OTP `verify/send` + `verify {email,code}`,
  `refresh` (rotates the calling token).
- Notifications: `GET /api/v1/notifications`, `POST .../{id}/read`.

## Live check

`flutter test --dart-define=BACKEND_LIVE=true test/backend_live_test.dart`
against `php artisan serve` (127.0.0.1:8000) with dev seeds. Switch the app
with `.env`: `USE_FAKE_BACKEND=false`, `API_BASE_URL=http://127.0.0.1:8000`
(`http://10.0.2.2:8000` on the Android emulator).
