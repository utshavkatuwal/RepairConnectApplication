# RepairConnect Backend Security Contract (§14)

Flutter enforces UX-level validation; **this document is authoritative** for
the Laravel/MySQL backend. Implement all items before production.

## Auth
- Passwords: `Hash::make` (bcrypt, cost 12). Never store/log plaintext.
- Tokens: Laravel Sanctum personal tokens, 24h access + 30d refresh with
  rotation. `POST /auth/refresh` validates refresh token, revokes old.
- `GET /users/me` revalidates the token on every app cold start.
- Failed refresh or 401 → client wipes secure storage (already implemented).

## Authorization (middleware + policies, never trust client role)
- `auth:sanctum` on all `/api/v1/*` except login/register/forgot.
- `role:customer|technician|admin` middleware reading the **server-side**
  user record, not request input.
- `verified-technician` gate on accept/transition endpoints.
- Policies: BookingPolicy (participant-only show/update), ReviewPolicy
  (participant + COMPLETED only), PaymentPolicy (customer owns booking;
  refunds admin-only). Every controller authorizes via `$this->authorize`.

## Validation (FormRequests, authoritative)
- Mirror client rules server-side: email RFC + unique, password min 8 +
  letter + digit (confirmed), phone, OTP 6-digit + attempts throttled,
  description 10–2000 chars, rating 1–5, coordinates ranges, amount > 0.
- Unknown enum values (`role`, `status`) rejected with 422 + field errors
  in the standard envelope `{success:false,message,code,errors}`.

## Job/payment integrity
- Transitions validated against the same table as
  `JobMachine` (REQUESTED→…→COMPLETED, CANCELLED/DISPUTED terminals).
  Record every move in `job_status_history` inside a DB transaction.
- Cancel/dispute require `reason` (min 5). Completed reopens only via dispute.
- Payments: `idempotency_key` UNIQUE column; provider webhooks verified by
  signature **before** marking SUCCEEDED; never accept client-reported success.
- Reviews: UNIQUE(booking_id); only when booking COMPLETED by participant.

## Injection / XSS / CORS / rate limits
- Eloquent bindings only (no raw SQL with interpolation). Mass assignment
  guarded via `$fillable`.
- Escape output in admin views; `strip_tags` on free text + length caps.
- CORS: allowlist app origins only. Throttle: `throttle:5,1` on auth/OTP,
  `throttle:30,1` on payments, `throttle:60,1` default api.

## Uploads (§19)
- Validate MIME allowlist (jpeg/png/webp/pdf) + 10MB max server-side.
- `storeAs` with generated UUID names on a private disk; serve via signed
  URLs. Never trust client paths. Keep only metadata in DB.

## Audit + secrets
- Write `audit_logs(actor_id, action, target_type, target_id, meta)` on all
  admin writes, verification decisions, refunds, suspensions.
- Secrets only in server `.env` (DB, FCM, payment keys). The Flutter
  `.env.example` contains no secrets; CI must fail if a secret pattern is
  committed (add a pre-commit grep for `sk_live`, `BEGIN PRIVATE KEY`).
