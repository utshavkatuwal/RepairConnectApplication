<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;

use App\Http\Requests\ApiRequests\MessageStoreRequest;
use App\Http\Requests\ApiRequests\PaymentInitiateRequest;
use App\Http\Requests\ApiRequests\ReviewStoreRequest;
use App\Http\Requests\ApiRequests\WithdrawalRequestRequest;
use App\Models\Complaint;
use App\Models\Conversation;
use App\Models\Dispute;
use App\Models\Job;
use App\Models\Message;
use App\Models\Payment;
use App\Models\Review;
use App\Models\User;
use App\Services\Notifications;
use App\Services\NotificationService;
use App\Services\Payments\PaymentService;
use App\Services\Payments\WalletService;
use Illuminate\Http\Request;

class HealthController extends Controller
{
    public function __invoke()
    {
        $db = 'healthy';
        $redis = 'healthy';
        try {
            \Illuminate\Support\Facades\DB::select('select 1');
        } catch (\Throwable) {
            $db = 'unhealthy';
        }
        try {
            \Illuminate\Support\Facades\Cache::put('health', 1, 10);
        } catch (\Throwable) {
            $redis = 'unhealthy';
        }

        return response()->json([
            'success' => $db === 'healthy',
            'message' => 'Health.',
            'data' => ['api' => 'healthy', 'database' => $db, 'redis' => $redis],
        ], $db === 'healthy' ? 200 : 503);
    }
}
