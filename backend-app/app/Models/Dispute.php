<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_id', 'raised_by', 'reason', 'status', 'resolution',
    ];

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class);
    }
}

