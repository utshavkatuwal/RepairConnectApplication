<?php

namespace App\Enums;

enum Role: string
{
    case Customer = 'customer';
    case Technician = 'technician';
    case Admin = 'admin';
    case SuperAdmin = 'super_admin';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
