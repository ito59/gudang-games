<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Http\Resources\PostResource;
use App\Models\Post;
use App\Services\Moderation\ContentModerator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FeedController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        // The sanctum guard by name: this route is public, so the default
        // (session) guard would ignore the Bearer token the app sends and
        // report every post as unliked.
        $viewer = $request->user('sanctum');

        $posts = Post::published()
            ->with(['author:id,name,username,accent_color,avatar_path', 'game:id,title'])
            ->withCount('likes')
            // Only one extra query, whether or not somebody is signed in.
            ->when($viewer, fn ($query) => $query->withExists([
                'likes as liked_by_me' => fn ($q) => $q->where('user_id', $viewer->id),
            ]))
            // Blocked either way: their posts leave the feed, and so do
            // the posts of anyone who blocked this member.
            ->when($viewer?->hiddenUserIds(), fn ($q, $hidden) => $q->whereNotIn('user_id', $hidden))
            ->when($request->string('kind')->value(), fn ($q, $kind) => $q->where('kind', $kind))
            // Set by a member's profile page, which shows only their posts.
            ->when($request->integer('user'), fn ($q, $id) => $q->where('user_id', $id))
            ->latest('published_at')
            ->paginate($request->integer('per_page', 20));

        return PostResource::collection($posts)->response();
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'body' => ['required', 'string', 'max:1000'],
            // News is written from the dashboard and speaks for the team, so
            // the app cannot post it however the request is shaped.
            'kind' => ['required', Rule::in(Post::KINDS), Rule::notIn([Post::news])],
            'game_id' => ['nullable', 'exists:games,id'],
        ]);

        app(ContentModerator::class)->guard($data['body'], $request->user(), 'post');

        $post = $request->user()->posts()->create($data + [
            'published_at' => now(),
        ]);

        $post->load(['author:id,name,username,accent_color,avatar_path', 'game:id,title'])
            ->loadCount('likes');

        return (new PostResource($post))->response()->setStatusCode(201);
    }

    /** Comments on one post, oldest first so a thread reads top to bottom. */
    public function comments(Request $request, Post $post): JsonResponse
    {
        abort_unless($post->is_published, 404);

        // Public route, so the token guard by name — the same reason
        // [index] names it. Signed out there are no blocks to apply.
        $viewer = $request->user('sanctum');

        $comments = $post->comments()
            ->with('author:id,name,username,accent_color,avatar_path')
            ->when($viewer?->hiddenUserIds(), fn ($q, $hidden) => $q->whereNotIn('user_id', $hidden))
            ->reorder('created_at')
            ->paginate(50);

        return CommentResource::collection($comments)->response();
    }

    public function comment(Request $request, Post $post): JsonResponse
    {
        abort_unless($post->is_published, 404);

        $data = $request->validate([
            'body' => ['required', 'string', 'max:500'],
        ]);

        app(ContentModerator::class)->guard($data['body'], $request->user(), 'comment');

        $comment = $post->comments()->create([
            'user_id' => $request->user()->id,
            'body' => $data['body'],
        ]);

        $comment->load('author:id,name,username,accent_color,avatar_path');

        return (new CommentResource($comment))->response()->setStatusCode(201);
    }

    /** Idempotent per member: the unique index makes a double like impossible. */
    public function like(Request $request, Post $post): JsonResponse
    {
        $post->likers()->syncWithoutDetaching([$request->user()->id]);

        return response()->json(['likes' => $post->likers()->count(), 'liked' => true]);
    }

    public function unlike(Request $request, Post $post): JsonResponse
    {
        $post->likers()->detach($request->user()->id);

        return response()->json(['likes' => $post->likers()->count(), 'liked' => false]);
    }
}
