<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CreateAdminCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_creates_an_administrator(): void
    {
        $this->artisan('admin:create', [
            '--name' => 'Ito',
            '--username' => 'ito',
            '--email' => 'ito@example.test',
            '--password' => 'correct horse 9 battery',
        ])->assertSuccessful();

        $user = User::where('email', 'ito@example.test')->firstOrFail();

        $this->assertTrue($user->is_admin);
        $this->assertTrue($user->is_active);
        // Stored hashed, never in the clear.
        $this->assertNotSame('correct horse 9 battery', $user->password);
        $this->assertTrue(\Hash::check('correct horse 9 battery', $user->password));
    }

    public function test_a_weak_password_is_refused(): void
    {
        $this->artisan('admin:create', [
            '--name' => 'Ito',
            '--username' => 'ito',
            '--email' => 'ito@example.test',
            '--password' => 'secret',
        ])->assertFailed();

        $this->assertSame(0, User::count());
    }

    public function test_a_taken_username_is_refused(): void
    {
        User::factory()->create(['username' => 'taken']);

        $this->artisan('admin:create', [
            '--name' => 'Ito',
            '--username' => 'taken',
            '--email' => 'ito@example.test',
            '--password' => 'correct horse 9 battery',
        ])->assertFailed();

        $this->assertSame(1, User::count());
    }

    public function test_an_existing_member_is_promoted_rather_than_duplicated(): void
    {
        $member = User::factory()->create([
            'email' => 'member@example.test',
            'is_admin' => false,
        ]);

        $this->artisan('admin:create', ['--email' => 'member@example.test'])
            ->expectsConfirmation(
                "{$member->name} <member@example.test> already exists. Make them an administrator?",
                'yes'
            )
            ->assertSuccessful();

        $this->assertTrue($member->fresh()->is_admin);
        $this->assertSame(1, User::count());
    }

    public function test_declining_the_promotion_changes_nothing(): void
    {
        $member = User::factory()->create([
            'email' => 'member@example.test',
            'is_admin' => false,
        ]);

        $this->artisan('admin:create', ['--email' => 'member@example.test'])
            ->expectsConfirmation(
                "{$member->name} <member@example.test> already exists. Make them an administrator?",
                'no'
            )
            ->assertFailed();

        $this->assertFalse($member->fresh()->is_admin);
    }
}
