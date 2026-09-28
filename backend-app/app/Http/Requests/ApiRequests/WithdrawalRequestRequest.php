<?php

namespace App\Http\Requests\ApiRequests;

use App\Enums\Role;
use Illuminate\Foundation\Http\FormRequest;

class WithdrawalRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isRole(Role::Technician->value) ?? false;
    }

    public function rules(): array
    {
        return [
            'amount' => ['required', 'numeric', 'min:1'],
            'method' => ['required', 'string', 'max:40'],
            'account_identifier' => ['required', 'string', 'max:191'],
        ];
    }
}
