<?php

namespace App\Http\Resources\ApiResources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'status' => $this->status,
            'is_verified' => ! is_null($this->email_verified_at),
            'tech_verified' => (bool) optional($this->technicianProfile)->isApproved(),
            'tech_status' => optional($this->technicianProfile)->verification_status ?? 'none',
        ];
    }
}

