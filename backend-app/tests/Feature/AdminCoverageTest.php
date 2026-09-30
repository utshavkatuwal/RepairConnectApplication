<?php

namespace Tests\Feature;

use App\Models\Job;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminCoverageTest extends TestCase
{
    use RefreshDatabase;

    public function test_technician_own_profile_with_stats(): void
    {
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create(['user_id' => $tech->id]);
        $token = $tech->createToken('t')->plainTextToken;

        $this->authed('GET', '/api/v1/technician/profile', $token)
            ->assertOk()
            ->assertJsonPath('data.verification_status', 'approved')
            ->assertJsonStructure(['data' => ['rating', 'jobs_completed', 'documents']]);
    }

    public function test_admin_lists_and_audit_trail(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $token = $admin->createToken('a')->plainTextToken;

        $this->authed('GET', '/api/v1/admin/jobs', $token)->assertOk();
        $this->authed('GET', '/api/v1/admin/payments', $token)->assertOk();
        $this->authed('GET', '/api/v1/admin/complaints', $token)->assertOk();

        $target = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $this->authed('POST', "/api/v1/admin/users/{$target->id}/suspend", $token)->assertOk();

        $audit = $this->authed('GET', '/api/v1/admin/audit', $token)->assertOk();
        $actions = collect($audit->json('data'))->pluck('action')->all();
        $this->assertContains('user.suspended', $actions);
    }

    public function test_customer_cannot_reach_admin_lists(): void
    {
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $token = $customer->createToken('c')->plainTextToken;

        $this->authed('GET', '/api/v1/admin/jobs', $token)->assertForbidden();
        $this->authed('GET', '/api/v1/admin/audit', $token)->assertForbidden();
    }

    public function test_verification_decision_is_audited(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $profile = TechnicianProfile::factory()->create();
        $token = $admin->createToken('a')->plainTextToken;

        $this->authed('POST', "/api/v1/admin/verification/{$profile->id}/approve", $token)->assertOk();
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $admin->id,
            'action' => 'technician.approved',
            'target_id' => $profile->id,
        ]);
    }
}
