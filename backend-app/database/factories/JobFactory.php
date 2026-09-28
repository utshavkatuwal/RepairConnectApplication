<?php

namespace Database\Factories;

use App\Models\Job;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class JobFactory extends Factory
{
    protected $model = Job::class;

    public function definition(): array
    {
        return [
            'service_request_id' => ServiceRequest::factory(),
            'customer_id' => User::factory(),
            'technician_id' => User::factory(),
            'status' => 'accepted',
            'accepted_at' => now(),
        ];
    }
}
