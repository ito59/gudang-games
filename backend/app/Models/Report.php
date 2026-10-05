<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * Somebody telling us about something. Reports are evidence, not verdicts:
 * nothing is hidden because it was reported, an admin decides.
 */
class Report extends Model
{
    use HasFactory;

    /** What the app offers as a reason, in the order it offers them. */
    public const reasons = [
        'spam' => 'Spam or scam',
        'harassment' => 'Harassment or bullying',
        'hate' => 'Hate speech',
        'sexual' => 'Sexual content',
        'violence' => 'Violence or threats',
        'other' => 'Something else',
    ];

    /** The kinds of thing the app may report, by the name it sends. */
    public const targets = [
        'message' => Message::class,
        'post' => Post::class,
        'comment' => Comment::class,
        'user' => User::class,
    ];

    public const pending = 'pending';

    public const resolved = 'resolved';

    public const dismissed = 'dismissed';

    protected $fillable = [
        'reporter_id', 'reportable_type', 'reportable_id', 'reason',
        'note', 'excerpt', 'reported_user_id', 'status', 'resolution',
        'resolved_by', 'resolved_at',
    ];

    protected function casts(): array
    {
        return ['resolved_at' => 'datetime'];
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    /** The member being reported — the author, or the member themselves. */
    public function reportedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_user_id');
    }

    public function resolver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }

    /**
     * Null once the content has been deleted, which is why [excerpt] is
     * stored alongside rather than read back through here.
     */
    public function reportable(): MorphTo
    {
        return $this->morphTo();
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', self::pending);
    }

    /** The app's name for this kind of target: `message`, `post`, … */
    public function getTargetNameAttribute(): string
    {
        return array_search($this->reportable_type, self::targets, true) ?: 'unknown';
    }

    public function isPending(): bool
    {
        return $this->status === self::pending;
    }
}
