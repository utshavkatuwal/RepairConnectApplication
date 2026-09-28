<?php

namespace App\Jobs;

use App\Models\AppNotification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class CleanupNotifications implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        AppNotification::whereNotNull('read_at')
            ->where('read_at', '<', now()->subDays(90))
            ->delete();
    }
}
