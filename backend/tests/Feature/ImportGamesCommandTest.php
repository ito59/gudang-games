<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Game;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use ZipArchive;

class ImportGamesCommandTest extends TestCase
{
    use RefreshDatabase;

    private string $folder;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('local');
        Storage::fake('public');

        $this->folder = sys_get_temp_dir().'/games-import-'.uniqid();
        File::makeDirectory($this->folder);
    }

    protected function tearDown(): void
    {
        File::deleteDirectory($this->folder);

        parent::tearDown();
    }

    /** @param  array<string, string>  $entries */
    private function zip(string $name, array $entries): void
    {
        $zip = new ZipArchive;
        $zip->open($this->folder.'/'.$name, ZipArchive::CREATE | ZipArchive::OVERWRITE);
        foreach ($entries as $entry => $contents) {
            $zip->addFromString($entry, $contents);
        }
        $zip->close();
    }

    /** @param  array<string, mixed>  $manifest */
    private function manifest(array $manifest): void
    {
        File::put($this->folder.'/games.json', json_encode($manifest));
    }

    public function test_it_imports_every_game_in_the_manifest(): void
    {
        $this->zip('roulette.zip', ['index.html' => '<html>spin</html>', 'js/game.js' => '1']);
        $this->manifest([
            'categories' => [['name' => 'Casino', 'icon' => 'trophy']],
            'games' => [['zip' => 'roulette.zip', 'title' => 'Roulette', 'category' => 'Casino']],
        ]);

        $this->artisan('games:import', ['folder' => $this->folder])->assertSuccessful();

        $game = Game::where('slug', 'roulette')->firstOrFail();
        $this->assertSame('zip', $game->source_type);
        $this->assertSame('index.html', $game->entry_path);
        $this->assertTrue($game->is_published);
        $this->assertSame('Casino', $game->category->name);
        $this->assertSame('trophy', $game->category->icon);
        Storage::disk('local')->assertExists('games/roulette/js/game.js');
    }

    public function test_running_it_again_updates_rather_than_duplicates(): void
    {
        $this->zip('roulette.zip', ['index.html' => 'v1']);
        $this->manifest(['games' => [['zip' => 'roulette.zip', 'title' => 'Roulette']]]);
        $this->artisan('games:import', ['folder' => $this->folder])->assertSuccessful();

        $this->zip('roulette.zip', ['index.html' => 'v2']);
        $this->artisan('games:import', ['folder' => $this->folder])->assertSuccessful();

        $this->assertSame(1, Game::count());
        $this->assertSame('v2', Storage::disk('local')->get('games/roulette/index.html'));
    }

    public function test_an_unsafe_bundle_is_refused_and_the_rest_still_import(): void
    {
        $this->zip('bad.zip', ['index.html' => 'x', 'api/save.php' => '<?php']);
        $this->zip('good.zip', ['index.html' => 'ok']);
        $this->manifest(['games' => [
            ['zip' => 'bad.zip', 'title' => 'Bad'],
            ['zip' => 'good.zip', 'title' => 'Good'],
        ]]);

        $this->artisan('games:import', ['folder' => $this->folder])->assertFailed();

        $this->assertFalse(Game::where('slug', 'bad')->exists());
        $this->assertTrue(Game::where('slug', 'good')->exists());
    }

    public function test_drafts_on_request_and_existing_categories_are_reused(): void
    {
        Category::create(['name' => 'Casino', 'icon' => 'trophy']);
        $this->zip('slots.zip', ['index.html' => 'x']);
        $this->manifest([
            'categories' => [['name' => 'Casino', 'icon' => 'bolt']],
            'games' => [['zip' => 'slots.zip', 'title' => 'Slots', 'category' => 'Casino']],
        ]);

        $this->artisan('games:import', ['folder' => $this->folder, '--unpublished' => true])
            ->assertSuccessful();

        $this->assertSame(1, Category::count());
        $this->assertFalse(Game::firstOrFail()->is_published);
    }

    public function test_a_category_named_only_by_a_game_is_created(): void
    {
        $this->zip('soccer.zip', ['index.html' => 'x']);
        $this->manifest(['games' => [
            ['zip' => 'soccer.zip', 'title' => 'Bubble Soccer', 'category' => 'Sports'],
        ]]);

        $this->artisan('games:import', ['folder' => $this->folder])->assertSuccessful();

        $this->assertSame('Sports', Game::firstOrFail()->category?->name);
    }
}
