<?php

namespace Tests\Feature;

use App\Models\Job;
use App\Models\Payment;
use App\Models\Review;
use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CoverageTest extends TestCase
{
    use RefreshDatabase;

    public function test_otp_send_verify_and_reuse_rejected(): void
    {
        $user = User::factory()->create(['email' => 'otp@example.com', 'role' => 'customer', 'status' => 'active']);

        $send = $this->postJson('/api/v1/auth/verify/send', ['email' => 'otp@example.com'])
            ->assertOk();
        $code = $send->json('data.debug_code');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        $this->postJson('/api/v1/auth/verify', ['email' => 'otp@example.com', 'code' => '000000'])
            ->assertStatus(422);
        $this->postJson('/api/v1/auth/verify', ['email' => 'otp@example.com', 'code' => $code])
            ->assertOk();
        // Single use: replay rejected.
        $this->postJson('/api/v1/auth/verify', ['email' => 'otp@example.com', 'code' => $code])
            ->assertStatus(422);
        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_refresh_rotates_token(): void
    {
        $user = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $token = $user->createToken('mobile')->plainTextToken;

        $r = $this->authed('POST', '/api/v1/auth/refresh', $token)->assertOk();
        $new = $r->json('data.token');
        $this->assertNotEquals($token, $new);

        $this->authed('GET', '/api/v1/auth/me', $token)->assertUnauthorized();
        $this->authed('GET', '/api/v1/auth/me', $new)->assertOk();
    }

    public function test_technician_search_lists_only_approved(): void
    {
        $specialty = Specialty::factory()->create();
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $approved = User::factory()->create(['name' => 'Zed Approved', 'role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create([
            'user_id' => $approved->id, 'specialty_id' => $specialty->id,
            'latitude' => 27.71, 'longitude' => 85.32,
        ]);
        $pending = User::factory()->create(['name' => 'Zed Pending', 'role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->create([
            'user_id' => $pending->id, 'specialty_id' => $specialty->id,
            'latitude' => 27.71, 'longitude' => 85.32,
        ]);

        $token = $customer->createToken('c')->plainTextToken;
        $r = $this->authed('GET', '/api/v1/technicians?q=Zed', $token)->assertOk();
        $names = collect($r->json('data'))->pluck('name')->all();
        $this->assertContains('Zed Approved', $names);
        $this->assertNotContains('Zed Pending', $names);

        // Distance-sorted when coordinates given.
        $r2 = $this->authed('GET', '/api/v1/technicians?lat=27.71&lng=85.32', $token)->assertOk();
        $this->assertEquals(1, count($r2->json('data')));
        $this->assertEquals(0.0, $r2->json('data.0.km'));
    }

    public function test_reviews_index_scoped(): void
    {
        [$customer, $job, $review] = $this->reviewedJob();
        $ctoken = $customer->createToken('c')->plainTextToken;

        $this->authed('GET', "/api/v1/reviews?booking_id={$job->id}", $ctoken)
            ->assertOk()->assertJsonCount(1, 'data');

        $this->authed('GET', "/api/v1/reviews?technician_id={$job->technician_id}", $ctoken)
            ->assertOk()->assertJsonCount(1, 'data');

        $stranger = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $this->authed('GET', "/api/v1/reviews?booking_id={$job->id}", $stranger->createToken('s')->plainTextToken)
            ->assertForbidden();
    }

    public function test_job_payments_and_invoice(): void
    {
        [$customer, $job] = $this->completedJob();
        $ctoken = $customer->createToken('c')->plainTextToken;

        $this->authed('GET', "/api/v1/jobs/{$job->id}/payments", $ctoken)
            ->assertOk()->assertJsonCount(0, 'data');
        $this->authed('GET', "/api/v1/jobs/{$job->id}/invoice", $ctoken)
            ->assertNotFound();

        Payment::create([
            'job_id' => $job->id, 'customer_id' => $customer->id,
            'technician_id' => $job->technician_id, 'provider' => 'esewa',
            'provider_transaction_id' => 'cov-1', 'idempotency_key' => 'cov-1',
            'amount' => 2000, 'status' => 'successful', 'paid_at' => now(),
        ]);
        $inv = $this->authed('GET', "/api/v1/jobs/{$job->id}/invoice", $ctoken)->assertOk();
        $inv->assertJsonPath('data.booking_id', $job->id);
        $inv->assertJsonPath('data.total', 2000);
    }

    /** @return array{User,Job,Review} */
    private function reviewedJob(): array
    {
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create(['user_id' => $tech->id]);
        $job = Job::factory()->create([
            'customer_id' => $customer->id, 'technician_id' => $tech->id,
            'status' => 'completed', 'completed_at' => now(),
        ]);
        $review = Review::create([
            'job_id' => $job->id, 'customer_id' => $customer->id,
            'technician_id' => $tech->id, 'rating' => 5,
        ]);

        return [$customer, $job, $review];
    }

    /** @return array{User,Job} */
    private function completedJob(): array
    {
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create(['user_id' => $tech->id]);
        $job = Job::factory()->create([
            'customer_id' => $customer->id, 'technician_id' => $tech->id,
            'status' => 'completed', 'completed_at' => now(),
        ]);

        return [$customer, $job];
    }
}
