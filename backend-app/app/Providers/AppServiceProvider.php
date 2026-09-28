<?php

namespace App\Providers;

use App\Events\JobAccepted;
use App\Events\JobStatusChanged;
use App\Events\MessageSent;
use App\Events\PaymentSuccessful;
use App\Events\TechnicianVerified;
use App\Events\WithdrawalRequested;
use App\Listeners\NotifyJobParties;
use App\Policies\MarketplacePolicy;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Gate::define('viewRequest', [MarketplacePolicy::class, 'viewRequest']);
        Gate::define('viewJob', [MarketplacePolicy::class, 'viewJob']);
        Gate::define('updateJob', [MarketplacePolicy::class, 'updateJob']);
        Gate::define('reviewJob', [MarketplacePolicy::class, 'reviewJob']);
        Gate::define('viewPayment', [MarketplacePolicy::class, 'viewPayment']);

        Event::listen(JobAccepted::class, [NotifyJobParties::class, 'handleAccepted']);
        Event::listen(JobStatusChanged::class, [NotifyJobParties::class, 'handleStatus']);
        Event::listen(PaymentSuccessful::class, [NotifyJobParties::class, 'handlePayment']);
        Event::listen(TechnicianVerified::class, [NotifyJobParties::class, 'handleVerification']);
        Event::listen(WithdrawalRequested::class, [NotifyJobParties::class, 'handleWithdrawal']);
        Event::listen(MessageSent::class, [NotifyJobParties::class, 'handleMessage']);
    }
}
