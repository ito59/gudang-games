<?php

namespace App\Console\Commands;

use App\Models\Category;
use App\Models\Game;
use App\Services\GameBundleExtractor;
use App\Services\ImageStore;
use Illuminate\Console\Command;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Loads a folder of game ZIPs in one go, instead of thirty trips through the
 * admin form. Each bundle goes through the same extractor as an upload, so
 * the same safety checks apply.
 *
 * The folder holds a `games.json` manifest beside the archives:
 *
 *     {
 *       "categories": [{"name": "Casino", "icon": "trophy"}],
 *       "games": [
 *         {"zip": "roulette.zip", "title": "Roulette", "category": "Casino",
 *          "cover": "covers/roulette.jpg", "description": "..."}
 *       ]
 *     }
 *
 * Running it again updates games by slug rather than duplicating them, so
 * the same folder can be imported on every server.
 */
class ImportGames extends Command
{
    protected $signature = 'games:import
        {folder : Folder holding games.json and the ZIP files}
        {--unpublished : Import as drafts instead of publishing}';

    protected $description = 'Import HTML5 game ZIPs listed in a games.json manifest';

    public function handle(GameBundleExtractor $extractor): int
    {
        $folder = rtrim((string) $this->argument('folder'), '/');
        $manifestPath = $folder.'/games.json';

        if (! is_file($manifestPath)) {
            $this->error("No games.json in {$folder}.");

            return self::FAILURE;
        }

        $manifest = json_decode((string) file_get_contents($manifestPath), true);

        if (! is_array($manifest) || ! is_array($manifest['games'] ?? null)) {
            $this->error('games.json is not valid: it needs a "games" list.');

            return self::FAILURE;
        }

        // A game may name a category the list leaves out; it is created too
        // rather than the game silently landing uncategorised.
        $named = collect($manifest['games'])
            ->pluck('category')
            ->filter()
            ->map(fn ($name) => ['name' => (string) $name]);
        $categories = $this->categories([...($manifest['categories'] ?? []), ...$named]);
        $failed = 0;

        foreach ($manifest['games'] as $entry) {
            $title = (string) ($entry['title'] ?? '');
            $zip = $folder.'/'.($entry['zip'] ?? '');

            if ($title === '' || ! is_file($zip)) {
                $this->warn("Skipped {$title}: missing title or ZIP.");
                $failed++;

                continue;
            }

            try {
                $this->importOne($extractor, $entry, $folder, $categories);
                $this->line("  <info>✓</info> {$title}");
            } catch (RuntimeException $e) {
                $this->line("  <error>✗</error> {$title}: {$e->getMessage()}");
                $failed++;
            }
        }

        $this->newLine();
        $this->info(sprintf('%d imported, %d failed.', count($manifest['games']) - $failed, $failed));

        return $failed === 0 ? self::SUCCESS : self::FAILURE;
    }

    /**
     * Finds or creates each category the manifest names.
     *
     * @param  list<array{name: string, icon?: string}>  $list
     * @return array<string, int> category id by name
     */
    private function categories(array $list): array
    {
        $ids = Category::pluck('id', 'name')->all();
        $order = (int) Category::max('sort_order');

        foreach ($list as $item) {
            $name = (string) ($item['name'] ?? '');
            if ($name === '' || isset($ids[$name])) {
                continue;
            }

            $category = Category::create([
                'name' => $name,
                'icon' => $item['icon'] ?? 'sports_esports',
                'sort_order' => ++$order,
            ]);
            $ids[$name] = $category->id;
            $this->line("  <comment>+</comment> category {$name}");
        }

        return $ids;
    }

    /**
     * @param  array<string, mixed>  $entry
     * @param  array<string, int>  $categories
     */
    private function importOne(
        GameBundleExtractor $extractor,
        array $entry,
        string $folder,
        array $categories,
    ): void {
        $title = (string) $entry['title'];
        $slug = (string) ($entry['slug'] ?? Str::slug($title));

        $game = Game::firstOrNew(['slug' => $slug]);
        $game->fill([
            'title' => $title,
            'description' => $entry['description'] ?? $game->description,
            'category_id' => $categories[$entry['category'] ?? ''] ?? $game->category_id,
            'is_published' => ! $this->option('unpublished'),
        ]);
        $game->rating ??= 0;

        // Extracted before anything is saved: a rejected bundle leaves the
        // existing game exactly as it was.
        $bundle = $extractor->extract($this->asUpload($folder.'/'.$entry['zip']), $slug);

        $game->source_type = Game::SOURCE_ZIP;
        $game->game_url = null;
        $game->bundle_path = $bundle['path'];
        $game->entry_path = $bundle['entry'];
        $game->bundle_size = $bundle['size'];

        $cover = $folder.'/'.($entry['cover'] ?? '');
        if (filled($entry['cover'] ?? null) && is_file($cover)) {
            $game->deleteCoverFile();
            $game->cover_path = (new ImageStore(maxEdge: 1200))
                ->store($this->asUpload($cover), 'covers');
        }

        $game->save();
    }

    /** Wraps a file on disk so the upload-handling services accept it. */
    private function asUpload(string $path): UploadedFile
    {
        return new UploadedFile($path, basename($path), null, null, true);
    }
}
