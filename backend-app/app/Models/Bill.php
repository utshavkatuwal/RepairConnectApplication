<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Technician-issued bill for a completed job. The customer pays the
 * issued amount; settlement marks the bill paid and links the payment.
 */
class Bill extends Model
{
    public const STATUS_ISSUED = 'issued';

    public const STATUS_PAID = 'paid';

    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'job_id',
        'technician_id',
        'customer_id',
        'amount',
        'currency',
        'line_items',
        'notes',
        'status',
        'payment_id',
        'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'line_items' => 'array',
            'paid_at' => 'datetime',
        ];
    }

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class);
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }
}
