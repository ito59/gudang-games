<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Where one install of the app can be reached.
 *
 * A token belongs to an install, not a person: reinstalling issues a new one,
 * and the same member on two devices has two. The hash is what carries the
 * unique index, since the token itself is longer than MySQL will index.
 */
class DeviceToken extends Model
{
    protected $fillable = ['user_id', 'token', 'token_hash', 'platform', 'used_at'];

    protected function casts(): array
    {
        return ['used_at' => 'datetime'];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public static function hash(string $token): string
    {
        return hash('sha256', $token);
    }

    /**
     * Records this install against this member.
     *
     * A token that turns up under a different account has changed hands —
     * somebody signed out and somebody else signed in on the same phone — so
     * it moves rather than being duplicated.
     */
    public static function remember(User $user, string $token, ?string $platform): self
    {
        return static::updateOrCreate(
            ['token_hash' => static::hash($token)],
            [
                'user_id' => $user->id,
                'token' => $token,
                'platform' => $platform,
                'used_at' => now(),
            ],
        );
    }
}
