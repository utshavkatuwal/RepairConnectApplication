<?php

namespace App\Enums;

enum RequestStatus: string
{
    case Requested = 'requested';
    case Searching = 'searching';
    case Offered = 'offered';
    case Accepted = 'accepted';
    case TechnicianArriving = 'technician_arriving';
    case InProgress = 'in_progress';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
    case Disputed = 'disputed';
}
