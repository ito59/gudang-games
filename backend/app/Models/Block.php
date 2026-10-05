<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One member deciding they are done with another.
 *
 * A block is one-directional as a record and two-directional in effect: the
 * person who blocked stops seeing the other, and the other also stops being
 * able to reach them. Anything less leaves the blocked person able to keep
 * talking into a room the blocker can no longer see.
 */
class Block extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'blocked_user_id'];

    public function blocker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function blocked(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocked_user_id');
    }
}
