<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Who may reach the dashboard.
 *
 * Every admin route in one test rather than one test per feature: a route
 * added to the group later without the middleware is exactly the mistake
 * worth catching, and it would not show up in that feature's own tests.
 */
class DashboardAccessTest extends TestCase
{
    use RefreshDatabase;

    /** @return array<int, string> */
    private function adminRoutes(): array
    {
        return collect(app('router')->getRoutes())
            ->filter(fn ($route) => str_starts_with($route->uri(), 'admin')
                && in_array('GET', $route->methods(), true))
            // Only routes with no parameters, so the check needs no fixtures.
            ->reject(fn ($route) => str_contains($route->uri(), '{'))
            ->map(fn ($route) => '/'.$route->uri())
            ->values()
            ->all();
    }

    public function test_every_admin_page_is_closed_to_a_member(): void
    {
        $routes = $this->adminRoutes();
        $this->assertNotEmpty($routes, 'no admin routes found to check');

        $member = User::factory()->create(['is_admin' => false]);

        foreach ($routes as $uri) {
            $this->actingAs($member)
                ->get($uri)
                ->assertForbidden("$uri should be closed to a member");
        }
    }

    public function test_every_admin_page_is_closed_to_a_stranger(): void
    {
        foreach ($this->adminRoutes() as $uri) {
            // Not signed in at all: a redirect to login, never the page.
            $this->get($uri)->assertRedirect('/login');
        }
    }

    public function test_an_admin_gets_in(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)->get('/admin')->assertOk();
    }

    public function test_the_dashboard_redirect_sends_a_member_to_their_profile(): void
    {
        // Breeze lands everyone on /dashboard after signing in; only an
        // admin is sent on to the panel.
        $this->actingAs(User::factory()->create(['is_admin' => false]))
            ->get('/dashboard')
            ->assertRedirect('/profile');

        $this->actingAs(User::factory()->create(['is_admin' => true]))
            ->get('/dashboard')
            ->assertRedirect('/admin');
    }

    public function test_a_suspended_admin_is_still_an_admin_but_cannot_sign_in(): void
    {
        // The app's login refuses an inactive account; the flag is separate
        // from the permission, and both have to hold.
        $admin = User::factory()->create([
            'is_admin' => true,
            'is_active' => false,
            'password' => bcrypt('correct horse 9 battery'),
        ]);

        $this->postJson('/api/v1/login', [
            'email' => $admin->email,
            'password' => 'correct horse 9 battery',
            'device_name' => 'test',
        ])->assertStatus(422);
    }
}
