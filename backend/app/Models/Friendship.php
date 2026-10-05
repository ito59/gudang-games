<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A friendship, from the request that started it through to acceptance.
 *
 * Rows are directed — `user_id` asked, `friend_id` answers — but an accepted
 * row means the same thing read from either side.
 */
class Friendship extends Model
{
    public const pending = 'pending';

    public const accepted = 'accepted';

    protected $fillable = ['user_id', 'friend_id', 'status', 'accepted_at'];

    protected function casts(): array
    {
        return ['accepted_at' => 'datetime'];
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function addressee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'friend_id');
    }

    public function isAccepted(): bool
    {
        return $this->status === self::accepted;
    }
}
