<?php

namespace App\Models;

use App\Models\Concerns\HasUploadedImage;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    use HasFactory, HasUploadedImage;

    /** Feed filter chips in the app. */
    public const KINDS = ['clip', 'squad', 'update', 'news'];

    /**
     * Announcements from the team. Written from the dashboard, not the app,
     * and shown as a headline the feed can open full page.
     */
    public const news = 'news';

    protected $fillable = [
        'user_id', 'game_id', 'title', 'body', 'kind', 'image_path',
        'comments_count', 'is_published', 'published_at',
    ];

    /** So the admin form can show the stored image without a second call. */
    protected $appends = ['image_url'];

    protected function casts(): array
    {
        return [
            'is_published' => 'boolean',
            'published_at' => 'datetime',
        ];
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class)->latest('created_at');
    }

    public function likes(): HasMany
    {
        return $this->hasMany(PostLike::class);
    }

    public function likers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'post_likes')->withTimestamps();
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }

    public function isNews(): bool
    {
        return $this->kind === self::news;
    }
}
