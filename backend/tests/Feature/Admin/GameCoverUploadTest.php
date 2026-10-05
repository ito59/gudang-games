<?php

namespace Tests\Feature\Admin;

use App\Models\Game;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class GameCoverUploadTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    public function test_a_cover_can_be_uploaded_when_creating_a_game(): void
    {
        Storage::fake('public');

        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Neon Guardian',
                'rating' => 4.9,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'cover' => UploadedFile::fake()->image('cover.jpg', 800, 600),
            ])
            ->assertRedirect('/admin/games');

        $game = Game::firstOrFail();

        $this->assertNotNull($game->cover_path);
        Storage::disk('public')->assertExists($game->cover_path);
        $this->assertStringContainsString('/storage/', $game->cover_url);
    }

    public function test_replacing_a_cover_deletes_the_previous_file(): void
    {
        Storage::fake('public');
        $admin = $this->admin();

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'First',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'cover' => UploadedFile::fake()->image('one.jpg'),
        ]);

        $game = Game::firstOrFail();
        $original = $game->cover_path;

        $this->actingAs($admin)->post("/admin/games/{$game->id}", [
            '_method' => 'put',
            'title' => 'First',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'cover' => UploadedFile::fake()->image('two.jpg'),
        ])->assertRedirect('/admin/games');

        $replacement = $game->fresh()->cover_path;

        $this->assertNotSame($original, $replacement);
        // The old file must not linger on disk.
        Storage::disk('public')->assertMissing($original);
        Storage::disk('public')->assertExists($replacement);
    }

    public function test_a_cover_can_be_removed(): void
    {
        Storage::fake('public');
        $admin = $this->admin();

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'With cover',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'cover' => UploadedFile::fake()->image('cover.jpg'),
        ]);

        $game = Game::firstOrFail();
        $path = $game->cover_path;

        $this->actingAs($admin)->post("/admin/games/{$game->id}", [
            '_method' => 'put',
            'title' => 'With cover',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'remove_cover' => true,
        ])->assertRedirect('/admin/games');

        $this->assertNull($game->fresh()->cover_path);
        Storage::disk('public')->assertMissing($path);
    }

    public function test_editing_without_touching_the_cover_keeps_it(): void
    {
        Storage::fake('public');
        $admin = $this->admin();

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'Keep me',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'cover' => UploadedFile::fake()->image('cover.jpg'),
        ]);

        $game = Game::firstOrFail();
        $path = $game->cover_path;

        $this->actingAs($admin)->post("/admin/games/{$game->id}", [
            '_method' => 'put',
            'title' => 'Renamed',
            'rating' => 4.5,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
        ])->assertRedirect('/admin/games');

        $this->assertSame($path, $game->fresh()->cover_path);
        Storage::disk('public')->assertExists($path);
    }

    public function test_deleting_a_game_removes_its_cover(): void
    {
        Storage::fake('public');
        $admin = $this->admin();

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'Doomed',
            'rating' => 4,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/demo',
            'cover' => UploadedFile::fake()->image('cover.jpg'),
        ]);

        $game = Game::firstOrFail();
        $path = $game->cover_path;

        $this->actingAs($admin)->delete("/admin/games/{$game->id}");

        Storage::disk('public')->assertMissing($path);
    }

    public function test_a_non_image_is_rejected(): void
    {
        Storage::fake('public');

        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Bad upload',
                'rating' => 4,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'cover' => UploadedFile::fake()->create('notes.pdf', 100, 'application/pdf'),
            ])
            ->assertSessionHasErrors('cover');

        $this->assertDatabaseCount('games', 0);
    }

    public function test_an_oversized_image_is_rejected(): void
    {
        Storage::fake('public');

        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Too big',
                'rating' => 4,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/demo',
                // 5 MB, over the 4 MB cap.
                'cover' => UploadedFile::fake()->image('huge.jpg')->size(5120),
            ])
            ->assertSessionHasErrors('cover');
    }
}
