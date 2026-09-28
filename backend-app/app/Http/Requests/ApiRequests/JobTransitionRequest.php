<?php

namespace App\Http\Requests\ApiRequests;

use App\Enums\Role;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

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

