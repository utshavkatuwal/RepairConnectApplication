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

class ComplaintController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'job_id' => ['nullable', 'exists:jobs,id'],
            'body' => ['required', 'string', 'min:5', 'max:2000'],
        ]);
        $c = Complaint::create([
            'job_id' => $request->input('job_id'),
            'reporter_id' => $request->user()->id,
            'body' => $request->string('body'),
        ]);

        return response()->json(['success' => true, 'message' => 'Complaint filed.', 'data' => $c], 201);
    }

    public function resolve(Request $request, int $id)
    {
        $request->validate(['resolution' => ['required', 'string', 'min:5']]);
        $c = Complaint::findOrFail($id);
        $c->update([
            'status' => 'resolved',
            'assignee_id' => $request->user()->id,
            'resolution' => $request->string('resolution'),
        ]);

        return response()->json(['success' => true, 'message' => 'Complaint resolved.', 'data' => $c]);
    }
}

