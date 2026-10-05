<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class GamePlayTest extends TestCase
{
    use RefreshDatabase;

    private function hostedGame(array $attributes = []): Game
    {
        Storage::fake('local');

        $game = Game::factory()->create(array_merge([
            'title' => 'Hosted Game',
            'slug' => 'hosted-game',
            'source_type' => Game::SOURCE_ZIP,
            'bundle_path' => 'games/hosted-game',
            'entry_path' => 'index.html',
            'is_published' => true,
        ], $attributes));

        Storage::disk('local')->put('games/hosted-game/index.html', '<html>play</html>');
        Storage::disk('local')->put('games/hosted-game/js/main.js', 'console.log(1)');
        Storage::disk('local')->put('games/hosted-game/core.wasm', 'fake-wasm');

        return $game;
    }

    public function test_the_entry_point_is_served(): void
    {
        $this->hostedGame();

        $response = $this->get('/games/hosted-game/play/index.html')
            ->assertOk()
            ->assertHeader('content-type', 'text/html; charset=UTF-8');

        // A streamed BinaryFileResponse has no buffered body, so the file
        // it points at is what gets checked.
        $this->assertSame(
            '<html>play</html>',
            file_get_contents($response->baseResponse->getFile()->getPathname())
        );
    }

    public function test_the_bare_play_url_redirects_to_the_entry_file(): void
    {
        $game = $this->hostedGame();

        // Browsers resolve a relative asset URL against the directory of the
        // page URL. Served bare at ".../play", "js/main.js" would resolve to
        // ".../hosted-game/js/main.js" and 404, so the entry must be
        // addressed by filename.
        $this->get('/games/hosted-game/play')
            ->assertRedirect('/games/hosted-game/play/index.html');

        $this->assertStringEndsWith('/play/index.html', $game->play_url);
    }

    public function test_a_relative_asset_resolves_from_the_entry_url(): void
    {
        $this->hostedGame();

        $page = '/games/hosted-game/play/index.html';
        // What a browser would request for src="js/main.js".
        $resolved = dirname($page).'/js/main.js';

        $this->assertSame('/games/hosted-game/play/js/main.js', $resolved);
        $this->get($resolved)->assertOk();
    }

    public function test_bundle_assets_are_served_with_correct_types(): void
    {
        $this->hostedGame();

        $this->get('/games/hosted-game/play/js/main.js')
            ->assertOk()
            // text/plain here would break module scripts.
            ->assertHeader('content-type', 'text/javascript; charset=UTF-8');

        $this->get('/games/hosted-game/play/core.wasm')
            ->assertOk()
            // Required for WebAssembly streaming compilation.
            ->assertHeader('content-type', 'application/wasm');
    }

    public function test_files_are_not_reachable_from_the_public_disk(): void
    {
        $this->hostedGame();

        // The bundle must not sit anywhere the web server serves directly.
        Storage::fake('public');
        $this->assertFalse(Storage::disk('public')->exists('games/hosted-game/index.html'));
    }

    public function test_a_missing_file_is_a_404(): void
    {
        $this->hostedGame();

        $this->get('/games/hosted-game/play/nope.js')->assertNotFound();
    }

    public function test_path_traversal_through_the_url_is_rejected(): void
    {
        $this->hostedGame();
        Storage::disk('local')->put('secret.txt', 'do not leak');

        foreach (['../secret.txt', '../../secret.txt', '..%2Fsecret.txt'] as $attempt) {
            $this->get('/games/hosted-game/play/'.$attempt)->assertNotFound();
        }

        $this->assertSame('do not leak', Storage::disk('local')->get('secret.txt'));
    }

    public function test_an_unpublished_game_is_hidden_from_the_public(): void
    {
        $this->hostedGame(['is_published' => false]);

        $this->get('/games/hosted-game/play/index.html')->assertNotFound();
    }

    public function test_an_admin_can_preview_an_unpublished_game(): void
    {
        $this->hostedGame(['is_published' => false]);

        $this->actingAs(User::factory()->admin()->create())
            ->get('/games/hosted-game/play/index.html')
            ->assertOk();
    }

    public function test_a_member_cannot_preview_an_unpublished_game(): void
    {
        $this->hostedGame(['is_published' => false]);

        $this->actingAs(User::factory()->create())
            ->get('/games/hosted-game/play/index.html')
            ->assertNotFound();
    }

    public function test_a_url_game_has_nothing_to_play_here(): void
    {
        Game::factory()->create([
            'slug' => 'linked-game',
            'source_type' => Game::SOURCE_URL,
            'game_url' => 'https://games.example.com/x',
        ]);

        $this->get('/games/linked-game/play')->assertNotFound();
    }
}
