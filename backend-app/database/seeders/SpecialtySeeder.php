<?php

namespace Database\Seeders;

use App\Models\Specialty;
use Illuminate\Database\Seeder;

class SpecialtySeeder extends Seeder
{
    public function run(): void
    {
        foreach (['Plumber', 'Electrician', 'AC Technician', 'Appliance Repair', 'Computer Technician', 'Carpenter', 'Painter'] as $name) {
            Specialty::firstOrCreate(['name' => $name], ['status' => 'active']);
        }
    }
}
