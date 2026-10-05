<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admins_can_list_and_filter_members(): void
    {
        $admin = User::factory()->admin()->create(['name' => 'Rey Anandra']);
        // Online is being heard from lately; a `playing` line alone is not it.
        User::factory()->create(['name' => 'Kirana Ayu', 'playing' => 'Quantum Rush', 'last_seen_at' => now()->subHour()]);
        User::factory()->create(['name' => 'Dita Prameswari', 'playing' => null, 'last_seen_at' => now()]);

        $this->actingAs($admin)
            ->get('/admin/users?status=online')
            ->assertOk()
            ->assertSee('Dita Prameswari')
            ->assertDontSee('Kirana Ayu');
    }

    public function test_a_member_can_be_updated(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->create();

        $this->actingAs($admin)
            ->put("/admin/users/{$member->id}", [
                'name' => 'Renamed Member',
                'username' => 'renamed',
                'email' => 'renamed@example.test',
                'accent_color' => '#14D1FF',
                'games_owned' => 5,
                'hours_played' => 10,
                'achievements' => 2,
                'is_admin' => false,
                'is_active' => false,
            ])
            ->assertRedirect('/admin/users');

        $this->assertDatabaseHas('users', [
            'id' => $member->id,
            'name' => 'Renamed Member',
            'is_active' => false,
        ]);
    }

    public function test_a_username_cannot_contain_spaces(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->create();

        $this->actingAs($admin)
            ->put("/admin/users/{$member->id}", [
                'name' => 'Someone',
                'username' => 'not a handle',
                'email' => 'someone@example.test',
                'accent_color' => '#14D1FF',
                'is_admin' => false,
                'is_active' => true,
            ])
            ->assertSessionHasErrors('username');
    }

    public function test_an_admin_cannot_delete_their_own_account(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->delete("/admin/users/{$admin->id}")
            ->assertSessionHasErrors('user');

        $this->assertDatabaseHas('users', ['id' => $admin->id]);
    }

    public function test_the_last_administrator_cannot_be_demoted(): void
    {
        $admin = User::factory()->admin()->create();

        // Demoting the only admin would lock everyone out of the panel.
        $this->actingAs($admin)
            ->put("/admin/users/{$admin->id}", [
                'name' => $admin->name,
                'username' => $admin->username,
                'email' => $admin->email,
                'accent_color' => '#14D1FF',
                'is_admin' => false,
                'is_active' => true,
            ])
            ->assertStatus(422);

        $this->assertTrue($admin->fresh()->is_admin);
    }

    public function test_an_administrator_can_be_demoted_when_another_remains(): void
    {
        $admin = User::factory()->admin()->create();
        $other = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->put("/admin/users/{$other->id}", [
                'name' => $other->name,
                'username' => $other->username,
                'email' => $other->email,
                'accent_color' => '#14D1FF',
                'is_admin' => false,
                'is_active' => true,
            ])
            ->assertRedirect('/admin/users');

        $this->assertFalse($other->fresh()->is_admin);
    }
}
