<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Specialty extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'icon', 'status'];

    public function technicians(): HasMany
    {
        return $this->hasMany(TechnicianProfile::class);
    }
}
