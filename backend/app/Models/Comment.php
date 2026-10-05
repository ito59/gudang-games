<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Comment extends Model
{
    use HasFactory;

    protected $fillable = ['post_id', 'user_id', 'body'];

    protected static function booted(): void
    {
        // Keeps posts.comments_count honest without a separate count query
        // on every feed request.
        static::created(fn (Comment $comment) => $comment->post?->increment('comments_count'));
        static::deleted(fn (Comment $comment) => $comment->post?->decrement('comments_count'));
    }

    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
