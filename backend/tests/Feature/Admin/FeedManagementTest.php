<?php

namespace Tests\Feature\Admin;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FeedManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_feed_can_be_filtered_by_kind(): void
    {
        $admin = User::factory()->admin()->create();
        Post::factory()->create(['kind' => 'clip', 'body' => 'A raid clip']);
        Post::factory()->create(['kind' => 'squad', 'body' => 'Need one more']);

        $this->actingAs($admin)
            ->get('/admin/posts?kind=clip')
            ->assertOk()
            ->assertSee('A raid clip')
            ->assertDontSee('Need one more');
    }

    public function test_hidden_posts_can_be_listed(): void
    {
        $admin = User::factory()->admin()->create();
        Post::factory()->create(['body' => 'Visible post']);
        Post::factory()->hidden()->create(['body' => 'Hidden post']);

        $this->actingAs($admin)
            ->get('/admin/posts?status=pending')
            ->assertOk()
            ->assertSee('Hidden post')
            ->assertDontSee('Visible post');
    }

    public function test_a_post_can_be_hidden_and_published_again(): void
    {
        $admin = User::factory()->admin()->create();
        $post = Post::factory()->create(['is_published' => true]);

        $this->actingAs($admin)->patch("/admin/posts/{$post->id}/toggle");
        $this->assertFalse($post->fresh()->is_published);

        $this->actingAs($admin)->patch("/admin/posts/{$post->id}/toggle");
        $this->assertTrue($post->fresh()->is_published);
    }

    public function test_a_post_can_be_deleted(): void
    {
        $admin = User::factory()->admin()->create();
        $post = Post::factory()->create();

        $this->actingAs($admin)
            ->delete("/admin/posts/{$post->id}")
            ->assertRedirect();

        $this->assertDatabaseMissing('posts', ['id' => $post->id]);
    }

    public function test_an_unknown_kind_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->post('/admin/posts', [
                'user_id' => $admin->id,
                'body' => 'Something',
                'kind' => 'gossip',
            ])
            ->assertSessionHasErrors('kind');
    }
}
