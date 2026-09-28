# Technician verification

Signup creates the account + empty profile with `verification_status =
pending`. Technician submits profile (specialty/experience/radius/real
coordinates) and documents (`government_id`, `professional_certificate`,
`license`, `experience_proof`, `other`; MIME allowlist + 10MB, UUID
filenames on the `private` disk — local driver dev, Azure prod).

Admin queue → approve (sets `approved_at`, marks docs) / reject (reason) /
resubmission_required. Events notify the technician. Guards: pending or
rejected techs 403 on accept and eligible-requests; approval is the only
path to eligibility. Nobody self-approves (admin routes are role-gated).
