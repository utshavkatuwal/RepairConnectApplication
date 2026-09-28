<?php

namespace App\Enums;

enum CaseStatus: string
{
    case Open = 'open';
    case InReview = 'in_review';
    case Resolved = 'resolved';
    case Rejected = 'rejected';
}
