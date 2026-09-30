<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AuditLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'actor_id', 'action', 'target_type', 'target_id', 'meta',
    ];

    protected function casts(): array
    {
        return ['meta' => 'array'];
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public static function record(
        User $actor,
        string $action,
        ?string $targetType = null,
        mixed $targetId = null,
        array $meta = []
    ): self {
        return static::create([
            'actor_id' => $actor->id,
            'action' => $action,
            'target_type' => $targetType,
            'target_id' => $targetId ? (int) $targetId : null,
            'meta' => $meta,
        ]);
    }
}
