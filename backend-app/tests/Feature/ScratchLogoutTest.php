<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ScratchLogoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_debug_logout(): void
    {
        User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $r = $this->getJson('/api/v1/auth/me');
        fwrite(STDERR, "\nNOAUTH-STATUS=" . $r->getStatusCode());
        fwrite(STDERR, "\nNOAUTH-BODY=" . substr($r->getContent(), 0, 200));
        $r2 = $this->getJson('/api/v1/auth/me', ['Authorization' => 'Bearer nonsense']);
        fwrite(STDERR, "\nBOGUS-STATUS=" . $r2->getStatusCode());
        $this->assertTrue(true);
    }
}
