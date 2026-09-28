<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OtpCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'email', 'code_hash', 'attempts', 'expires_at', 'consumed_at',
    ];

    protected function casts(): array
    {
        return ['expires_at' => 'datetime', 'consumed_at' => 'datetime'];
    }

    public function usable(): bool
    {
        return is_null($this->consumed_at)
            && $this->attempts < 5
            && $this->expires_at->isFuture();
    }
}
