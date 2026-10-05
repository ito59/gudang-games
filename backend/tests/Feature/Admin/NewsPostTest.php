<?php

namespace Tests\Feature\Admin;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NewsPostTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    public function test_an_admin_can_publish_news(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post('/admin/posts', [
                'kind' => 'news',
                'title' => 'Season 2 lands next week',
                'body' => "Ranked resets on Monday.\n\nNew maps come with it.",
                'is_published' => true,
            ])
            ->assertRedirect('/admin/posts');

        $post = Post::where('kind', 'news')->firstOrFail();

        $this->assertSame('Season 2 lands next week', $post->title);
        $this->assertTrue($post->is_published);
        $this->assertNotNull($post->published_at);
    }

    public function test_news_without_a_headline_is_rejected(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post('/admin/posts', [
                'kind' => 'news',
                'body' => 'No headline here.',
            ])
            ->assertSessionHasErrors('title');

        $this->assertSame(0, Post::count());
    }

    public function test_an_ordinary_post_still_needs_no_headline(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post('/admin/posts', [
                'kind' => 'update',
                'body' => 'Just a post.',
            ])
            ->assertRedirect('/admin/posts');

        $this->assertNull(Post::firstOrFail()->title);
    }

    public function test_the_admin_list_can_be_searched_by_headline(): void
    {
        $admin = $this->admin();
        Post::factory()->create(['kind' => 'news', 'title' => 'Season 2 lands', 'body' => 'x']);
        Post::factory()->create(['kind' => 'update', 'body' => 'Unrelated']);

        $this->actingAs($admin)
            ->get('/admin/posts?search=Season')
            ->assertOk()
            ->assertInertia(fn ($page) => $page
                ->component('Admin/Posts/Index')
                ->has('posts.data', 1)
                ->where('posts.data.0.title', 'Season 2 lands'));
    }

    public function test_the_panel_is_admin_only(): void
    {
        $this->actingAs(User::factory()->create(['is_admin' => false]))
            ->post('/admin/posts', ['kind' => 'news', 'body' => 'x'])
            ->assertForbidden();
    }
}
