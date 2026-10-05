<?php

namespace Tests\Feature\Admin;

use App\Models\FeaturedEvent;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Posts and featured events both carry an `image_path` an admin fills in from
 * the dashboard, and both use the same upload behaviour.
 */
class PostImageUploadTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->admin = User::factory()->create(['is_admin' => true]);
    }

    /** @return array<string, mixed> */
    private function postFields(array $extra = []): array
    {
        return array_merge([
            'kind' => 'update',
            'body' => 'A post with a picture.',
        ], $extra);
    }

    public function test_a_post_image_is_uploaded_not_typed(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('shot.jpg'),
            ]))
            ->assertRedirect('/admin/posts');

        $post = Post::firstOrFail();

        $this->assertStringStartsWith('posts/', $post->image_path);
        Storage::disk('public')->assertExists($post->image_path);
    }

    public function test_the_app_is_handed_a_url_for_it(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('shot.jpg'),
            ]));

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonPath('data.0.image', Post::firstOrFail()->image_url);
    }

    public function test_replacing_an_image_deletes_the_one_it_replaced(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('first.jpg'),
            ]));

        $post = Post::firstOrFail();
        $first = $post->image_path;

        $this->actingAs($this->admin)
            ->post("/admin/posts/{$post->id}", $this->postFields([
                '_method' => 'put',
                'image' => UploadedFile::fake()->image('second.jpg'),
            ]))
            ->assertRedirect('/admin/posts');

        $second = $post->fresh()->image_path;

        $this->assertNotSame($first, $second);
        Storage::disk('public')->assertMissing($first);
        Storage::disk('public')->assertExists($second);
    }

    public function test_removing_an_image_clears_the_column_and_the_file(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('shot.jpg'),
            ]));

        $post = Post::firstOrFail();
        $path = $post->image_path;

        $this->actingAs($this->admin)
            ->post("/admin/posts/{$post->id}", $this->postFields([
                '_method' => 'put',
                'remove_image' => true,
            ]))
            ->assertRedirect('/admin/posts');

        $this->assertNull($post->fresh()->image_path);
        Storage::disk('public')->assertMissing($path);
    }

    public function test_an_edit_that_mentions_no_image_keeps_the_stored_one(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('shot.jpg'),
            ]));

        $post = Post::firstOrFail();
        $path = $post->image_path;

        $this->actingAs($this->admin)
            ->post("/admin/posts/{$post->id}", $this->postFields([
                '_method' => 'put',
                'body' => 'Only the words changed.',
            ]))
            ->assertRedirect('/admin/posts');

        $this->assertSame($path, $post->fresh()->image_path);
        Storage::disk('public')->assertExists($path);
    }

    public function test_deleting_a_post_takes_its_image_with_it(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('shot.jpg'),
            ]));

        $post = Post::firstOrFail();
        $path = $post->image_path;

        $this->actingAs($this->admin)
            ->delete("/admin/posts/{$post->id}")
            ->assertRedirect();

        Storage::disk('public')->assertMissing($path);
    }

    public function test_a_non_image_is_rejected(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->create('notes.pdf', 20, 'application/pdf'),
            ]))
            ->assertSessionHasErrors('image');

        $this->assertSame(0, Post::count());
    }

    public function test_an_oversized_image_says_so(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/posts', $this->postFields([
                'image' => UploadedFile::fake()->image('huge.jpg')->size(5000),
            ]))
            ->assertSessionHasErrors([
                'image' => 'The image must be 4 MB or smaller.',
            ]);
    }

    public function test_a_seeded_bundle_path_is_left_alone(): void
    {
        // Seeded records point at an asset inside the Flutter app. It has no
        // URL of ours, and deleting the record must not try to unlink it.
        $post = Post::factory()->create(['image_path' => 'assets/images/clip.jpg']);

        $this->assertNull($post->image_url);

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonPath('data.0.image', 'assets/images/clip.jpg');

        $post->delete();
        $this->assertSame(0, Post::count());
    }

    public function test_a_featured_event_uploads_the_same_way(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/events', [
                'title' => 'Ascension',
                'description' => 'The season finale.',
                'season' => 'SEASON 2',
                'image' => UploadedFile::fake()->image('banner.jpg'),
            ])
            ->assertRedirect('/admin/events');

        $event = FeaturedEvent::firstOrFail();

        $this->assertStringStartsWith('events/', $event->image_path);
        Storage::disk('public')->assertExists($event->image_path);

        $this->getJson('/api/v1/featured')
            ->assertOk()
            ->assertJsonPath('data.0.image', $event->image_url);
    }
}
