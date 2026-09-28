<?php

use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChatController;
use App\Http\Controllers\Api\V1\ComplaintController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\JobController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\ServiceRequestController;
use App\Http\Controllers\Api\V1\SpecialtyController;
use App\Http\Controllers\Api\V1\TechnicianController;
use App\Http\Controllers\Api\V1\VerificationController;
use App\Http\Controllers\Api\V1\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('health', HealthController::class);

    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:5,1');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:5,1');
        Route::post('forgot-password', [AuthController::class, 'forgot']);
        Route::post('reset-password', [AuthController::class, 'reset']);
        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::post('refresh', [AuthController::class, 'refresh']);
            Route::get('me', [AuthController::class, 'me']);
        });
        Route::post('verify/send', [AuthController::class, 'sendCode'])->middleware('throttle:5,1');
        Route::post('verify', [AuthController::class, 'verify'])->middleware('throttle:10,1');
    });

    Route::get('specialties', [TechnicianController::class, 'specialties']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('devices', [NotificationController::class, 'device']);
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/{id}/read', [NotificationController::class, 'read']);
        Route::get('technicians', [TechnicianController::class, 'search']);
        Route::get('reviews', [ReviewController::class, 'index']);

        // Customer
        Route::middleware('role:customer')->group(function () {
            Route::get('service-requests', [ServiceRequestController::class, 'index']);
            Route::post('service-requests', [ServiceRequestController::class, 'store']);
            Route::get('service-requests/{id}', [ServiceRequestController::class, 'show']);
            Route::post('service-requests/{id}/cancel', [ServiceRequestController::class, 'cancel']);
            Route::post('reviews', [ReviewController::class, 'store']);
            Route::post('reviews/{id}/report', [ReviewController::class, 'report']);
            Route::post('complaints', [ComplaintController::class, 'store']);
        });

        // Technician
        Route::middleware('role:technician')->group(function () {
            Route::post('technician/profile', [TechnicianController::class, 'storeProfile']);
            Route::post('technician/documents', [TechnicianController::class, 'uploadDocument']);
            Route::post('technician/availability', [TechnicianController::class, 'availability']);
            Route::post('technician/location', [TechnicianController::class, 'location']);
            Route::get('technician/requests', [TechnicianController::class, 'nearbyRequests']);
            Route::get('wallet', [WalletController::class, 'balance']);
            Route::get('wallet/ledger', [WalletController::class, 'ledger']);
            Route::post('withdrawals', [WalletController::class, 'withdraw']);
        });

        // Shared participant routes (policy-checked inside controllers)
        Route::get('jobs', [JobController::class, 'mine']);
        Route::get('jobs/{id}', [JobController::class, 'show']);
        Route::post('jobs/{id}/accept', [JobController::class, 'accept'])->middleware('role:technician,admin');
        Route::post('jobs/{id}/transition', [JobController::class, 'transition']);
        Route::post('payments', [PaymentController::class, 'initiate'])->middleware('throttle:30,1');
        Route::get('payments/{id}', [PaymentController::class, 'show']);
        Route::get('conversations/{id}/messages', [ChatController::class, 'messages']);
        Route::post('conversations/{id}/messages', [ChatController::class, 'send']);
        Route::post('conversations/{id}/read', [ChatController::class, 'read']);
        Route::get('jobs/{id}/conversation', [ChatController::class, 'forJob']);
        Route::get('jobs/{id}/payments', [PaymentController::class, 'forJob']);
        Route::get('jobs/{id}/invoice', [PaymentController::class, 'invoice']);

        // Admin
        Route::middleware('role:admin,super_admin')->prefix('admin')->group(function () {
            Route::get('dashboard', [AdminController::class, 'dashboard']);
            Route::get('users', [AdminController::class, 'users']);
            Route::post('users/{id}/suspend', [AdminController::class, 'suspend']);
            Route::get('verification', [VerificationController::class, 'queue']);
            Route::post('verification/{id}/approve', [VerificationController::class, 'approve']);
            Route::post('verification/{id}/reject', [VerificationController::class, 'reject']);
            Route::post('verification/{id}/resubmit', [VerificationController::class, 'resubmit']);
            Route::post('payments/{id}/refund', [PaymentController::class, 'refund']);
            Route::post('withdrawals/{id}/decide', [WalletController::class, 'decide']);
            Route::post('complaints/{id}/resolve', [ComplaintController::class, 'resolve']);
            Route::get('settings', [AdminController::class, 'settings']);
            Route::post('settings', [AdminController::class, 'settings']);
            Route::apiResource('specialties', SpecialtyController::class)->only(['store', 'update', 'destroy']);
        });
    });

    // Provider webhooks: signature-verified inside the service, never trusted blindly.
    Route::post('webhooks/payments/{provider}', [PaymentController::class, 'webhook'])
        ->whereIn('provider', ['esewa', 'khalti']);
});
