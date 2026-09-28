# API (`/api/v1`)

Envelope success: `{success:true,message,data}` (+`meta` on paginated lists).
Error: `{success:false,message,errors?}` with correct codes (200/201/401/
403/404/409/422/429/500/503). Never 200 for business failures.

Auth: register, login, logout, me, forgot/reset-password. Devices + user
notifications (list/read). Customer: service-requests CRUD-ish, reviews,
complaints. Technician: profile, documents, availability, location,
technician/requests (eligible nearby), wallet (+ledger), withdrawals.
Shared: jobs (mine/show/accept/transition), payments (initiate/show),
conversations messages + read. Admin (`role:admin,super_admin`): dashboard,
users (+suspend), verification queue/approve/reject/resubmit, specialties
CRUD, payment refund, withdrawal decide, complaint resolve, settings.
Webhooks: `POST webhooks/payments/{esewa|khalti}` (signature-verified).

Pagination: `?page&per_page` (default 20) with `meta.total`. Auth: Sanctum
Bearer. See `routes/api.php` — it IS the documentation; keep it in sync.
