<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 20)->default('customer')->after('email');
            $table->string('phone', 40)->nullable()->after('role');
            $table->string('status', 20)->default('active')->after('phone');
            $table->timestamp('phone_verified_at')->nullable()->after('email_verified_at');
            $table->softDeletes()->after('updated_at');
            $table->index('role');
            $table->index('status');
            $table->index('phone');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role']);
            $table->dropIndex(['status']);
            $table->dropIndex(['phone']);
            $table->dropSoftDeletes();
            $table->dropColumn(['role', 'phone', 'status', 'phone_verified_at']);
        });
    }
};
