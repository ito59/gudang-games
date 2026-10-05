<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Concerns\SyncsUploadedImage;
use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\Post;
use App\Services\Push\Notifier;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * The user feed: what members post in the app's Community tab.
 */
class PostController extends Controller
{
    use SyncsUploadedImage;

    public function index(Request $request): Response
    {
        $posts = Post::query()
            ->with(['author:id,name,username,accent_color', 'game:id,title'])
            ->withCount('likes')
            ->when($request->string('search')->trim()->value(), function ($query, string $search) {
                $query->where(fn ($q) => $q
                    ->where('body', 'like', "%{$search}%")
                    ->orWhere('title', 'like', "%{$search}%"));
            })
            ->when($request->string('kind')->value(), fn ($q, $kind) => $q->where('kind', $kind))
            ->when($request->string('status')->value() === 'pending', fn ($q) => $q->where('is_published', false))
            ->latest('published_at')
            ->paginate(10)
            ->withQueryString();

        return Inertia::render('Admin/Posts/Index', [
            'posts' => $posts,
            'kinds' => Post::KINDS,
            'filters' => $request->only('search', 'kind', 'status'),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Admin/Posts/Form', [
            'post' => null,
            'kinds' => Post::KINDS,
            'games' => Game::orderBy('title')->get(['id', 'title']),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validated($request);
        unset($data['image'], $data['remove_image']);
        $data['published_at'] ??= now();
        // A post is written by whoever is signed in. An admin speaking as
        // somebody else would put words in a member's mouth.
        $data['user_id'] = $request->user()->id;

        $post = new Post($data);
        $this->syncImage($request, $post, 'posts');
        $post->save();

        $this->announceIfNews($post, wasAnnounced: false);

        return to_route('admin.posts.index')->with('success', 'Post created.');
    }

    public function edit(Post $post): Response
    {
        return Inertia::render('Admin/Posts/Form', [
            'post' => $post->load('author:id,name,username'),
            'kinds' => Post::KINDS,
            'games' => Game::orderBy('title')->get(['id', 'title']),
        ]);
    }

    public function update(Request $request, Post $post): RedirectResponse
    {
        $data = $this->validated($request);
        unset($data['image'], $data['remove_image']);

        // Editing a member's post does not make it the admin's: the author
        // stays whoever wrote it.
        // Whether it had already gone out decides whether it goes out again.
        $wasAnnounced = $post->getOriginal('is_published')
            && $post->getOriginal('kind') === Post::news;

        $post->fill($data);
        $this->syncImage($request, $post, 'posts');
        $post->save();

        $this->announceIfNews($post, wasAnnounced: $wasAnnounced);

        return to_route('admin.posts.index')->with('success', 'Post updated.');
    }

    /** Quick moderation toggle from the list. */
    public function togglePublished(Post $post): RedirectResponse
    {
        $wasAnnounced = $post->is_published && $post->isNews();

        $post->update([
            'is_published' => ! $post->is_published,
            'published_at' => $post->published_at ?? now(),
        ]);

        $this->announceIfNews($post, wasAnnounced: $wasAnnounced);

        return back()->with(
            'success',
            $post->is_published ? 'Post published.' : 'Post hidden.'
        );
    }

    public function destroy(Post $post): RedirectResponse
    {
        $post->delete();

        return back()->with('success', 'Post deleted.');
    }

    /**
     * Tells every phone about an announcement, once.
     *
     * Only when it crosses into being published news — fixing a typo in an
     * article that went out this morning must not buzz everybody again.
     */
    private function announceIfNews(Post $post, bool $wasAnnounced): void
    {
        if ($wasAnnounced || ! $post->isNews() || ! $post->is_published) {
            return;
        }

        app(Notifier::class)->newsPublished($post);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'game_id' => ['nullable', 'exists:games,id'],
            // A headline is what makes news readable as news in the feed, so
            // it is required for that kind and ignored for the others.
            'title' => [
                Rule::requiredIf(fn () => $request->input('kind') === Post::news),
                'nullable',
                'string',
                'max:120',
            ],
            'body' => ['required', 'string', 'max:5000'],
            'kind' => ['required', Rule::in(Post::KINDS)],
            ...$this->imageRules(),
            'comments_count' => ['integer', 'min:0'],
            'is_published' => ['boolean'],
            'published_at' => ['nullable', 'date'],
        ], $this->imageMessages());
    }
}
