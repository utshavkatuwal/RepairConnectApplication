<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Testing\TestResponse;

abstract class TestCase extends BaseTestCase
{
    /**
     * Authenticated JSON call isolated from previous calls in the same
     * test. Guards cache the resolved user per process; real HTTP
     * requests boot fresh, so reset guards to simulate that.
     */
    protected function authed(string $method, string $uri, string $token, array $data = []): TestResponse
    {
        auth()->forgetGuards();

        return $this->json($method, $uri, $data, ['Authorization' => "Bearer $token"]);
    }
}
