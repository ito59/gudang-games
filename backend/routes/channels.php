<?php

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function (User $user, int $id) {
    return $user->id === $id;
});

/*
 * A thread is only listenable by the two people in it. This is what stops a
 * signed-in member from subscribing to somebody else's conversation id.
 */
Broadcast::channel('conversation.{conversation}', function (User $user, Conversation $conversation) {
    return $conversation->participants()->whereKey($user->id)->exists();
});
