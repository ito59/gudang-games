<?php

namespace Tests\Feature\Api;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AvatarTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_a_member_can_upload_a_photo(): void
    {
        $user = User::factory()->create(['avatar_path' => null]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('me.jpg', 400, 400),
        ])->assertOk();

        $path = $user->fresh()->avatar_path;

        $this->assertNotNull($path);
        Storage::disk('public')->assertExists($path);
        // The app is handed a URL, not a disk path it could not resolve.
        $this->assertStringContainsString('/storage/', $response->json('data.avatar'));
    }

    public function test_replacing_a_photo_deletes_the_one_it_replaced(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('first.jpg'),
        ])->assertOk();
        $first = $user->fresh()->avatar_path;

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('second.jpg'),
        ])->assertOk();
        $second = $user->fresh()->avatar_path;

        $this->assertNotSame($first, $second);
        Storage::disk('public')->assertMissing($first);
        Storage::disk('public')->assertExists($second);
    }

    public function test_removing_a_photo_clears_the_column_and_the_file(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('me.jpg'),
        ])->assertOk();
        $path = $user->fresh()->avatar_path;

        $this->deleteJson('/api/v1/me/avatar')
            ->assertOk()
            ->assertJsonPath('data.avatar', null);

        $this->assertNull($user->fresh()->avatar_path);
        Storage::disk('public')->assertMissing($path);
    }

    public function test_a_seeded_bundle_path_is_left_on_the_bundle(): void
    {
        // Seeded members point at an asset inside the Flutter app. It is not
        // on our disk, so it passes through and must not be deleted.
        $user = User::factory()->create(['avatar_path' => 'assets/images/avatar.jpg']);
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.avatar', 'assets/images/avatar.jpg');

        $this->deleteJson('/api/v1/me/avatar')->assertOk();
        $this->assertNull($user->fresh()->avatar_path);
    }

    public function test_a_non_image_is_rejected(): void
    {
        $user = User::factory()->create(['avatar_path' => null]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->create('save.zip', 40, 'application/zip'),
        ])->assertStatus(422)->assertJsonValidationErrors('photo');

        $this->assertNull($user->fresh()->avatar_path);
    }

    public function test_an_oversized_photo_says_so(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('huge.jpg')->size(9000),
        ])
            ->assertStatus(422)
            ->assertJsonPath('errors.photo.0', 'That photo is larger than 8 MB.');
    }

    public function test_uploading_needs_a_token(): void
    {
        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('me.jpg'),
        ])->assertUnauthorized();

        $this->deleteJson('/api/v1/me/avatar')->assertUnauthorized();
    }

    public function test_the_photo_follows_the_member_into_posts_and_comments(): void
    {
        $author = User::factory()->create();
        Sanctum::actingAs($author);

        $this->postJson('/api/v1/me/avatar', [
            'photo' => UploadedFile::fake()->image('me.jpg'),
        ])->assertOk();

        $post = Post::factory()->for($author, 'author')->create();
        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => 'Nice run.'])
            ->assertCreated();

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonPath(
                'data.0.author.avatar',
                $author->fresh()->avatar_url,
            );

        $this->getJson("/api/v1/feed/{$post->id}/comments")
            ->assertOk()
            ->assertJsonPath(
                'data.0.author.avatar',
                $author->fresh()->avatar_url,
            );
    }
}
