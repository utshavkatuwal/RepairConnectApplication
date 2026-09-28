<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case Pending = 'pending';
    case Initiated = 'initiated';
    case Processing = 'processing';
    case Successful = 'successful';
    case Failed = 'failed';
    case Cancelled = 'cancelled';
    case Refunded = 'refunded';

    /** @return array<string, string[]> */
    public static function transitions(): array
    {
        return [
            self::Pending->value => [self::Initiated->value, self::Processing->value, self::Successful->value, self::Failed->value, self::Cancelled->value],
            self::Initiated->value => [self::Processing->value, self::Successful->value, self::Failed->value, self::Cancelled->value],
            self::Processing->value => [self::Successful->value, self::Failed->value],
            self::Successful->value => [self::Refunded->value],
            self::Failed->value => [self::Pending->value],
            self::Cancelled->value => [],
            self::Refunded->value => [],
        ];
    }

    public static function can(string $from, string $to): bool
    {
        return in_array($to, self::transitions()[$from] ?? [], true);
    }
}
