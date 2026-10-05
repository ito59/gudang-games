<?php

namespace Tests\Feature\Admin;

use App\Models\Game;
use App\Models\User;
use App\Services\GameBundleExtractor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;
use ZipArchive;

class GameBundleTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    /**
     * @param  array<string, string>  $entries
     */
    private function zip(array $entries, string $name = 'game.zip'): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'zip').'.zip';

        $zip = new ZipArchive;
        $zip->open($path, ZipArchive::CREATE | ZipArchive::OVERWRITE);
        foreach ($entries as $entry => $contents) {
            $zip->addFromString($entry, $contents);
        }
        $zip->close();

        return new UploadedFile($path, $name, 'application/zip', null, true);
    }

    /**
     * @param  array<string, string>  $entries
     */
    private function upload(array $entries, array $overrides = []): TestResponse
    {
        return $this->actingAs($this->admin())->post('/admin/games', array_merge([
            'title' => 'Bundled Game',
            'rating' => 4.5,
            'sort_order' => 0,
            'source_type' => 'zip',
            'bundle' => $this->zip($entries),
        ], $overrides));
    }

    public function test_a_zip_is_extracted_and_the_entry_point_found(): void
    {
        Storage::fake('local');

        $this->upload([
            'index.html' => '<html>game</html>',
            'js/main.js' => 'console.log(1)',
            'art/sprite.png' => 'png-bytes',
        ])->assertRedirect('/admin/games');

        $game = Game::firstOrFail();

        $this->assertSame('zip', $game->source_type);
        $this->assertSame('games/bundled-game', $game->bundle_path);
        // Relative to the bundle, so the play route can resolve any file.
        $this->assertSame('index.html', $game->entry_path);

        Storage::disk('local')->assertExists('games/bundled-game/index.html');
        Storage::disk('local')->assertExists('games/bundled-game/js/main.js');
        // Streamed by the app, never exposed under /storage.
        $this->assertStringContainsString('/games/bundled-game/play', $game->play_url);
        $this->assertStringNotContainsString('/storage/', $game->play_url);
    }

    public function test_a_single_wrapping_folder_is_stripped(): void
    {
        Storage::fake('local');

        // Zipping a folder is the common case; the entry must still be at root.
        $this->upload([
            'my-game/index.html' => '<html>game</html>',
            'my-game/js/main.js' => 'x',
        ])->assertRedirect('/admin/games');

        Storage::disk('local')->assertExists('games/bundled-game/index.html');
        Storage::disk('local')->assertExists('games/bundled-game/js/main.js');
        Storage::disk('local')->assertMissing('games/bundled-game/my-game/index.html');
    }

    public function test_an_index_nested_several_levels_deep_is_found(): void
    {
        Storage::fake('local');

        // Build output commonly lands in dist/game/, not at the root.
        $this->upload([
            'dist/game/index.html' => '<html>game</html>',
            'dist/game/js/main.js' => 'x',
        ])->assertRedirect('/admin/games');

        $game = Game::firstOrFail();

        $this->assertSame('index.html', $game->entry_path);
        Storage::disk('local')->assertExists('games/bundled-game/index.html');
        Storage::disk('local')->assertExists('games/bundled-game/js/main.js');
    }

    public function test_siblings_outside_the_game_folder_are_dropped(): void
    {
        Storage::fake('local');

        $this->upload([
            'game/index.html' => '<html>game</html>',
            'game/js/main.js' => 'x',
            'docs/readme.txt' => 'not part of the game',
        ])->assertRedirect('/admin/games');

        Storage::disk('local')->assertExists('games/bundled-game/index.html');
        Storage::disk('local')->assertExists('games/bundled-game/js/main.js');
        Storage::disk('local')->assertMissing('games/bundled-game/docs/readme.txt');
    }

    public function test_a_capitalised_index_is_accepted(): void
    {
        Storage::fake('local');

        $this->upload(['Index.html' => '<html>game</html>'])
            ->assertRedirect('/admin/games');

        $this->assertSame('Index.html', Game::firstOrFail()->entry_path);
    }

    public function test_the_shallowest_index_wins(): void
    {
        Storage::fake('local');

        $this->upload([
            'index.html' => '<html>root</html>',
            'levels/bonus/index.html' => '<html>bonus</html>',
        ])->assertRedirect('/admin/games');

        $game = Game::firstOrFail();

        $this->assertSame('index.html', $game->entry_path);
        // The deeper one is still shipped, just not the entry point.
        Storage::disk('local')->assertExists('games/bundled-game/levels/bonus/index.html');
    }

    public function test_an_archive_without_an_index_is_rejected(): void
    {
        Storage::fake('local');

        $this->upload(['readme.txt' => 'no game here'])
            ->assertSessionHasErrors('bundle');

        $this->assertDatabaseCount('games', 0);
    }

    public function test_path_traversal_is_rejected(): void
    {
        Storage::fake('local');

        $this->upload([
            'index.html' => '<html>ok</html>',
            '../../../../etc/pwned.txt' => 'escaped',
        ])->assertSessionHasErrors('bundle');

        $this->assertDatabaseCount('games', 0);
        Storage::disk('local')->assertMissing('games/bundled-game/index.html');
    }

    public function test_executable_files_are_rejected(): void
    {
        Storage::fake('local');

        // A .php under the public disk would be executed, not served.
        $this->upload([
            'index.html' => '<html>ok</html>',
            'shell.php' => '<?php system($_GET["c"]); ?>',
        ])->assertSessionHasErrors('bundle');

        $this->assertDatabaseCount('games', 0);
    }

    public function test_htaccess_is_rejected(): void
    {
        Storage::fake('local');

        $this->upload([
            'index.html' => '<html>ok</html>',
            '.htaccess' => 'AddType application/x-httpd-php .png',
        ])->assertSessionHasErrors('bundle');
    }

    public function test_mac_metadata_is_ignored(): void
    {
        Storage::fake('local');

        $this->upload([
            'index.html' => '<html>ok</html>',
            '__MACOSX/._index.html' => 'junk',
            '.DS_Store' => 'junk',
        ])->assertRedirect('/admin/games');

        Storage::disk('local')->assertExists('games/bundled-game/index.html');
        Storage::disk('local')->assertMissing('games/bundled-game/.DS_Store');
    }

    public function test_a_url_game_needs_a_url(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Linked game',
                'rating' => 4,
                'sort_order' => 0,
                'source_type' => 'url',
            ])
            ->assertSessionHasErrors('game_url');
    }

    public function test_a_url_game_stores_its_link(): void
    {
        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Linked game',
                'rating' => 4,
                'sort_order' => 0,
                'source_type' => 'url',
                'game_url' => 'https://games.example.com/neon',
            ])
            ->assertRedirect('/admin/games');

        $game = Game::firstOrFail();

        $this->assertSame('https://games.example.com/neon', $game->play_url);
        $this->assertNull($game->bundle_path);
    }

    public function test_switching_from_zip_to_url_removes_the_bundle(): void
    {
        Storage::fake('local');

        $this->upload(['index.html' => '<html>ok</html>']);
        $game = Game::firstOrFail();
        Storage::disk('local')->assertExists('games/bundled-game/index.html');

        $this->actingAs($this->admin())->post("/admin/games/{$game->id}", [
            '_method' => 'put',
            'title' => $game->title,
            'slug' => $game->slug,
            'rating' => 4.5,
            'sort_order' => 0,
            'source_type' => 'url',
            'game_url' => 'https://games.example.com/neon',
        ])->assertRedirect('/admin/games');

        $game->refresh();

        $this->assertNull($game->bundle_path);
        $this->assertNull($game->entry_path);
        Storage::disk('local')->assertMissing('games/bundled-game/index.html');
    }

    public function test_editing_a_hosted_game_without_a_new_zip_keeps_it(): void
    {
        Storage::fake('local');

        $this->upload(['index.html' => '<html>ok</html>']);
        $game = Game::firstOrFail();

        $this->actingAs($this->admin())->post("/admin/games/{$game->id}", [
            '_method' => 'put',
            'title' => 'Renamed',
            'slug' => $game->slug,
            'rating' => 5,
            'sort_order' => 0,
            'source_type' => 'zip',
        ])->assertRedirect('/admin/games');

        $game->refresh();

        $this->assertSame('index.html', $game->entry_path);
        Storage::disk('local')->assertExists('games/bundled-game/index.html');
    }

    public function test_deleting_a_game_removes_its_bundle(): void
    {
        Storage::fake('local');

        $this->upload(['index.html' => '<html>ok</html>']);
        $game = Game::firstOrFail();

        $this->actingAs($this->admin())->delete("/admin/games/{$game->id}");

        Storage::disk('local')->assertMissing('games/bundled-game/index.html');
    }

    public function test_a_non_zip_upload_is_rejected(): void
    {
        Storage::fake('local');

        $this->actingAs($this->admin())
            ->post('/admin/games', [
                'title' => 'Bad bundle',
                'rating' => 4,
                'sort_order' => 0,
                'source_type' => 'zip',
                'bundle' => UploadedFile::fake()->create('game.txt', 10, 'text/plain'),
            ])
            ->assertSessionHasErrors('bundle');
    }

    public function test_the_extractor_caps_the_entry_count(): void
    {
        $this->assertSame(5000, GameBundleExtractor::MAX_ENTRIES);
        $this->assertContains('php', GameBundleExtractor::BLOCKED_EXTENSIONS);
    }
}
