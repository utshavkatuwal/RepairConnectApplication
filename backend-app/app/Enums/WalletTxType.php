<?php

namespace App\Enums;

enum WalletTxType: string
{
    case Earning = 'earning';
    case Commission = 'commission';
    case Withdrawal = 'withdrawal';
    case Refund = 'refund';
    case Adjustment = 'adjustment';
}

