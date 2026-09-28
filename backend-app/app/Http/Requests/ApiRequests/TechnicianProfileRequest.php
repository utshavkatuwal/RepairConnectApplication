<?php

namespace App\Http\Requests\ApiRequests;

use App\Enums\Role;
use Illuminate\Foundation\Http\FormRequest;

class TechnicianProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isRole(Role::Technician->value) ?? false;
    }

    public function rules(): array
    {
        return [
            'specialty_id' => ['required', 'exists:specialties,id'],
            'bio' => ['nullable', 'string', 'max:2000'],
            'experience_years' => ['required', 'integer', 'min:0', 'max:60'],
            'service_radius' => ['required', 'integer', 'min:1', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ];
    }
}
