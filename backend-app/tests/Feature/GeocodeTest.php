<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeocodeTest extends TestCase
{
    use RefreshDatabase;

    public function test_reverse_geocode_returns_address_from_provider(): void
    {
        Http::fake([
            'nominatim.openstreetmap.org/*' => Http::response([
                'display_name' => 'Thamel, Kathmandu, Nepal',
            ], 200),
        ]);

        $resp = $this->getJson('/api/v1/geocode/reverse?lat=27.7172&lng=85.324');

        $resp->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.address', 'Thamel, Kathmandu, Nepal')
            ->assertJsonPath('data.lat', 27.7172)
            ->assertJsonPath('data.lng', 85.324);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'nominatim.openstreetmap.org/reverse'));
    }

    public function test_reverse_geocode_returns_null_address_when_provider_fails(): void
    {
        Http::fake([
            'nominatim.openstreetmap.org/*' => Http::response('boom', 500),
        ]);

        $resp = $this->getJson('/api/v1/geocode/reverse?lat=27.71&lng=85.32');

        $resp->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.address', null);
    }

    public function test_reverse_geocode_validates_coordinates(): void
    {
        Http::fake();

        $this->getJson('/api/v1/geocode/reverse?lat=999&lng=85.32')->assertStatus(422);
        $this->getJson('/api/v1/geocode/reverse?lat=27.7')->assertStatus(422);

        Http::assertNothingSent();
    }
}
