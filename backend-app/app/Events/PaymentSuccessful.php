<?php

namespace App\Events;

use App\Models\Payment;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

class PaymentSuccessful implements ShouldBroadcast
{
    use Dispatchable;

    public function __construct(public Payment $payment) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->payment->customer_id}"),
            new PrivateChannel("user.{$this->payment->technician_id}"),
        ];
    }
}
