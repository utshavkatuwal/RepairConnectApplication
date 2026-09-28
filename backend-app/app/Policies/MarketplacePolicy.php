<?php

namespace App\Policies;

use App\Models\Job;
use App\Models\Payment;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Models\User;

class MarketplacePolicy
{
    public function viewRequest(User $user, ServiceRequest $request): bool
    {
        return $user->id === $request->customer_id || $user->isAdmin();
    }

    public function viewJob(User $user, Job $job): bool
    {
        return $job->involves($user);
    }

    public function updateJob(User $user, Job $job): bool
    {
        return $user->id === $job->technician_id || $user->isAdmin();
    }

    public function reviewJob(User $user, Job $job): bool
    {
        return $user->id === $job->customer_id && $job->status === 'completed';
    }

    public function viewPayment(User $user, Payment $payment): bool
    {
        return $user->id === $payment->customer_id
            || $user->id === $payment->technician_id
            || $user->isAdmin();
    }

    public function createReview(User $user, Review $review): bool
    {
        return $user->id === $review->customer_id;
    }
}
