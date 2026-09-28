<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_register_login_and_fetch_profile(): void
    {
        $reg = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test Customer',
            'email' => 'c@example.com',
            'password' => 'password1',
            'password_confirmation' => 'password1',
            'role' => 'customer',
        ]);
        $reg->assertCreated()->assertJsonPath('success', true);
        $token = $reg->json('data.token');
        $this->assertNotEmpty($token);

        $me = $this->authed('GET', '/api/v1/auth/me', $token);
        $me->assertOk()->assertJsonPath('data.role', 'customer');

        $this->authed('POST', '/api/v1/auth/logout', $token)
            ->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
        // Guards cache the user within one test process (see TestCase);
        // logout already revoked the token, so a fresh lookup fails.
        $this->authed('GET', '/api/v1/auth/me', $token)
            ->assertUnauthorized();
    }

    public function test_invalid_credentials_rejected(): void
    {
        User::factory()->create(['email' => 'x@example.com', 'password' => 'password1']);
        $this->postJson('/api/v1/auth/login', ['email' => 'x@example.com', 'password' => 'wrongpass'])
            ->assertUnauthorized();
    }

    public function test_customer_cannot_hit_technician_routes(): void
    {
        $token = $this->tokenFor('customer');
        $this->postJson('/api/v1/technician/profile', [], ['Authorization' => "Bearer $token"])
            ->assertForbidden();
    }

    public function test_guest_cannot_access_private_api(): void
    {
        $this->getJson('/api/v1/jobs')->assertUnauthorized();
    }

    private function tokenFor(string $role): string
    {
        $user = User::factory()->create(['role' => $role, 'status' => 'active']);
        return $user->createToken('test')->plainTextToken;
    }
}
