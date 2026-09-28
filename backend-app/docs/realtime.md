# Realtime (verified path)

Events (`JobAccepted`, `JobStatusChanged`, `PaymentSuccessful`,
`MessageSent`, …) implement `ShouldBroadcast` on private channels
(`user.{id}`, `conversation.{id}`), authorized in `routes/channels.php`
(self-only user channels; participant-only conversation channels).

Locally `BROADCAST_CONNECTION=log`: every broadcast lands in
`storage/logs/laravel.log` with channel + payload — verified live
(`private-user.*`, `private-conversation.*` entries from real accept /
transition / message flows). Queue (`database` locally) carries push
closures; `php artisan queue:work --stop-when-empty` drains them, and
missing FCM creds produce explicit warnings, never silent drops.

Production swap: install a Reverb-compatible release and set
`BROADCAST_CONNECTION=reverb` (+ `REVERB_*`). Note: `laravel/reverb`
v1.7–v1.12 requires `guzzlehttp/psr7 ^2.6` while this Laravel 13 stack
locks psr7 at 3.x — do NOT force-downgrade; wait for a compatible
Reverb release, then swap the env only. No application code changes.
Flutter keeps using REST as truth with the socket as notify-only,
per `ChatService`/`PushService` abstractions.
