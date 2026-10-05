<?php

namespace App\Models;

use App\Services\Moderation\Verdict;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

/** Something the filter refused, kept so the filter itself can be judged. */
class ModerationEvent extends Model
{
    use HasFactory;

    public const contexts = ['chat', 'post', 'comment'];

    protected $fillable = ['user_id', 'context', 'reason', 'rule', 'body'];

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Writes the event for a rejected [$verdict]. Never throws: the point of
     * the rejection is that the text did not get through, and a log that
     * cannot be written must not turn that into a 500.
     */
    public static function record(Verdict $verdict, ?User $author, string $context, string $body): void
    {
        if ($verdict->allowed) {
            return;
        }

        try {
            static::create([
                'user_id' => $author?->id,
                'context' => $context,
                'reason' => $verdict->reason,
                'rule' => Str::limit((string) $verdict->match, 60, ''),
                'body' => Str::limit($body, 2000, ''),
            ]);
        } catch (\Throwable $e) {
            report($e);
        }
    }
}
