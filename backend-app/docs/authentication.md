# Authentication & authorization

Sanctum personal tokens (`mobile`); bcrypt cost 12; login rejects
non-active accounts; logout revokes the current token; `me` revalidates.
Password reset via Laravel broker; email/phone verification columns exist
(`email_verified_at`, `phone_verified_at`).

Roles come from the DB user row (`EnsureRole` middleware + Policies/Gates),
never from client input: customer, technician, admin, super_admin (manage
admins/settings/specialties). Statuses: active/inactive/suspended/pending.
Suspended users fail login; revoked/expired tokens get 401 and the Flutter
client wipes secure storage.
