<?php

namespace Tests\Feature;

use App\Models\ServiceRequest;
use App\Models\Specialty;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_wrong_ownership_blocked(): void
    {
        $a = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $b = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $req = ServiceRequest::factory()->create(['customer_id' => $a->id]);

        $this->getJson("/api/v1/service-requests/{$req->id}", [
            'Authorization' => 'Bearer '.$b->createToken('x')->plainTextToken,
        ])->assertForbidden();
    }

    public function test_invalid_coordinates_rejected(): void
    {
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $specialty = Specialty::factory()->create();

        $this->postJson('/api/v1/service-requests', [
            'specialty_id' => $specialty->id,
            'title' => 'x',
            'description' => 'short',
            'address' => 'nowhere',
            'latitude' => 999,
            'longitude' => 999,
        ], ['Authorization' => 'Bearer '.$customer->createToken('c')->plainTextToken])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_suspended_user_blocked_at_login(): void
    {
        User::factory()->create([
            'email' => 's@example.com', 'password' => 'password1',
            'role' => 'customer', 'status' => 'suspended',
        ]);
        $this->postJson('/api/v1/auth/login', [
            'email' => 's@example.com', 'password' => 'password1',
        ])->assertForbidden();
    }

    public function test_health_endpoint_reports_dependencies(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonStructure(['success', 'data' => ['api', 'database', 'redis']]);
    }
}
