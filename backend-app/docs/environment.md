# Environment

Copy `.env.example` → `.env`, then `php artisan key:generate`. Never commit
`.env` or any secret. Local: debug on, log/mail drivers, database queue +
cache, local/private disks. Production: debug off, Redis (cache/queue),
Azure disk, Reverb + FCM + provider + mail creds, `APP_URL` https.

Missing-credential behavior is explicit, never silent simulation:
payments → 503 "not configured"; FCM → stored + warning log; maps → 422
configuration requirement from the backend. Azure migration = env swap
only (`FILESYSTEM_DISK`, `CACHE/QUEUE`, DB host, Blob creds); business
logic untouched. See `.env.example` for the full variable list.
