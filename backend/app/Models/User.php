<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'username',
        'email',
        'password',
        'bio',
        'location',
        'avatar_path',
        'google_avatar_url',
        'accent_color',
        'games_owned',
        'hours_played',
        'achievements',
        'playing',
        'is_admin',
        'is_active',
        'notify_chat',
        'notify_news',
    ];

    /**
     * Defaults a new model carries without a round trip to the database.
     *
     * The columns default to true as well, but a model just created holds
     * only what was inserted — leaving these null, which casts to false and
     * quietly opts somebody out of the notifications they never turned off.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'notify_chat' => true,
        'notify_news' => true,
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_seen_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'is_active' => 'boolean',
            'notify_chat' => 'boolean',
            'notify_news' => 'boolean',
        ];
    }

    /** Memos for the block lookups, which several resources ask for in turn. */
    private ?array $hiddenUserIds = null;

    private ?array $blockedUserIds = null;

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function likedPosts(): BelongsToMany
    {
        return $this->belongsToMany(Post::class, 'post_likes')->withTimestamps();
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function conversations(): BelongsToMany
    {
        return $this->belongsToMany(Conversation::class)
            ->withPivot('last_read_message_id')
            ->withTimestamps();
    }

    /** Friendships this member started. */
    public function sentFriendships(): HasMany
    {
        return $this->hasMany(Friendship::class, 'user_id');
    }

    /** Friendships somebody started with this member. */
    public function receivedFriendships(): HasMany
    {
        return $this->hasMany(Friendship::class, 'friend_id');
    }

    /** Blocks this member has placed on others. */
    public function blocks(): HasMany
    {
        return $this->hasMany(Block::class);
    }

    public function blockedUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'blocks', 'user_id', 'blocked_user_id')
            ->withTimestamps();
    }

    /** Members who have blocked this one. They are not told, and nor is it. */
    public function blockedByUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'blocks', 'blocked_user_id', 'user_id')
            ->withTimestamps();
    }

    public function hasBlocked(User $other): bool
    {
        return in_array($other->id, $this->blockedUserIds(), true);
    }

    /**
     * Who this member has blocked, as ids, held for the request.
     *
     * Memoised because a resource answers this per member: a page of twenty
     * would otherwise be twenty queries for a list that cannot change
     * halfway through rendering one response.
     *
     * @return list<int>
     */
    public function blockedUserIds(): array
    {
        return $this->blockedUserIds ??= $this->blocks()
            ->pluck('blocked_user_id')
            ->all();
    }

    /**
     * Whether these two are kept apart, whichever of them decided it.
     *
     * Every gate between members asks this rather than [hasBlocked], because
     * a block that only worked one way would leave the blocked member still
     * able to write into a thread the blocker can no longer read.
     */
    public function isSeparatedFrom(User $other): bool
    {
        return Block::query()
            ->where(fn ($q) => $q->where('user_id', $this->id)->where('blocked_user_id', $other->id))
            ->orWhere(fn ($q) => $q->where('user_id', $other->id)->where('blocked_user_id', $this->id))
            ->exists();
    }

    /**
     * Everyone this member should not see, in either direction, as ids.
     *
     * Held for the life of the request: the feed, the member strip and the
     * conversation list each need it, and it cannot change underneath a
     * single response.
     *
     * @return list<int>
     */
    public function hiddenUserIds(): array
    {
        return $this->hiddenUserIds ??= Block::query()
            ->where('user_id', $this->id)
            ->orWhere('blocked_user_id', $this->id)
            ->get(['user_id', 'blocked_user_id'])
            ->flatMap(fn (Block $block) => [$block->user_id, $block->blocked_user_id])
            ->reject(fn (int $id) => $id === $this->id)
            ->unique()
            ->values()
            ->all();
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class, 'reporter_id');
    }

    /** The row between these two, whichever of them asked first. */
    public function friendshipWith(User $other): ?Friendship
    {
        return Friendship::query()
            ->where(fn ($q) => $q->where('user_id', $this->id)->where('friend_id', $other->id))
            ->orWhere(fn ($q) => $q->where('user_id', $other->id)->where('friend_id', $this->id))
            ->first();
    }

    /**
     * How this member stands with [$viewer], in the viewer's own terms:
     * `self`, `friends`, `requested` (the viewer asked), `pending` (this
     * member asked and the viewer has yet to answer) or `none`.
     *
     * Reads the `sentFriendships` and `receivedFriendships` relations when
     * they are loaded, so a list of members costs two queries rather than two
     * per member.
     */
    public function friendshipStateFor(?User $viewer): string
    {
        if ($viewer === null) {
            return 'none';
        }

        if ($viewer->is($this)) {
            return 'self';
        }

        $row = $this->relationLoaded('sentFriendships') && $this->relationLoaded('receivedFriendships')
            ? $this->sentFriendships->firstWhere('friend_id', $viewer->id)
                ?? $this->receivedFriendships->firstWhere('user_id', $viewer->id)
            : $this->friendshipWith($viewer);

        if ($row === null) {
            return 'none';
        }

        if ($row->isAccepted()) {
            return 'friends';
        }

        // The row points at whoever has to answer it.
        return $row->friend_id === $viewer->id ? 'pending' : 'requested';
    }

    /**
     * Constrains the friendship relations to [$viewer] so a resource can read
     * the state without a query per member. A no-op when nobody is signed in.
     */
    public function scopeWithFriendshipFor(Builder $query, ?User $viewer): Builder
    {
        return $query->when($viewer, fn ($q) => $q->with([
            'sentFriendships' => fn ($r) => $r->where('friend_id', $viewer->id),
            'receivedFriendships' => fn ($r) => $r->where('user_id', $viewer->id),
        ]));
    }

    /**
     * Builds a free handle from a name or email.
     *
     * Handles are required and unique, so anything that creates a user —
     * registration included — has to supply one.
     */
    public static function uniqueUsername(string $seed): string
    {
        $base = strtolower(preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $seed)[0]));
        $base = substr($base, 0, 30) ?: 'player';

        $candidate = $base;
        $suffix = 1;

        while (static::where('username', $candidate)->exists()) {
            $candidate = $base.(++$suffix);
        }

        return $candidate;
    }

    /**
     * A URL for the uploaded photo, mirroring [Game::getCoverUrlAttribute].
     *
     * Null when there is none — and also for the seeded paths that point at
     * the Flutter bundle, which is not on our disk.
     */
    public function getAvatarUrlAttribute(): ?string
    {
        if (blank($this->avatar_path) || str_starts_with($this->avatar_path, 'assets/')) {
            return null;
        }

        return Storage::disk('public')->url($this->avatar_path);
    }

    /**
     * How long after their last request a member still counts as online. The
     * app sends a heartbeat every minute while it is open, so this covers a
     * missed beat or two on a bad connection without keeping somebody who
     * has put the phone down "online" for long.
     */
    public const ONLINE_WINDOW_SECONDS = 180;

    /** How stale `last_seen_at` may get before a request rewrites it. */
    public const PRESENCE_TOUCH_SECONDS = 30;

    /**
     * Online means the app has been heard from recently — not what `playing`
     * says, which is only what the profile shows they are into.
     */
    public function isOnline(): bool
    {
        return $this->last_seen_at !== null
            && $this->last_seen_at->gt(now()->subSeconds(self::ONLINE_WINDOW_SECONDS));
    }

    public function scopeOnline(Builder $query): Builder
    {
        return $query->where('last_seen_at', '>', now()->subSeconds(self::ONLINE_WINDOW_SECONDS));
    }

    /**
     * Records that the member is here. A plain query rather than save(), so
     * being seen does not bump `updated_at` or fire model events.
     */
    public function markSeen(): void
    {
        if ($this->last_seen_at?->gt(now()->subSeconds(self::PRESENCE_TOUCH_SECONDS))) {
            return;
        }

        $this->last_seen_at = now();
        static::whereKey($this->getKey())->toBase()->update(['last_seen_at' => $this->last_seen_at]);
    }

    /** The app went to the background, or its owner signed out. */
    public function markAway(): void
    {
        $this->last_seen_at = null;
        static::whereKey($this->getKey())->toBase()->update(['last_seen_at' => null]);
    }

    public function scopeAdmins(Builder $query): Builder
    {
        return $query->where('is_admin', true);
    }
}
