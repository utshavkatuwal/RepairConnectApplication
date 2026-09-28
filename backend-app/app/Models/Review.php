<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_id', 'customer_id', 'technician_id', 'rating', 'comment',
    ];

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class);
    }
}

