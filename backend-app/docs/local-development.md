# Local development

Prereqs: PHP 8.3+ with curl,fileinfo,mbstring,openssl,pdo_mysql,pdo_sqlite,
Composer, Flutter. MySQL 8 required for the real local stack:

```powershell
winget install --id Oracle.MySQL
# create database `repairconnect`, user with grants
cp .env.example .env   # set DB_* + APP_KEY via: php artisan key:generate
php artisan migrate --force
php artisan db:seed
php artisan serve --host=127.0.0.1 --port=8000
```

Queue/scheduler (separate shells): `php artisan queue:work`,
`php artisan schedule:work`. Realtime: `BROADCAST_CONNECTION=log` locally;
run Reverb (`php artisan reverb:start`) when testing sockets.

Fallback: sqlite runs the suite with zero setup
(`DB_CONNECTION=sqlite`, file auto-created); phpunit uses `:memory:`.

Flutter dev: `USE_FAKE_BACKEND=false`, `API_BASE_URL=http://127.0.0.1:8000`
(desktop/web) or `http://10.0.2.2:8000` (Android emulator). Dev accounts
(see `DevSeeder`, DEVELOPMENT DATA only): admin/customer/pending+approved
techs `@repairconnect.dev` / `password123`. Health: `GET /api/v1/health`.
