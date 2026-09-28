<?php

namespace App\Events;

use App\Models\TechnicianProfile;
use Illuminate\Foundation\Events\Dispatchable;

class TechnicianVerified
{
    use Dispatchable;

    public function __construct(
        public TechnicianProfile $profile,
        public bool $approved,
        public ?string $reason = null,
    ) {}
}
