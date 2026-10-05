<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Game;
use App\Services\GameBundleExtractor;
use App\Services\ImageStore;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;
use RuntimeException;

class GameController extends Controller
{
    public function index(Request $request): Response
    {
        $games = Game::query()
            ->with('category:id,name')
            ->when($request->string('search')->trim()->value(), function ($query, string $search) {
                $query->where('title', 'like', "%{$search}%");
            })
            ->when($request->integer('category'), fn ($query, $id) => $query->where('category_id', $id))
            ->when($request->string('featured')->value() === 'yes', fn ($q) => $q->where('is_featured', true))
            ->orderBy('sort_order')
            ->orderBy('title')
            ->paginate(10)
            ->withQueryString();

        return Inertia::render('Admin/Games/Index', [
            'games' => $games,
            'categories' => Category::orderBy('sort_order')->get(['id', 'name']),
            'filters' => $request->only('search', 'category', 'featured'),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Admin/Games/Form', [
            'game' => null,
            'categories' => Category::orderBy('sort_order')->get(['id', 'name']),
            'sourceTypes' => Game::SOURCE_TYPES,
            'maxBundleMb' => intdiv($this->maxBundleKilobytes(), 1024),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->assertUploadSucceeded($request);
        $data = $this->validated($request);
        unset($data['cover'], $data['remove_cover'], $data['bundle']);

        $game = new Game($data);
        $game->slug = $game->slug ?: Str::slug($game->title);
        $this->syncCover($request, $game);
        $this->syncSource($request, $game);
        $game->save();

        return to_route('admin.games.index')->with('success', 'Game created.');
    }

    public function edit(Game $game): Response
    {
        return Inertia::render('Admin/Games/Form', [
            'game' => $game,
            'categories' => Category::orderBy('sort_order')->get(['id', 'name']),
            'sourceTypes' => Game::SOURCE_TYPES,
            'maxBundleMb' => intdiv($this->maxBundleKilobytes(), 1024),
        ]);
    }

    public function update(Request $request, Game $game): RedirectResponse
    {
        $this->assertUploadSucceeded($request);
        $data = $this->validated($request, $game);
        unset($data['cover'], $data['remove_cover'], $data['bundle']);

        $game->fill($data);
        $game->slug = $game->slug ?: Str::slug($game->title);
        $this->syncCover($request, $game);
        $this->syncSource($request, $game);
        $game->save();

        return to_route('admin.games.index')->with('success', 'Game updated.');
    }

    public function destroy(Game $game): RedirectResponse
    {
        // The model's deleting hook removes the file.
        $game->delete();

        return back()->with('success', 'Game deleted.');
    }

    /**
     * Applies an uploaded cover, or clears the current one.
     *
     * Replacing an image deletes the file it replaced, so the disk does not
     * collect an orphan every time somebody edits a game.
     */
    private function syncCover(Request $request, Game $game): void
    {
        if ($request->boolean('remove_cover')) {
            $game->deleteCoverFile();
            $game->cover_path = null;

            return;
        }

        if (! $request->hasFile('cover')) {
            return;
        }

        $game->deleteCoverFile();
        // Drawn at card size; anything larger is bandwidth nobody sees.
        $game->cover_path = (new ImageStore(maxEdge: 1200))
            ->store($request->file('cover'), 'covers');
    }

    /**
     * Applies whichever source the admin picked.
     *
     * Switching type clears the other side, so a game never carries both a
     * link and a hosted bundle.
     */
    private function syncSource(Request $request, Game $game): void
    {
        if ($game->source_type === Game::SOURCE_URL) {
            $game->deleteBundle();
            $game->bundle_path = null;
            $game->entry_path = null;
            $game->bundle_size = null;

            return;
        }

        $game->game_url = null;

        if (! $request->hasFile('bundle')) {
            return;
        }

        try {
            $bundle = app(GameBundleExtractor::class)->extract(
                $request->file('bundle'),
                $game->slug
            );
        } catch (RuntimeException $e) {
            // Logged so a rejected bundle can be diagnosed after the fact.
            Log::warning('Game bundle rejected', [
                'game' => $game->slug,
                'file' => $request->file('bundle')?->getClientOriginalName(),
                'reason' => $e->getMessage(),
            ]);

            throw ValidationException::withMessages(['bundle' => $e->getMessage()]);
        }

        $game->bundle_path = $bundle['path'];
        $game->entry_path = $bundle['entry'];
        $game->bundle_size = $bundle['size'];
    }

    /**
     * The upload cap follows php.ini rather than a number of its own, so the
     * two cannot drift apart — a hard-coded rule silently rejects files the
     * server would happily accept after the ini is raised.
     */
    public function maxBundleKilobytes(): int
    {
        $limit = min(
            $this->iniBytes((string) ini_get('upload_max_filesize')),
            $this->iniBytes((string) ini_get('post_max_size'))
        );

        // Headroom for the other form fields travelling in the same request.
        $kilobytes = intdiv($limit, 1024) - 512;

        return max(1024, $kilobytes);
    }

    /** Parses php.ini shorthand ("80M", "512K", "1G") into bytes. */
    private function iniBytes(string $value): int
    {
        $value = trim($value);
        if ($value === '') {
            return PHP_INT_MAX;
        }

        $number = (int) $value;

        return match (strtolower(substr($value, -1))) {
            'g' => $number * 1024 ** 3,
            'm' => $number * 1024 ** 2,
            'k' => $number * 1024,
            default => $number,
        };
    }

    /**
     * PHP drops an upload that exceeds its own limits before validation runs,
     * which would otherwise surface as a bare "bundle is required".
     */
    private function assertUploadSucceeded(Request $request): void
    {
        $file = $request->files->get('bundle');

        if (! $file instanceof UploadedFile || $file->isValid()) {
            return;
        }

        $message = match ($file->getError()) {
            UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => sprintf(
                'The ZIP is larger than this server accepts (upload_max_filesize = %s, '
                .'post_max_size = %s). Raise both in php.ini and restart PHP.',
                ini_get('upload_max_filesize'),
                ini_get('post_max_size')
            ),
            UPLOAD_ERR_PARTIAL => 'The upload was interrupted. Please try again.',
            UPLOAD_ERR_NO_TMP_DIR, UPLOAD_ERR_CANT_WRITE => 'The server could not store the upload.',
            default => 'The upload did not complete: '.$file->getErrorMessage(),
        };

        throw ValidationException::withMessages(['bundle' => $message]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request, ?Game $game = null): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:120'],
            'slug' => [
                'nullable', 'string', 'max:140',
                Rule::unique('games', 'slug')->ignore($game?->id),
            ],
            'category_id' => ['nullable', 'exists:categories,id'],
            'description' => ['nullable', 'string', 'max:2000'],
            'rating' => ['required', 'numeric', 'between:0,5'],
            'cover' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'remove_cover' => ['boolean'],
            'source_type' => ['required', Rule::in(Game::SOURCE_TYPES)],
            'game_url' => [
                Rule::requiredIf(fn () => $request->input('source_type') === Game::SOURCE_URL),
                'nullable', 'url', 'max:2000',
            ],
            'bundle' => [
                // Only required the first time a hosted game is saved.
                Rule::requiredIf(fn () => $request->input('source_type') === Game::SOURCE_ZIP
                    && blank($game?->bundle_path)),
                'nullable', 'file', 'mimes:zip', 'max:'.$this->maxBundleKilobytes(),
            ],
            'is_published' => ['boolean'],
            'is_featured' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ], [
            'cover.max' => 'The cover must be 4 MB or smaller.',
            'cover.mimes' => 'The cover must be a JPG, PNG or WebP image.',
            'game_url.required' => 'A game URL is required when the type is URL.',
            'bundle.required' => 'A ZIP bundle is required when the type is ZIP.',
            'bundle.mimes' => 'The bundle must be a ZIP archive.',
            'bundle.max' => sprintf(
                'The bundle must be %d MB or smaller.',
                intdiv($this->maxBundleKilobytes(), 1024)
            ),
        ]);
    }
}
