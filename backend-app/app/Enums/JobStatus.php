<?php

namespace App\Enums;

enum JobStatus: string
{
    case Offered = 'offered';
    case Accepted = 'accepted';
    case TechnicianArriving = 'technician_arriving';
    case InProgress = 'in_progress';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
    case Disputed = 'disputed';

    /** @return array<string, string[]> */
    public static function transitions(): array
    {
        return [
            self::Offered->value => [self::Accepted->value, self::Cancelled->value],
            self::Accepted->value => [self::TechnicianArriving->value, self::Cancelled->value],
            self::TechnicianArriving->value => [self::InProgress->value, self::Cancelled->value],
            self::InProgress->value => [self::Completed->value, self::Disputed->value],
            self::Completed->value => [self::Disputed->value],
            self::Disputed->value => [],
            self::Cancelled->value => [],
        ];
    }

    public static function can(string $from, string $to): bool
    {
        return in_array($to, self::transitions()[$from] ?? [], true);
    }
}
