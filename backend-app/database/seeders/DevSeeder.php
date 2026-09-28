<?php

namespace Database\Seeders;

use App\Models\PlatformSetting;
use App\Models\ServiceRequest;
use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * DEVELOPMENT DATA ONLY. Never run in production.
 * Clearly labelled demo accounts for local end-to-end testing.
 */
class DevSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(SpecialtySeeder::class);
        PlatformSetting::updateOrCreate(['key' => 'commission_percent'], ['value' => '10']);

        $admin = User::firstOrCreate(
            ['email' => 'admin@repairconnect.dev'],
            ['name' => 'Dev Admin', 'password' => 'password123', 'role' => 'admin', 'status' => 'active']
        );
        User::firstOrCreate(
            ['email' => 'super@repairconnect.dev'],
            ['name' => 'Dev Super Admin', 'password' => 'password123', 'role' => 'super_admin', 'status' => 'active']
        );
        $customer = User::firstOrCreate(
            ['email' => 'customer@repairconnect.dev'],
            ['name' => 'Dev Customer', 'password' => 'password123', 'role' => 'customer', 'status' => 'active']
        );
        $customer->customerProfile()->firstOrCreate([]);

        $pendingTech = User::firstOrCreate(
            ['email' => 'pending.tech@repairconnect.dev'],
            ['name' => 'Dev Pending Tech', 'password' => 'password123', 'role' => 'technician', 'status' => 'active']
        );
        TechnicianProfile::firstOrCreate(
            ['user_id' => $pendingTech->id],
            [
                'specialty_id' => Specialty::first()->id,
                'bio' => 'Development seed technician.',
                'experience_years' => 3,
                'service_radius' => 25,
                'latitude' => 27.7172,
                'longitude' => 85.3240,
                'availability_status' => 'online',
                'verification_status' => 'pending',
            ]
        );

        $approvedTech = User::firstOrCreate(
            ['email' => 'approved.tech@repairconnect.dev'],
            ['name' => 'Dev Approved Tech', 'password' => 'password123', 'role' => 'technician', 'status' => 'active']
        );
        TechnicianProfile::updateOrCreate(
            ['user_id' => $approvedTech->id],
            [
                'specialty_id' => Specialty::first()->id,
                'bio' => 'Development seed technician.',
                'experience_years' => 8,
                'service_radius' => 25,
                'latitude' => 27.7172,
                'longitude' => 85.3240,
                'availability_status' => 'online',
                'verification_status' => 'approved',
                'approved_at' => now(),
            ]
        );

        if (ServiceRequest::count() === 0) {
            ServiceRequest::create([
                'customer_id' => $customer->id,
                'specialty_id' => Specialty::first()->id,
                'title' => 'Leaking kitchen tap',
                'description' => 'Kitchen tap leaks continuously, needs washer replacement and sealing.',
                'address' => 'Lakeside, Pokhara',
                'latitude' => 28.2096,
                'longitude' => 83.9856,
                'status' => 'searching',
            ]);
        }
    }
}
