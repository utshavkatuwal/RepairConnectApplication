<?php

namespace Tests\Feature;

use App\Models\Job;
use App\Models\Payment;
use App\Models\PlatformSetting;
use App\Models\TechnicianProfile;
use App\Models\User;
use App\Services\Payments\PaymentService;
use App\Services\Payments\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Test merchant credentials: gateway create() builds payloads
        // without network. Live verify() still requires real secrets.
        config()->set('payments.esewa.merchant_id', 'TESTMERCHANT');
        config()->set('payments.esewa.secret', 'TESTSECRET');
    }

    public function test_initiate_creates_pending_and_idempotent(): void
    {
        [$customer, $job] = $this->completedJob();
        $ctoken = $customer->createToken('c')->plainTextToken;

        $a = $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'esewa',
            'amount' => 1500,
            'idempotency_key' => 'key-1',
        ])->assertCreated()->assertJsonPath('data.status', 'initiated');

        // Retry with the same key returns the SAME row, no duplicate.
        $b = $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'esewa',
            'amount' => 1500,
            'idempotency_key' => 'key-1',
        ])->assertCreated();
        $this->assertEquals($a->json('data.id'), $b->json('data.id'));
        $this->assertEquals(1, Payment::where('idempotency_key', 'key-1')->count());
    }

    public function test_unconfigured_provider_returns_clear_error(): void
    {
        config()->set('payments.esewa.merchant_id', null);
        config()->set('payments.esewa.secret', null);
        [$customer, $job] = $this->completedJob();
        $ctoken = $customer->createToken('c')->plainTextToken;

        // 503 with configuration message — never a fake success.
        $this->authed('POST', '/api/v1/payments', $ctoken, [
            'job_id' => $job->id,
            'provider' => 'esewa',
            'amount' => 1500,
            'idempotency_key' => 'key-2',
        ])->assertStatus(503)
            ->assertJsonPath('success', false);
        $this->assertEquals(0, Payment::where('idempotency_key', 'key-2')->count());
    }

    public function test_settle_computes_commission_and_ledgers(): void
    {
        [$customer, $job] = $this->completedJob();
        PlatformSetting::updateOrCreate(
            ['key' => 'commission_percent'], ['value' => '10']
        );
        $payment = Payment::create([
            'job_id' => $job->id,
            'customer_id' => $customer->id,
            'technician_id' => $job->technician_id,
            'provider' => 'esewa',
            'idempotency_key' => 'settle-1',
            'amount' => 1000,
            'status' => 'pending',
        ]);

        $settled = app(PaymentService::class)->settle($payment);
        $this->assertEquals('successful', $settled->status);
        $this->assertEquals(100, (float) $settled->commission_amount);
        $this->assertEquals(900, (float) $settled->technician_amount);
        $this->assertEquals(800, app(WalletService::class)->balance($job->technician_id));

        // Double settle rejected — no double credit.
        $this->expectExceptionMessage('no longer settleable');
        app(PaymentService::class)->settle($settled->fresh());
    }

    public function test_other_customer_cannot_view_payment(): void
    {
        [$customer, $job] = $this->completedJob();
        $payment = Payment::create([
            'job_id' => $job->id,
            'customer_id' => $customer->id,
            'technician_id' => $job->technician_id,
            'provider' => 'esewa',
            'idempotency_key' => 'key-3',
            'amount' => 100,
            'status' => 'pending',
        ]);
        $stranger = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $this->authed('GET', "/api/v1/payments/{$payment->id}", $stranger->createToken('s')->plainTextToken)
            ->assertForbidden();
    }

    public function test_wallet_derives_balance_and_withdrawal_flow(): void
    {
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        $wallet = app(WalletService::class);
        $this->assertEquals(0, $wallet->balance($tech->id));

        $wallet->credit($tech->id, 1000, 'earning', Payment::class, 1, 'test');
        $this->assertEquals(1000, $wallet->balance($tech->id));

        $w = $wallet->requestWithdrawal($tech, 400, 'esewa', '98XXXXXXXX');
        $this->assertEquals('pending', $w->status);
        // Requesting does not move money yet.
        $this->assertEquals(1000, $wallet->balance($tech->id));

        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $wallet->decideWithdrawal($admin, $w, 'paid', 'txn-ref-1');
        $this->assertEquals(600, $wallet->balance($tech->id));

        // Double payout rejected.
        $this->expectExceptionMessage('no longer pending');
        $wallet->decideWithdrawal($admin, $w->fresh(), 'paid', 'txn-ref-2');
    }

    /** @return array{User,Job} */
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

        return [$customer, $job];
    }
}
