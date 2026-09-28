<?php

namespace Database\Factories;

use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class TechnicianProfileFactory extends Factory
{
    protected $model = TechnicianProfile::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'specialty_id' => Specialty::factory(),
            'bio' => fake()->paragraph(),
            'experience_years' => fake()->numberBetween(1, 20),
            'service_radius' => 25,
            'latitude' => 27.7172,
            'longitude' => 85.3240,
            'availability_status' => 'online',
            'verification_status' => 'pending',
        ];
    }

    public function approved(): static
    {
        return $this->state(fn () => [
            'verification_status' => 'approved',
            'approved_at' => now(),
        ]);
    }
}
