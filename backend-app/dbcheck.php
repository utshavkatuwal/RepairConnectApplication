<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$u = App\Models\User::where('email', 'e2ecust@example.com')->first();
echo 'USER='.json_encode($u?->only(['id','name','email','role','status'])).PHP_EOL;
echo 'USERS='.App\Models\User::count().' REQ='.App\Models\ServiceRequest::count().' JOBS='.App\Models\Job::count().' PAY='.App\Models\Payment::count().' LEDGER='.App\Models\WalletTransaction::count().' WD='.App\Models\WithdrawalRequest::count().' MSG='.App\Models\Message::count().' REV='.App\Models\Review::count().' AUDIT='.App\Models\AuditLog::count().PHP_EOL;
