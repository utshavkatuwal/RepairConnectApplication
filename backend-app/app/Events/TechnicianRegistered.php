<?php

namespace App\Events;

use App\Models\TechnicianProfile;
use Illuminate\Foundation\Events\Dispatchable;

class TechnicianRegistered
{
    use Dispatchable;

    public function __construct(public TechnicianProfile $profile) {}
}
