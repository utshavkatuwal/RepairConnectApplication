<?php

namespace Database\Factories;

use App\Models\ServiceRequest;
use App\Models\Specialty;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceRequestFactory extends Factory
{
    protected $model = ServiceRequest::class;

    public function definition(): array
    {
        return [
            'customer_id' => User::factory(),
            'specialty_id' => Specialty::factory(),
            'title' => fake()->sentence(3),
            'description' => fake()->paragraph(),
            'address' => fake()->address(),
            'latitude' => 27.7172,
            'longitude' => 85.3240,
            'status' => 'requested',
        ];
    }
}
