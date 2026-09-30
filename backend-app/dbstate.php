<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
echo 'USERS='.App\Models\User::count().' TOKENS='.Laravel\Sanctum\PersonalAccessToken::count().' REQ='.App\Models\ServiceRequest::count().' JOBS='.App\Models\Job::count().PHP_EOL;
foreach (App\Models\User::orderBy('id')->get(['id','email','role']) as $u) {
    echo "U {$u->id} {$u->email} {$u->role}".PHP_EOL;
}
