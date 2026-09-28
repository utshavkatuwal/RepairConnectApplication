<?php

namespace App\Services\Payments;

abstract class BaseGateway implements PaymentGateway
{
    protected function cfg(string $key, mixed $default = null): mixed
    {
        return config('payments.'.static::name().'.'.$key, $default);
    }

    abstract protected static function name(): string;

    protected function configured(): bool
    {
        return ! blank($this->cfg('merchant_id'))
            && ! blank($this->cfg('secret'));
    }

    protected function needConfig(): never
    {
        abort(response()->json([
            'success' => false,
            'message' => 'Payment provider is not configured. Set credentials in .env.',
            'errors' => ['provider' => ['Missing provider credentials.']],
        ], 503));
    }
}

/**
 * eSewa gateway. Real HTTP verification against eSewa; without credentials
 * it returns a clear 503 — never a fake success.
 */
