<?php

namespace App\Jobs;

use App\Enums\RequestStatus;
use App\Models\ServiceRequest;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class CleanupNotifications implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        \App\Models\AppNotification::whereNotNull('read_at')
            ->where('read_at', '<', now()->subDays(90))
            ->delete();
    }
}

