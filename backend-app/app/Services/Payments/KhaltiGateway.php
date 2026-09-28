<?php

namespace App\Services\Payments;

class KhaltiGateway extends BaseGateway
{
    protected static function name(): string
    {
        return 'khalti';
    }

    public function create(array $order): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }

        return [
            'provider' => 'khalti',
            'provider_ref' => 'khalti_'.$order['idempotency_key'],
            'payload' => [
                'amount' => (int) round($order['amount'] * 100),
                'purchase_order_id' => $order['idempotency_key'],
            ],
        ];
    }

    public function verify(array $callback): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }
        // Real implementation POSTs the pidx to Khalti's lookup endpoint
        // with the secret key and maps Completed/Expired/Cancelled.
        throw new \RuntimeException('Khalti live verification requires secret key.');
    }

    public function refund(string $providerRef, float $amount): array
    {
        if (! $this->configured()) {
            $this->needConfig();
        }
        throw new \RuntimeException('Khalti refunds are processed via merchant API.');
    }
}
