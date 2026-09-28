<?php

namespace App\Enums;

enum Availability: string
{
    case Online = 'online';
    case Offline = 'offline';
    case Busy = 'busy';
}
