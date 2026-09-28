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

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $rows = \App\Models\AppNotification::where('user_id', $request->user()->id)
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Notifications.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function read(Request $request, int $id)
    {
        $n = \App\Models\AppNotification::where('user_id', $request->user()->id)->findOrFail($id);
        $n->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Marked read.', 'data' => []]);
    }

    public function device(Request $request)
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['sometimes', 'in:android,ios,web'],
        ]);
        \App\Models\Device::updateOrCreate(
            ['fcm_token' => $request->string('token')],
            ['user_id' => $request->user()->id, 'platform' => $request->input('platform', 'android')]
        );

        return response()->json(['success' => true, 'message' => 'Device registered.', 'data' => []]);
    }
}

