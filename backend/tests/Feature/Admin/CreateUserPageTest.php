<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class CreateUserPageTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    /** @return array<string, mixed> */
    private function fields(array $extra = []): array
    {
        return array_merge([
            'name' => 'Ito',
            'username' => 'ito',
            'email' => 'ito@example.test',
            'password' => 'correct horse 9 battery',
            'password_confirmation' => 'correct horse 9 battery',
        ], $extra);
    }

    public function test_an_admin_can_open_the_form(): void
    {
        $this->actingAs($this->admin())
            ->get('/admin/users/create')
            ->assertOk()
            ->assertInertia(fn ($page) => $page
                ->component('Admin/Users/Form')
                ->where('user', null));
    }

    public function test_an_admin_can_create_another_admin(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/users', $this->fields(['is_admin' => true]))
            ->assertRedirect('/admin/users');

        $created = User::where('email', 'ito@example.test')->firstOrFail();

        $this->assertTrue($created->is_admin);
        $this->assertTrue($created->is_active);
        $this->assertTrue(Hash::check('correct horse 9 battery', $created->password));
    }

    public function test_the_new_admin_can_actually_reach_the_panel(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/users', $this->fields(['is_admin' => true]));

        // The point of the feature: not just a row with a flag.
        $this->actingAs(User::where('email', 'ito@example.test')->firstOrFail())
            ->get('/admin')
            ->assertOk();
    }

    public function test_an_account_made_without_the_flag_is_kept_out(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/users', $this->fields(['is_admin' => false]));

        $this->actingAs(User::where('email', 'ito@example.test')->firstOrFail())
            ->get('/admin')
            ->assertForbidden();
    }

    public function test_a_weak_password_is_refused(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/users', $this->fields([
                'password' => 'secret',
                'password_confirmation' => 'secret',
            ]))
            ->assertSessionHasErrors('password');

        $this->assertNull(User::where('email', 'ito@example.test')->first());
    }

    public function test_a_mistyped_confirmation_is_refused(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/users', $this->fields([
                'password_confirmation' => 'correct horse 9 batteryy',
            ]))
            ->assertSessionHasErrors('password');
    }

    public function test_a_taken_email_or_username_is_refused(): void
    {
        User::factory()->create(['email' => 'taken@example.test', 'username' => 'taken']);
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post('/admin/users', $this->fields(['email' => 'taken@example.test']))
            ->assertSessionHasErrors('email');

        $this->actingAs($admin)
            ->post('/admin/users', $this->fields(['username' => 'taken']))
            ->assertSessionHasErrors('username');
    }

    public function test_a_member_cannot_mint_an_admin(): void
    {
        // The whole point of the guard: without it, any signed-in member
        // could POST here and hand themselves the panel.
        $this->actingAs(User::factory()->create(['is_admin' => false]))
            ->post('/admin/users', $this->fields(['is_admin' => true]))
            ->assertForbidden();

        $this->assertNull(User::where('email', 'ito@example.test')->first());
    }

    public function test_a_stranger_cannot_either(): void
    {
        $this->post('/admin/users', $this->fields(['is_admin' => true]))
            ->assertRedirect('/login');

        $this->assertNull(User::where('email', 'ito@example.test')->first());
    }
}
