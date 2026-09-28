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

class AcceptJobService
{
    /**
     * Explicit technician acceptance with row locking: exactly one
     * technician can win a request even under concurrency.
     *
     * @throws ValidationException
     */
    public function accept(User $technician, int $requestId): Job
    {
        return DB::transaction(function () use ($technician, $requestId) {
            $profile = $technician->technicianProfile;
            abort_unless($profile, 403, 'Technician profile required.');
            abort_unless($profile->isApproved(), 403, 'Technician is not approved.');
            abort_unless($technician->status === 'active', 403, 'Account is not active.');
            abort_unless($profile->availability_status === 'online', 409, 'Technician is not available.');

            /** @var ServiceRequest $request */
            $request = ServiceRequest::whereKey($requestId)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless($request->isOpen(), 409, 'Request is no longer available.');
            abort_if($request->job()->lockForUpdate()->exists(), 409, 'Request already has a technician.');

            abort_unless(
                (int) $profile->specialty_id === (int) $request->specialty_id,
                403,
                'Specialty does not match this request.'
            );

            $job = Job::create([
                'service_request_id' => $request->id,
                'customer_id' => $request->customer_id,
                'technician_id' => $technician->id,
                'status' => JobStatus::Accepted->value,
                'accepted_at' => now(),
            ]);

            $request->update(['status' => 'accepted']);

            $conversation = Conversation::create(['job_id' => $job->id]);
            $conversation->participants()->attach([$request->customer_id, $technician->id]);

            $profile->update(['availability_status' => 'busy']);

            event(new JobAccepted($job));

            return $job->fresh();
        });
    }
}

