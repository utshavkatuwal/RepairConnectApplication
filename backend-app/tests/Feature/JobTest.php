<?php

namespace Tests\Feature;

use App\Models\Job;
use App\Models\ServiceRequest;
use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class JobTest extends TestCase
{
    use RefreshDatabase;

    public function test_request_stays_searching_with_no_auto_assignment(): void
    {
        [$customer, $token] = $this->customer();
        $specialty = Specialty::factory()->create();

        $r = $this->authed('POST', '/api/v1/service-requests', $token, [
            'specialty_id' => $specialty->id,
            'title' => 'Fix tap',
            'description' => 'Kitchen tap leaks badly, needs repair.',
            'address' => 'Lakeside',
            'latitude' => 28.2,
            'longitude' => 83.9,
        ])->assertCreated();

        $this->assertDatabaseMissing('jobs', ['service_request_id' => $r->json('data.id')]);
        $this->assertContains($r->json('data.status'), ['requested', 'searching']);
    }

    public function test_service_request_resource_links_job_and_schedule(): void
    {
        [$customer, $token] = $this->customer();
        $specialty = Specialty::factory()->create();

        $id = $this->authed('POST', '/api/v1/service-requests', $token, [
            'specialty_id' => $specialty->id,
            'title' => 'Scheduled tap fix',
            'description' => 'Kitchen tap leaks badly, needs repair.',
            'address' => 'Lakeside',
            'latitude' => 28.2,
            'longitude' => 83.9,
            'scheduled_at' => now()->addDay()->toIso8601String(),
        ])->assertCreated()->json('data.id');

        // Open request: schedule visible, no job to navigate to yet.
        $before = $this->authed('GET', "/api/v1/service-requests/{$id}", $token)->assertOk();
        $this->assertNotNull($before->json('data.scheduled_at'));
        $this->assertArrayHasKey('job_id', $before->json('data'));
        $this->assertNull($before->json('data.job_id'));

        // Same contract in the list (the app resolves req-{id} from it).
        $index = $this->authed('GET', '/api/v1/service-requests', $token)->assertOk()->json('data');
        $this->assertArrayHasKey('job_id', $index[0]);
        $this->assertNull($index[0]['job_id']);

        $tech = $this->approvedTech($specialty);
        $jobId = $this->authed('POST', "/api/v1/jobs/{$id}/accept", $tech->createToken('t')->plainTextToken)
            ->assertOk()->json('data.id');

        // After acceptance the request points at the real job id.
        $after = $this->authed('GET', "/api/v1/service-requests/{$id}", $token)->assertOk();
        $after->assertJsonPath('data.job_id', $jobId);
    }

    public function test_approved_tech_accepts_and_second_is_rejected(): void
    {
        [$customer] = $this->customer();
        $specialty = Specialty::factory()->create();
        $request = ServiceRequest::factory()->create([
            'customer_id' => $customer->id,
            'specialty_id' => $specialty->id,
            'status' => 'searching',
            'latitude' => 27.71,
            'longitude' => 85.32,
        ]);

        $techA = $this->approvedTech($specialty);
        $techB = $this->approvedTech($specialty);

        $accept = $this->authed(
            'POST', "/api/v1/jobs/{$request->id}/accept",
            $techA->createToken('t')->plainTextToken
        )->assertOk();
        $accept->assertJsonPath('data.status', 'accepted');

        // Second technician loses the race with 409, not a duplicate job.
        $this->authed(
            'POST', "/api/v1/jobs/{$request->id}/accept",
            $techB->createToken('t')->plainTextToken
        )->assertStatus(409);
        $this->assertEquals(1, Job::where('service_request_id', $request->id)->count());
    }

    public function test_pending_and_wrong_specialty_techs_cannot_accept(): void
    {
        [$customer] = $this->customer();
        $specialty = Specialty::factory()->create();
        $other = Specialty::factory()->create();
        $request = ServiceRequest::factory()->create([
            'customer_id' => $customer->id,
            'specialty_id' => $specialty->id,
            'status' => 'searching',
        ]);

        $pending = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->create([
            'user_id' => $pending->id, 'specialty_id' => $specialty->id,
        ]);
        $this->authed(
            'POST', "/api/v1/jobs/{$request->id}/accept",
            $pending->createToken('t')->plainTextToken
        )->assertForbidden();

        $wrongSpec = $this->approvedTech($other);
        $this->authed(
            'POST', "/api/v1/jobs/{$request->id}/accept",
            $wrongSpec->createToken('t')->plainTextToken
        )->assertForbidden();
    }

    public function test_lifecycle_and_actor_rules(): void
    {
        [$customer, $ctoken] = $this->customer();
        $specialty = Specialty::factory()->create();
        $request = ServiceRequest::factory()->create([
            'customer_id' => $customer->id, 'specialty_id' => $specialty->id, 'status' => 'searching',
        ]);
        $tech = $this->approvedTech($specialty);
        $ttoken = $tech->createToken('t')->plainTextToken;

        $jobId = $this->authed('POST', "/api/v1/jobs/{$request->id}/accept", $ttoken)
            ->assertOk()->json('data.id');

        // Customer cannot drive technician moves.
        $this->authed('POST', "/api/v1/jobs/$jobId/transition", $ctoken, ['status' => 'completed'])
            ->assertStatus(422);
        // Arbitrary jumps rejected.
        $this->authed('POST', "/api/v1/jobs/$jobId/transition", $ttoken, ['status' => 'completed'])
            ->assertStatus(422);

        foreach (['technician_arriving', 'in_progress', 'completed'] as $s) {
            $this->authed('POST', "/api/v1/jobs/$jobId/transition", $ttoken, ['status' => $s])
                ->assertOk();
        }
        $this->assertEquals('completed', Job::find($jobId)->status);

        // Completed jobs do not reopen.
        $this->authed('POST', "/api/v1/jobs/$jobId/transition", $ttoken, ['status' => 'in_progress'])
            ->assertStatus(422);
    }

    /** @return array{User,string} */
    private function customer(): array
    {
        $u = User::factory()->create(['role' => 'customer', 'status' => 'active']);

        return [$u, $u->createToken('c')->plainTextToken];
    }

    private function approvedTech(Specialty $specialty): User
    {
        $u = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create([
            'user_id' => $u->id,
            'specialty_id' => $specialty->id,
            'latitude' => 27.71,
            'longitude' => 85.32,
        ]);

        return $u;
    }
}
