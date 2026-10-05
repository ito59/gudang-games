<?php

namespace Tests\Feature\Admin;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostAuthorTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_new_post_is_written_by_the_signed_in_admin(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)
            ->post('/admin/posts', ['kind' => 'update', 'body' => 'From the desk.'])
            ->assertRedirect('/admin/posts');

        $this->assertSame($admin->id, Post::firstOrFail()->user_id);
    }

    public function test_the_author_cannot_be_named_in_the_request(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $member = User::factory()->create();

        // The form has no author field; a request that invents one must not
        // put words in a member's mouth.
        $this->actingAs($admin)
            ->post('/admin/posts', [
                'user_id' => $member->id,
                'kind' => 'update',
                'body' => 'Not mine.',
            ])
            ->assertRedirect('/admin/posts');

        $this->assertSame($admin->id, Post::firstOrFail()->user_id);
    }

    public function test_editing_a_members_post_does_not_reassign_it(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $member = User::factory()->create();
        $post = Post::factory()->for($member, 'author')->create(['body' => 'Mine.']);

        $this->actingAs($admin)
            ->put("/admin/posts/{$post->id}", [
                'kind' => $post->kind,
                'body' => 'Tidied by a moderator.',
            ])
            ->assertRedirect('/admin/posts');

        $post->refresh();

        $this->assertSame('Tidied by a moderator.', $post->body);
        // Moderating somebody's words does not make them yours.
        $this->assertSame($member->id, $post->user_id);
    }

    public function test_an_attempt_to_reassign_on_edit_is_ignored(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $member = User::factory()->create();
        $post = Post::factory()->for($member, 'author')->create();

        $this->actingAs($admin)
            ->put("/admin/posts/{$post->id}", [
                'user_id' => $admin->id,
                'kind' => $post->kind,
                'body' => $post->body,
            ])
            ->assertRedirect('/admin/posts');

        $this->assertSame($member->id, $post->fresh()->user_id);
    }

    public function test_the_form_no_longer_offers_a_list_of_authors(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)
            ->get('/admin/posts/create')
            ->assertOk()
            ->assertInertia(fn ($page) => $page
                ->component('Admin/Posts/Form')
                ->missing('authors'));
    }
}
