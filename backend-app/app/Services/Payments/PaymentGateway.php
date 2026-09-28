<?php

namespace App\Services\Payments;

interface PaymentGateway
{
    /** Create a provider-side payment intent. Returns provider reference + redirect payload. */
    public function create(array $order): array;

    /**
     * Verify a provider callback/webhook against the provider API.
     * Returns normalized ['status' => successful|failed|pending, 'provider_ref' => string].
     */
    public function verify(array $callback): array;

    /** Refund a settled payment. Returns provider refund reference. */
    public function refund(string $providerRef, float $amount): array;
}
