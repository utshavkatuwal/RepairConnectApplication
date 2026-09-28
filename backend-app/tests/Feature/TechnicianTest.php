<?php

namespace Tests\Feature;

use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class TechnicianTest extends TestCase
{
    use RefreshDatabase;

    public function test_signup_starts_pending_and_cannot_accept(): void
    {
        Storage::fake('private');
        $specialty = Specialty::factory()->create();
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        $token = $tech->createToken('t')->plainTextToken;
        $h = ['Authorization' => "Bearer $token"];

        $this->postJson('/api/v1/technician/profile', [
            'specialty_id' => $specialty->id,
            'experience_years' => 5,
            'service_radius' => 20,
            'latitude' => 27.7,
            'longitude' => 85.3,
        ], $h)->assertOk();

        $this->assertDatabaseHas('technician_profiles', [
            'user_id' => $tech->id,
            'verification_status' => 'pending',
        ]);

        // Pending tech sees gate on eligible-requests endpoint.
        $this->getJson('/api/v1/technician/requests', $h)->assertForbidden();
    }

    public function test_document_type_and_mime_validated(): void
    {
        Storage::fake('private');
        $tech = User::factory()->create(['role' => 'technician', 'status' => 'active']);
        TechnicianProfile::factory()->create(['user_id' => $tech->id]);
        $token = $tech->createToken('t')->plainTextToken;
        $h = ['Authorization' => "Bearer $token"];

        $this->postJson('/api/v1/technician/documents', [
            'document_type' => 'passport',
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ], $h)->assertStatus(422);

        $this->postJson('/api/v1/technician/documents', [
            'document_type' => 'government_id',
            'file' => UploadedFile::fake()->create('id.pdf', 100, 'application/pdf'),
        ], $h)->assertCreated();
    }

    public function test_admin_approves_and_tech_becomes_eligible(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $profile = TechnicianProfile::factory()->create();
        $token = $admin->createToken('a')->plainTextToken;

        $this->postJson(
            "/api/v1/admin/verification/{$profile->id}/approve", [],
            ['Authorization' => "Bearer $token"]
        )->assertOk();

        $this->assertEquals('approved', $profile->fresh()->verification_status);
    }

    public function test_technician_cannot_self_approve(): void
    {
        $tech = TechnicianProfile::factory()->create();
        $token = $tech->user->createToken('t')->plainTextToken;

        $this->postJson(
            "/api/v1/admin/verification/{$tech->id}/approve", [],
            ['Authorization' => "Bearer $token"]
        )->assertForbidden();
    }
}
