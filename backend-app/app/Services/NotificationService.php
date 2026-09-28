<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Device;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    public function notify(User $user, string $type, string $title, string $body, array $meta = []): AppNotification
    {
        $n = AppNotification::create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'meta' => $meta,
        ]);

        // Push is queued; missing FCM config logs clearly instead of
        // silently pretending delivery.
        dispatch(function () use ($user, $n) {
            $this->push($user, $n);
        })->afterResponse();

        return $n;
    }

    public function push(User $user, AppNotification $n): void
    {
        $serverKey = config('services.fcm.server_key');
        if (blank($serverKey)) {
            Log::warning('FCM not configured; notification stored without push.', [
                'notification_id' => $n->id,
            ]);

            return;
        }

        $tokens = Device::where('user_id', $user->id)->pluck('fcm_token')->all();
        foreach ($tokens as $token) {
            Http::withToken($serverKey)->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $token,
                'notification' => ['title' => $n->title, 'body' => $n->body],
                'data' => ['type' => $n->type, 'id' => (string) $n->id],
            ]);
        }
    }
}
