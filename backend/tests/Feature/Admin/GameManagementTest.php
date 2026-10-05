<?php

namespace Tests\Feature\Admin;

use App\Models\Category;
use App\Models\Game;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GameManagementTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    public function test_guests_are_redirected_to_login(): void
    {
        $this->get('/admin/games')->assertRedirect('/login');
    }

    public function test_members_without_the_flag_are_forbidden(): void
    {
        $this->actingAs(User::factory()->create())
            ->get('/admin/games')
            ->assertForbidden();
    }

    public function test_admins_see_the_game_list(): void
    {
        $game = Game::factory()->create(['title' => 'Neon Guardian']);

        $this->actingAs($this->admin())
            ->get('/admin/games')
            ->assertOk()
            ->assertSee($game->title);
    }

    public function test_a_game_can_be_created(): void
    {
        $category = Category::factory()->create();

        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Mystic Ruin',
                'category_id' => $category->id,
                'rating' => 4.7,
                'is_published' => true,
                'sort_order' => 1,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
            ])
            ->assertRedirect('/admin/games');

        $this->assertDatabaseHas('games', [
            'title' => 'Mystic Ruin',
            // The slug is derived when left blank.
            'slug' => 'mystic-ruin',
            'category_id' => $category->id,
        ]);
    }

    public function test_a_game_can_be_updated(): void
    {
        $game = Game::factory()->create(['title' => 'Old title']);

        $this->actingAs($this->admin())
            ->put("/admin/games/{$game->id}", [
                'title' => 'New title',
                'slug' => $game->slug,
                'rating' => 4.2,
                'is_published' => false,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
            ])
            ->assertRedirect('/admin/games');

        $this->assertDatabaseHas('games', [
            'id' => $game->id,
            'title' => 'New title',
            'is_published' => false,
        ]);
    }

    public function test_a_game_can_be_deleted(): void
    {
        $game = Game::factory()->create();

        $this->actingAs($this->admin())
            ->delete("/admin/games/{$game->id}")
            ->assertRedirect();

        $this->assertDatabaseMissing('games', ['id' => $game->id]);
    }

    public function test_the_rating_is_bounded(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Impossible',
                'rating' => 9,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
            ])
            ->assertSessionHasErrors('rating');

        $this->assertDatabaseCount('games', 0);
    }
}
