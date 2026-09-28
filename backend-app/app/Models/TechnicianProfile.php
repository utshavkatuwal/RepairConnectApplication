<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TechnicianProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'specialty_id', 'bio', 'experience_years',
        'service_radius', 'latitude', 'longitude', 'availability_status',
        'verification_status', 'approved_at', 'rejected_reason',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'approved_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function specialty(): BelongsTo
    {
        return $this->belongsTo(Specialty::class);
    }

    public function documents(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(VerificationDocument::class, 'technician_id');
    }

    public function isApproved(): bool
    {
        return $this->verification_status === 'approved';
    }
}

