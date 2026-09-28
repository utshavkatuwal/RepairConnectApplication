<?php

use App\Jobs\CleanupNotifications;
use App\Jobs\ExpireStaleRequests;
use App\Jobs\RecheckPendingPayments;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Periodic maintenance (§37). Runs via `php artisan schedule:work`
// locally or the platform scheduler in production — never the app.
Schedule::job(new ExpireStaleRequests)->hourly();
Schedule::job(new CleanupNotifications)->daily();
Schedule::job(new RecheckPendingPayments)->everyThirtyMinutes();
