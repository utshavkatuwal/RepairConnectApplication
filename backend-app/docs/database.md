# Database

MySQL 8 locally (`repairconnect` @ 127.0.0.1:3306), sqlite only for CI/tests.
Every table has a migration; FKs, indexes, uniques, timestamps, soft deletes
(users, service_requests) as specified.

Core: users (role/status/phone), customer_profiles, technician_profiles
(specialty, radius, lat/lng, availability, verification), specialties,
verification_documents (private disk), service_requests, jobs (unique
service_request_id — the double-accept guard), conversations (+pivot),
messages, notifications, devices, payments (unique provider_transaction_id +
idempotency_key), wallet_transactions (append-only ledger), withdrawal_requests,
reviews (unique job_id), complaints, disputes, platform_settings.

Queue infra uses `queue_jobs` (renamed — domain owns `jobs`), cache/sessions
on database locally, Redis in production via env swap.
