<?php

namespace App\Http\Resources\ApiResources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class JobResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'service_request_id' => $this->service_request_id,
            'customer_id' => $this->customer_id,
            'technician_id' => $this->technician_id,
            'status' => $this->status,
            'price' => null,
            'payment_status' => $this->payments()->latest()->first()?->status ?? 'pending',
            'accepted_at' => $this->accepted_at,
            'started_at' => $this->started_at,
            'completed_at' => $this->completed_at,
            'title' => $this->request?->title,
            'scheduled_at' => $this->request?->scheduled_at,
            'address' => $this->request?->address,
            'latitude' => $this->request?->latitude,
            'longitude' => $this->request?->longitude,
            'customer_name' => $this->customer?->name,
            'technician_name' => $this->technician?->name,
        ];
    }
}
