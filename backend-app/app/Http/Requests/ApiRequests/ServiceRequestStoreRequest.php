<?php

namespace App\Http\Requests\ApiRequests;

use App\Enums\Role;
use Illuminate\Foundation\Http\FormRequest;

class ServiceRequestStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isRole(Role::Customer->value) ?? false;
    }

    public function rules(): array
    {
        return [
            'specialty_id' => ['required', 'exists:specialties,id'],
            'title' => ['required', 'string', 'max:200'],
            'description' => ['required', 'string', 'min:10', 'max:2000'],
            'address' => ['required', 'string', 'max:512'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'scheduled_at' => ['nullable', 'date', 'after:now'],
            'priority' => ['sometimes', 'in:normal,urgent,critical'],
        ];
    }
}
