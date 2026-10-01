<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$rows = Illuminate\Support\Facades\DB::select('SELECT id, customer_id, title, status, scheduled_at FROM service_requests ORDER BY id');
echo json_encode($rows, JSON_PRETTY_PRINT), PHP_EOL;
$jobs = Illuminate\Support\Facades\DB::select('SELECT id, service_request_id, customer_id, technician_id, status FROM jobs ORDER BY id');
echo json_encode($jobs, JSON_PRETTY_PRINT), PHP_EOL;