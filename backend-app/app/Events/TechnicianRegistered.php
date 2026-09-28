<?php

namespace App\Events;

use App\Models\Job;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Models\TechnicianProfile;
use App\Models\WithdrawalRequest;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

class TechnicianRegistered
{
    use Dispatchable;
    public function __construct(public TechnicianProfile $profile) {}
}

