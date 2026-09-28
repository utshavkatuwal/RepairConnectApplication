<?php

namespace App\Listeners;

use App\Events\JobAccepted;
use App\Events\JobStatusChanged;
use App\Events\MessageSent;
use App\Events\PaymentSuccessful;
use App\Events\TechnicianVerified;
use App\Events\WithdrawalRequested;
use App\Services\NotificationService;

class NotifyJobParties
{
    public function __construct(private NotificationService $notify) {}

    public function handleAccepted(JobAccepted $e): void
    {
        $job = $e->job->loadMissing('technician');
        $this->notify->notify(
            $job->customer, 'job_accepted',
            'Technician accepted your request',
            "{$job->technician->name} accepted request #{$job->service_request_id}.",
            ['job_id' => $job->id]
        );
    }

    public function handleStatus(JobStatusChanged $e): void
    {
        foreach ([$e->job->customer, $e->job->technician] as $user) {
            $this->notify->notify(
                $user, 'job_update',
                "Job {$e->to}",
                "Job #{$e->job->id} moved from {$e->from} to {$e->to}.",
                ['job_id' => $e->job->id, 'status' => $e->to]
            );
        }
    }

    public function handlePayment(PaymentSuccessful $e): void
    {
        $p = $e->payment;
        $this->notify->notify(
            $p->customer, 'payment_successful', 'Payment successful',
            "Payment of {$p->amount} {$p->currency} confirmed for job #{$p->job_id}.",
            ['payment_id' => $p->id]
        );
        $this->notify->notify(
            $p->technician, 'payment_successful', 'Earning credited',
            "Ledger credited {$p->technician_amount} for job #{$p->job_id}.",
            ['payment_id' => $p->id]
        );
    }

    public function handleVerification(TechnicianVerified $e): void
    {
        $user = $e->profile->user;
        $this->notify->notify(
            $user,
            $e->approved ? 'technician_approved' : 'technician_rejected',
            $e->approved ? 'Verification approved' : 'Verification needs attention',
            $e->approved
                ? 'You can now accept jobs.'
                : ($e->reason ?? 'Please review and resubmit.'),
            ['technician_id' => $e->profile->id]
        );
    }

    public function handleWithdrawal(WithdrawalRequested $e): void
    {
        $admins = \App\Models\User::whereIn('role', ['admin', 'super_admin'])
            ->where('status', 'active')->get();
        foreach ($admins as $admin) {
            $this->notify->notify(
                $admin, 'withdrawal_request',
                'New withdrawal request',
                "Technician #{$e->withdrawal->technician_id} requested {$e->withdrawal->amount}.",
                ['withdrawal_id' => $e->withdrawal->id]
            );
        }
    }

    public function handleMessage(MessageSent $e): void
    {
        $conversation = $e->message->conversation()->with('participants')->first();
        foreach ($conversation->participants as $participant) {
            if ($participant->id === $e->message->sender_id) {
                continue;
            }
            $this->notify->notify(
                $participant, 'new_message', 'New message',
                'You have a new chat message.',
                ['conversation_id' => $e->message->conversation_id]
            );
        }
    }
}
