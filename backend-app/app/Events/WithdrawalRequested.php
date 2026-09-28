<?php

namespace App\Events;

use App\Models\WithdrawalRequest;
use Illuminate\Foundation\Events\Dispatchable;

class WithdrawalRequested
{
    use Dispatchable;

    public function __construct(public WithdrawalRequest $withdrawal) {}
}
