<?php

namespace App\Models;

use App\Services\GameBundleExtractor;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Game extends Model
{
    use HasFactory;

    /** How a game is delivered. */
    public const SOURCE_URL = 'url';

    public const SOURCE_ZIP = 'zip';

    public const SOURCE_TYPES = [self::SOURCE_URL, self::SOURCE_ZIP];

    protected $fillable = [
        'title', 'slug', 'category_id', 'description',
        'rating', 'plays_count', 'cover_path', 'is_published', 'is_featured',
        'sort_order',
        'source_type', 'game_url', 'bundle_path', 'entry_path', 'bundle_size',
        'trailer_path', 'trailer_mime', 'trailer_size',
    ];

    /** Where trailers live on the protected disk. */
    public const TRAILER_DIRECTORY = 'trailers';

    /** Exposed so the admin UI and the API can use them directly. */
    protected $appends = ['cover_url', 'play_url', 'trailer_url'];

    protected function casts(): array
    {
        return [
            'rating' => 'float',
            'plays_count' => 'integer',
            'is_published' => 'boolean',
            'is_featured' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (Game $game) {
            $game->slug = $game->slug ?: Str::slug($game->title);
        });

        // Deleting the row must not leave uploads behind.
        static::deleting(function (Game $game) {
            $game->deleteCoverFile();
            $game->deleteBundle();
            $game->deleteTrailer();
        });
    }

    public function getCoverUrlAttribute(): ?string
    {
        if (blank($this->cover_path)) {
            return null;
        }

        // Paths seeded from the Flutter bundle are not on our disk.
        if (str_starts_with($this->cover_path, 'assets/')) {
            return null;
        }

        return Storage::disk('public')->url($this->cover_path);
    }

    /** Where the game actually opens, whichever source it uses. */
    public function getPlayUrlAttribute(): ?string
    {
        if ($this->source_type === self::SOURCE_ZIP) {
            // Streamed by GamePlayController; the files are not web-served.
            return blank($this->bundle_path)
                ? null
                // Includes the entry filename so relative asset URLs inside
                // the game resolve against the bundle, not its parent.
                : route('games.play', [
                    'game' => $this->slug,
                    'path' => $this->entry_path ?: 'index.html',
                ]);
        }

        return $this->game_url ?: null;
    }

    /** Streamed by TrailerController; not served from a public directory. */
    public function getTrailerUrlAttribute(): ?string
    {
        return blank($this->trailer_path)
            ? null
            : route('games.trailer', ['game' => $this->slug]);
    }

    /** Counts one play. Atomic so concurrent opens cannot lose a count. */
    public function recordPlay(): void
    {
        $this->increment('plays_count');
    }

    public function hasTrailer(): bool
    {
        return filled($this->trailer_path);
    }

    public function deleteTrailer(): void
    {
        if (filled($this->trailer_path)) {
            Storage::disk(GameBundleExtractor::DISK)->delete($this->trailer_path);
        }
    }

    public function isHosted(): bool
    {
        return $this->source_type === self::SOURCE_ZIP;
    }

    /** Removes an extracted bundle and forgets it. */
    public function deleteBundle(): void
    {
        if (filled($this->bundle_path)) {
            Storage::disk(GameBundleExtractor::DISK)->deleteDirectory($this->bundle_path);
        }
    }

    public function deleteCoverFile(): void
    {
        if (filled($this->cover_path) && ! str_starts_with($this->cover_path, 'assets/')) {
            Storage::disk('public')->delete($this->cover_path);
        }
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }

    /** Only a published game can be promoted to the carousel. */
    public function scopeFeatured(Builder $query): Builder
    {
        return $query->published()->where('is_featured', true);
    }
}
