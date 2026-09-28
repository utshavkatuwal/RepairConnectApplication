<?php

namespace App\Http\Requests\ApiRequests;

use Illuminate\Foundation\Http\FormRequest;

class JobTransitionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user();
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'string'],
            'reason' => ['nullable', 'string', 'min:5', 'max:2000'],
        ];
    }
}
