<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlatformSetting extends Model
{
    use HasFactory;

    protected $fillable = ['key', 'value'];

    public static function get(string $key, mixed $default = null): mixed
    {
        $row = static::where('key', $key)->first();

        return $row ? $row->value : $default;
    }

    public static function commissionRate(): float
    {
        return (float) static::get('commission_percent', 10);
    }
}
