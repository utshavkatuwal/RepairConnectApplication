<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Development data only. Production seeds nothing fake.
        if (app()->environment('production')) {
            $this->call(SpecialtySeeder::class);
            return;
        }

        $this->call(DevSeeder::class);
    }
}
