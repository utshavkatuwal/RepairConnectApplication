<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\MessageStoreRequest;
use App\Models\Conversation;
use App\Models\Job;
use App\Models\Message;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    use AuthorizesRequests;

    /** Conversation for a job the caller participates in. */
    public function forJob(Request $request, int $jobId)
    {
        $job = Job::findOrFail($jobId);
        $this->authorize('viewJob', $job);
        $conversation = Conversation::firstOrCreate(['job_id' => $job->id]);
        $conversation->participants()->syncWithoutDetaching([
            $job->customer_id, $job->technician_id,
        ]);

        return response()->json([
            'success' => true, 'message' => 'Conversation.',
            'data' => $conversation,
        ]);
    }

    public function messages(Request $request, int $id)
    {
        $conversation = Conversation::with('participants')->findOrFail($id);
        abort_unless($conversation->participants->contains($request->user()), 403);

        $rows = $conversation->messages()->with('sender')->paginate(50);

        return response()->json([
            'success' => true, 'message' => 'Messages.',
            'data' => $rows->items(),
            'meta' => ['total' => $rows->total()],
        ]);
    }

    public function send(MessageStoreRequest $request, int $id)
    {
        $conversation = Conversation::with('participants')->findOrFail($id);
        abort_unless($conversation->participants->contains($request->user()), 403);

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
            'message' => $request->string('message'),
            'message_type' => $request->input('message_type', 'text'),
        ]);
        event(new MessageSent($message->fresh()));

        return response()->json(['success' => true, 'message' => 'Sent.', 'data' => $message], 201);
    }

    public function read(Request $request, int $id)
    {
        $conversation = Conversation::findOrFail($id);
        Message::where('conversation_id', $conversation->id)
            ->where('sender_id', '!=', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Marked read.', 'data' => []]);
    }
}
