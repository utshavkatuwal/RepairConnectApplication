<?php

namespace App\Http\Requests\ApiRequests;

use Illuminate\Foundation\Http\FormRequest;

class PaymentInitiateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user();
    }

    public function rules(): array
    {
        return [
            'job_id' => ['required', 'exists:jobs,id'],
            'provider' => ['required', 'in:esewa,khalti'],
            'amount' => ['required', 'numeric', 'min:1', 'max:100000'],
            'idempotency_key' => ['required', 'string', 'max:64'],
        ];
    }
}
