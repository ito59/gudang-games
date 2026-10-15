<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Game;
use App\Models\Post;
use App\Models\User;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function __invoke(): Response
    {
        return Inertia::render('Admin/Dashboard', [
            'stats' => [
                'games' => Game::count(),
                'published_games' => Game::published()->count(),
                'categories' => Category::count(),
                'featured' => Game::featured()->count(),
                'users' => User::count(),
                'online' => User::online()->count(),
                'posts' => Post::count(),
                'pending_posts' => Post::where('is_published', false)->count(),
            ],
            'latestPosts' => Post::with(['author:id,name,username', 'game:id,title'])
                ->latest('published_at')
                ->take(5)
                ->get()
                ->map(fn (Post $post) => [
                    'id' => $post->id,
                    'body' => str($post->body)->limit(80)->value(),
                    'kind' => $post->kind,
                    'author' => $post->author?->name,
                    'game' => $post->game?->title,
                    'is_published' => $post->is_published,
                ]),
        ]);
    }
}
