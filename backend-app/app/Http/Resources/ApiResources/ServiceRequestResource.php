<?php

namespace App\Http\Resources\ApiResources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'specialty_id' => $this->specialty_id,
            'title' => $this->title,
            'description' => $this->description,
            'address' => $this->address,
            'latitude' => (float) $this->latitude,
            'longitude' => (float) $this->longitude,
            'status' => $this->status,
            'scheduled_at' => $this->scheduled_at,
            // Clients navigate service requests as "req-{id}" until a
            // technician accepts; job_id lets them switch to job views.
            'job_id' => $this->whenLoaded('job', fn () => $this->job?->id),
            'technician' => $this->whenLoaded('job', fn () => [
                'id' => $this->job->technician_id,
            ]),
        ];
    }
}
