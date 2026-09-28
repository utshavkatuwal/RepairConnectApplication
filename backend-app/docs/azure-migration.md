# Azure migration plan (PREPARATION ONLY — do not deploy yet)

The codebase is migration-ready by construction: every environment
difference is a config swap, business logic is untouched. When the local
definition of done is fully signed off, the move looks like this.

## Target topology

Flutter → HTTPS → Azure App Service (PHP 8.3, Laravel)
├── Azure Database for MySQL (migrations as-is)
├── Azure Cache for Redis (`CACHE_STORE`, `QUEUE_CONNECTION`)
├── Azure Blob Storage (`FILESYSTEM_DISK=azure`, private containers)
├── Application Insights (logs/metrics)
└── External: maps, eSewa/Khalti, FCM, mail/SMS

## Env mapping (local → Azure)

| Purpose | Local | Azure |
|---|---|---|
| DB | MySQL 127.0.0.1 / sqlite fallback | Azure MySQL connection string |
| Cache/queue | database | Redis (`CACHE_STORE=redis`, `QUEUE_CONNECTION=redis`) |
| Files | `local`/`private` disks | `azure` disk (private containers for documents) |
| Realtime | `log` broadcast | Reverb on App Service or Azure Web PubSub |
| Secrets | `.env` (never committed) | App Service app settings / Key Vault references |

## Pre-flight checklist

1. All 24 backend + 81 Flutter tests green in CI.
2. `21/21` HTTP E2E re-run against a MySQL-backed staging slot.
3. eSewa/Khalti live credentials verified in sandbox first.
4. FCM server key + device registration smoke-tested.
5. `APP_DEBUG=false`, `APP_URL` https, CORS allowlist tightened.
6. Storage migration: copy `verification/*` to the private Blob container.
7. Scheduler: enable App Service WebJobs/cron for `schedule:run`.
8. Queue: start a worker (`queue:work --queue=default`) as a second instance.
9. Backups: automated MySQL backups + Blob soft-delete on.
10. Swap slots (staging → production), monitor Insights, keep rollback ready.

## Non-goals until sign-off

No Bicep/Terraform, no pipeline deploys, no DNS cutover in this repo yet.
GitHub Actions here runs tests only.
