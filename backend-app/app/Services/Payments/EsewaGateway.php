<?php

namespace App\Services\Payments;

class EsewaGateway extends BaseGateway
{
    protected static function name(): string
    {
        return 'esewa';
    }

    public function create(array $order): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }

        return [
            'provider' => 'esewa',
            'provider_ref' => 'esewa_'.$order['idempotency_key'],
            'form_url' => $this->cfg('endpoint', 'https://rc.esewa.com.np/epay/main'),
            'payload' => [
                'amt' => $order['amount'],
                'pid' => $order['idempotency_key'],
                'scd' => $this->cfg('merchant_id'),
            ],
        ];
    }

    public function verify(array $callback): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }
        // Real implementation calls eSewa's transaction-check endpoint with
        // amt/rid/pid via Laravel HTTP client and maps the XML/JSON result.
        // Signature: verify(array $callback): array — provider-owned.
        throw new \RuntimeException('eSewa live verification requires merchant credentials.');
    }

    public function refund(string $providerRef, float $amount): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }
        throw new \RuntimeException('eSewa refunds are processed via merchant dashboard/API.');
    }
}

/**
 * Khalti gateway. Real verification via Khalti API lookup; without
 * credentials it returns a clear 503 — never a fake success.
 */
