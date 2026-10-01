<?php

namespace Tests\Feature;

use App\Models\Bill;
use App\Models\Job;
use App\Models\Payment;
use App\Models\TechnicianProfile;
use App\Models\User;
use App\Services\Payments\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BillingTest extends TestCase
{
    use RefreshDatabase;

    public function test_technician_issues_bill_after_completion_only(): void
    {
        [$customer, $job, $tech] = $this->completedJob();
        $ttoken = $tech->createToken('t')->plainTextToken;

        $open = Job::factory()->create([
            'customer_id' => $customer->id, 'technician_id' => $tech->id,
            'status' => 'in_progress',
        ]);
        $this->authed('POST', "/api/v1/jobs/{$open->id}/bill", $ttoken, [
            'amount' => 500,
        ])->assertStatus(422);

        $this->authed('POST', "/api/v1/jobs/{$job->id}/bill", $ttoken, [
            'amount' => 1500,
            'notes' => 'Parts + labour',
            'line_items' => [
                ['description' => 'Labour', 'amount' => 500],
                ['description' => 'Pipe', 'amount' => 1000],
            ],
        ])->assertCreated()->assertJsonPath('data.status', 'issued');

        $this->authed('POST', "/api/v1/jobs/{$job->id}/bill", $ttoken, [
            'amount' => 999,
        ])->assertStatus(409);

        $ctoken = $customer->createToken('c')->plainTextToken;
        $this->authed('GET', "/api/v1/jobs/{$job->id}/bill", $ctoken)
            ->assertOk()->assertJsonPath('data.amount', 1500);
    }

    public function test_customer_pays_exact_bill_via_sandbox_end_to_end(): void
    {
        [$customer, $job, $tech] = $this->completedJob();
        $ttoken = $tech->createToken('t')->plainTextToken;
        $ctoken = $customer->createToken('c')->plainTextToken;

        $bill = $this->authed('POST', "/api/v1/jobs/{$job->id}/bill", $ttoken, [
            'amount' => 2000,
        ])->assertCreated()->json('data');

        // Wrong amount rejected while a bill is issued.
        $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'sandbox',
            'amount' => 1999,
            'idempotency_key' => 'bill-pay-1',
        ])->assertStatus(422);

        $payment = $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'sandbox',
            'amount' => 2000,
            'idempotency_key' => 'bill-pay-1',
        ])->assertCreated()->assertJsonPath('data.status', 'initiated');

        $pid = $payment->json('data.id');

        // Only the customer can confirm.
        $stranger = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $this->authed('POST', "/api/v1/payments/{$pid}/confirm", $stranger->createToken('s')->plainTextToken)
            ->assertForbidden();

        $this->authed('POST', "/api/v1/payments/{$pid}/confirm", $ctoken)
            ->assertOk()->assertJsonPath('data.status', 'successful');

        // Confirmation is idempotent-guarded.
        $this->authed('POST', "/api/v1/payments/{$pid}/confirm", $ctoken)->assertStatus(409);

        $freshBill = Bill::findOrFail($bill['id']);
        $this->assertEquals(Bill::STATUS_PAID, $freshBill->status);
        $this->assertEquals($pid, $freshBill->payment_id);

        // Invoice reflects the paid bill.
        $inv = $this->authed('GET', "/api/v1/jobs/{$job->id}/invoice", $ctoken)->assertOk();
        $inv->assertJsonPath('data.total', 2000);
    }

    public function test_sandbox_confirm_moves_wallet_balance(): void
    {
        [$customer, $job, $tech] = $this->completedJob();
        $ctoken = $customer->createToken('c')->plainTextToken;

        $payment = $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'sandbox',
            'amount' => 1000,
            'idempotency_key' => 'wallet-1',
        ])->assertCreated();

        $this->authed('POST', "/api/v1/payments/{$payment->json('data.id')}/confirm", $ctoken)
            ->assertOk();

        $balance = $this->authed('GET', '/api/v1/wallet', $tech->createToken('t')->plainTextToken)
            ->assertOk()->json('data.balance');
        $this->assertEquals(900, (float) $balance);
    }

    public function test_withdrawal_request_with_platform_and_mobile_then_admin_initiates(): void
    {
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        $wallet = app(WalletService::class);
        $wallet->credit($tech->id, 1000, 'earning', Payment::class, 1, 'test');
        $ttoken = $tech->createToken('t')->plainTextToken;

        $w = $this->authed('POST', '/api/v1/withdrawals', $ttoken, [
            'amount' => 500,
            'method' => 'eSewa',
            'account_identifier' => '9800000001',
        ])->assertCreated()->json('data');

        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $atoken = $admin->createToken('a')->plainTextToken;

        $list = $this->authed('GET', '/api/v1/admin/withdrawals', $atoken)->assertOk();
        $this->assertNotEmpty($list->json('data'));

        // Admin initiates the payout, then marks it paid (ledger moves).
        $this->authed('POST', '/api/v1/admin/withdrawals/'.$w['id'].'/decide', $atoken, [
            'decision' => 'processing', 'note' => 'Initiated via mobile wallet',
        ])->assertOk()->assertJsonPath('data.status', 'processing');

        $this->authed('POST', '/api/v1/admin/withdrawals/'.$w['id'].'/decide', $atoken, [
            'decision' => 'paid', 'note' => 'TXN-123',
        ])->assertOk()->assertJsonPath('data.status', 'paid');

        $this->assertEquals(500, $wallet->balance($tech->id));
        $this->assertDatabaseHas('withdrawal_requests', [
            'id' => $w['id'], 'status' => 'paid', 'processed_by' => $admin->id,
        ]);
    }

    public function test_technician_without_verification_cannot_go_online(): void
    {
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->create([
            'user_id' => $tech->id, 'verification_status' => 'pending',
            'availability_status' => 'offline',
        ]);
        $token = $tech->createToken('t')->plainTextToken;

        $this->authed('POST', '/api/v1/technician/availability', $token, [
            'availability_status' => 'online',
        ])->assertForbidden();

        $approved = TechnicianProfile::where('user_id', $tech->id)->first();
        $approved->update(['verification_status' => 'approved']);
        $this->authed('POST', '/api/v1/technician/availability', $token, [
            'availability_status' => 'online',
        ])->assertOk();
    }

    /** @return array{User,Job,User} */
    private function completedJob(): array
    {
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->approved()->create(['user_id' => $tech->id]);
        $job = Job::factory()->create([
            'customer_id' => $customer->id,
            'technician_id' => $tech->id,
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return [$customer, $job, $tech];
    }
}
