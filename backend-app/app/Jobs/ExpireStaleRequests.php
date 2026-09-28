<?php

namespace App\Jobs;

use App\Enums\RequestStatus;
use App\Models\ServiceRequest;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ExpireStaleRequests implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        ServiceRequest::whereIn('status', [
            RequestStatus::Requested->value,
            RequestStatus::Searching->value,
        ])
            ->where('created_at', '<', now()->subHours(72))
            ->update(['status' => RequestStatus::Cancelled->value]);
    }
}
