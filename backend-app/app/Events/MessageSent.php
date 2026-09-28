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

class MessageSent implements ShouldBroadcast
{
    use Dispatchable;
    public function __construct(public \App\Models\Message $message) {}
    public function broadcastOn(): array
    {
        return [new PrivateChannel("conversation.{$this->message->conversation_id}")];
    }
}
