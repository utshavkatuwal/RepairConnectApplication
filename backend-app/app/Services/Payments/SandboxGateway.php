<?php

namespace App\Services\Payments;

/**
 * Local sandbox gateway: full initiate -> confirm -> settle lifecycle
 * without external merchant credentials. Clearly labelled "sandbox" in
 * the app; never used unless the customer explicitly picks it.
 */
class SandboxGateway extends BaseGateway
{
    protected static function name(): string
    {
        return 'sandbox';
    }

    protected function configured(): bool
    {
        return true;
    }

    public function create(array $order): array
    {
        return [
            'provider' => 'sandbox',
            'provider_ref' => 'sandbox_'.$order['idempotency_key'],
            'sandbox' => true,
            'confirm' => 'POST /api/v1/payments/{id}/confirm',
        ];
    }

    public function verify(array $callback): array
    {
        $ref = (string) ($callback['provider_ref'] ?? '');
        abort_if(! str_starts_with($ref, 'sandbox_'), 422, 'Invalid sandbox reference.');

        return [
            'provider_ref' => $ref,
            'status' => ($callback['status'] ?? 'successful') === 'failed' ? 'failed' : 'successful',
        ];
    }

    public function refund(string $providerRef, float $amount): array
    {
        return ['provider' => 'sandbox', 'provider_ref' => $providerRef, 'status' => 'refunded'];
    }
}
