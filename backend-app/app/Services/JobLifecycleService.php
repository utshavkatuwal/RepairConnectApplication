<?php

namespace App\Services;

use App\Enums\JobStatus;
use App\Events\JobAccepted;
use App\Events\JobStatusChanged;
use App\Models\Conversation;
use App\Models\Job;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class JobLifecycleService
{
    /**
     * Role-aware transitions. Flutter may request, backend disposes:
     * unknown or unauthorized moves are rejected, never applied.
     *
     * @throws ValidationException
     */
    public function transition(User $actor, Job $job, string $to, ?string $reason = null): Job
    {
        return DB::transaction(function () use ($actor, $job, $to, $reason) {
            /** @var Job $locked */
            $locked = Job::whereKey($job->id)->lockForUpdate()->firstOrFail();
            $from = $locked->status;

            abort_unless(JobStatus::can($from, $to), 422, "Cannot move from {$from} to {$to}.");
            $this->authorize($actor, $locked, $from, $to);

            if (in_array($to, ['cancelled', 'disputed'], true) && blank($reason)) {
                abort(response()->json([
                    'success' => false,
                    'message' => 'A reason is required.',
                    'errors' => ['reason' => ['Reason is required (min 5).']],
                ], 422));
            }

            $locked->status = $to;
            match ($to) {
                'technician_arriving', 'in_progress' => $locked->started_at ??= now(),
                'completed' => $locked->completed_at = now(),
                'cancelled' => [$locked->cancelled_at = now(), $locked->cancel_reason = $reason],
                default => null,
            };
            $locked->save();

            $locked->request()->update(['status' => $to]);

            if ($to === 'completed' || $to === 'cancelled') {
                $locked->technician->technicianProfile?->update(['availability_status' => 'online']);
            }

            event(new JobStatusChanged($locked, $from, $to, $actor->id));

            return $locked->fresh();
        });
    }

    private function authorize(User $actor, Job $job, string $from, string $to): void
    {
        if ($actor->isAdmin()) {
            return;
        }
        $isTech = $actor->id === $job->technician_id && $actor->isRole('technician');
        $isCustomer = $actor->id === $job->customer_id && $actor->isRole('customer');

        $techMoves = [
            'offered' => ['accepted'],
            'accepted' => ['technician_arriving', 'cancelled'],
            'technician_arriving' => ['in_progress', 'cancelled'],
            'in_progress' => ['completed', 'disputed'],
            'completed' => ['disputed'],
        ];
        $customerMoves = [
            'offered' => ['cancelled'],
            'accepted' => ['cancelled'],
            'technician_arriving' => ['cancelled'],
            'in_progress' => ['disputed'],
            'completed' => ['disputed'],
        ];

        if ($isTech && in_array($to, $techMoves[$from] ?? [], true)) {
            return;
        }
        if ($isCustomer && in_array($to, $customerMoves[$from] ?? [], true)) {
            return;
        }
        abort(403, 'Your role cannot perform this transition.');
    }
}
