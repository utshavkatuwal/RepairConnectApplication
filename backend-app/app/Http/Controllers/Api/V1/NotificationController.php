<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Device;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $rows = AppNotification::where('user_id', $request->user()->id)
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Notifications.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function read(Request $request, int $id)
    {
        $n = AppNotification::where('user_id', $request->user()->id)->findOrFail($id);
        $n->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Marked read.', 'data' => []]);
    }

    public function device(Request $request)
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['sometimes', 'in:android,ios,web'],
        ]);
        Device::updateOrCreate(
            ['fcm_token' => $request->string('token')],
            ['user_id' => $request->user()->id, 'platform' => $request->input('platform', 'android')]
        );

        return response()->json(['success' => true, 'message' => 'Device registered.', 'data' => []]);
    }
}
