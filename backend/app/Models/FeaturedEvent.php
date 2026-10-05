<?php

namespace App\Models;

use App\Models\Concerns\HasUploadedImage;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeaturedEvent extends Model
{
    use HasFactory, HasUploadedImage;

    protected $fillable = [
        'title', 'description', 'season', 'is_live',
        'image_path', 'game_id', 'is_published', 'sort_order',
    ];

    /** So the admin form can show the stored image without a second call. */
    protected $appends = ['image_url'];

    protected function casts(): array
    {
        return [
            'is_live' => 'boolean',
            'is_published' => 'boolean',
        ];
    }

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }
}
