<?php

use App\Models\Job;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

foreach (Job::orderBy('id')->get() as $j) {
    echo "job {$j->id}: sr={$j->service_request_id} tech={$j->technician_id} cust={$j->customer_id} status={$j->status} sched=".($j->scheduled_at ?: '-').' completed='.($j->completed_at ?: '-').PHP_EOL;
}
if (Schema::hasTable('bills')) {
    foreach (DB::table('bills')->get() as $b) {
        echo "bill {$b->id}: job={$b->job_id} amount={$b->amount} status={$b->status}".PHP_EOL;
    }
}
foreach (DB::table('technician_profiles')->get() as $p) {
    echo "profile user {$p->user_id}: avail={$p->availability_status} verif={$p->verification_status}".PHP_EOL;
}
foreach (DB::table('service_requests')->orderBy('id')->get() as $s) {
    echo "sr {$s->id}: cust={$s->customer_id} status={$s->status} sched=".($s->scheduled_at ?: '-').PHP_EOL;
}
