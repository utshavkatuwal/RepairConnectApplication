<?php

namespace App\Jobs;

use App\Enums\RequestStatus;
use App\Models\ServiceRequest;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class RecheckPendingPayments implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        // Provider reconciliation runs here once merchant credentials exist.
        // Without credentials the job is a no-op (never fakes settlement).
        if (blank(config('payments.esewa.merchant_id'))
            && blank(config('payments.khalti.secret'))) {
            return;
        }
    }
}
