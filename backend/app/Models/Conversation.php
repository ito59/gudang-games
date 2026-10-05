<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

/**
 * A thread between members. One-to-one for now, which is why [pairKey] exists;
 * the participants live in a pivot so groups need no reshaping later.
 */
class Conversation extends Model
{
    use HasFactory;

    protected $fillable = ['pair_key', 'last_message_at'];

    protected function casts(): array
    {
        return ['last_message_at' => 'datetime'];
    }

    public function participants(): BelongsToMany
    {
        return $this->belongsToMany(User::class)
            ->withPivot('last_read_message_id')
            ->withTimestamps();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    /**
     * The last thing said, for the conversation list.
     *
     * A relation rather than `with(['messages' => fn ($q) => $q->limit(1)])`:
     * on a MySQL without window functions that eager-load falls back to
     * session variables and a HAVING on a non-grouping field, which older
     * servers reject outright. This resolves to a plain `max(id)` subquery
     * that any MySQL understands.
     */
    public function latestMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }

    /** Ordered so the same two members always produce the same key. */
    public static function pairKey(int $a, int $b): string
    {
        return $a < $b ? "$a:$b" : "$b:$a";
    }

    /**
     * The thread between these two, opened if this is their first message.
     *
     * Wrapped in a transaction and re-read on a unique clash, so two devices
     * tapping Message at once cannot make a second thread.
     */
    public static function between(User $viewer, User $other): self
    {
        $key = self::pairKey($viewer->id, $other->id);

        $existing = self::where('pair_key', $key)->first();
        if ($existing !== null) {
            return $existing;
        }

        try {
            return DB::transaction(function () use ($key, $viewer, $other) {
                $conversation = self::create(['pair_key' => $key]);
                $conversation->participants()->attach([$viewer->id, $other->id]);

                return $conversation;
            });
        } catch (QueryException $e) {
            // The other device won the race. The unique index is what makes
            // that safe; this just picks up the thread it created.
            $conversation = self::where('pair_key', $key)->first();

            if ($conversation === null) {
                throw $e;
            }

            return $conversation;
        }
    }

    /**
     * Threads this member is in, most recently spoken in first.
     *
     * Joined rather than `whereHas`, because the join also brings that
     * member's `last_read_message_id` into reach — an unread count needs it.
     * The
     * select is set here so a later `withCount` adds to it rather than being
     * thrown away by a select that came after.
     */
    public function scopeForMember(Builder $query, User $user): Builder
    {
        return $query
            ->select('conversations.*')
            ->join('conversation_user', function ($join) use ($user) {
                $join->on('conversation_user.conversation_id', '=', 'conversations.id')
                    ->where('conversation_user.user_id', '=', $user->id);
            })
            ->orderByDesc('conversations.last_message_at')
            ->orderByDesc('conversations.id');
    }

    public function includes(User $user): bool
    {
        return $this->participants->contains('id', $user->id);
    }

    /** The person on the other side, from [$viewer]'s seat. */
    public function otherThan(User $viewer): ?User
    {
        return $this->participants->firstWhere('id', '!=', $viewer->id);
    }
}
