<?php

namespace Tests\Feature\Admin;

use App\Models\Category;
use App\Models\Game;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The shrinking reaches the real upload routes, not just the class that does
 * it. Each of these was its own `->store()` call before, and the mistake
 * worth catching is a fifth one appearing that quietly keeps the original.
 */
class UploadShrinkTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    /** @return array{0: int, 1: int} */
    private function sizeOf(string $path): array
    {
        $info = getimagesizefromstring(Storage::disk('public')->get($path));

        return [$info[0], $info[1]];
    }

    public function test_a_game_cover_is_shrunk(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        Category::factory()->create();

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'Neon Guardian',
            'rating' => 4.5,
            'source_type' => Game::SOURCE_URL,
            'game_url' => 'https://example.test/play',
            'cover' => UploadedFile::fake()->image('cover.jpg', 3200, 1800),
        ])->assertRedirect();

        [$width] = $this->sizeOf(Game::firstOrFail()->cover_path);

        $this->assertSame(1200, $width);
    }

    public function test_a_post_image_is_shrunk(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)->post('/admin/posts', [
            'kind' => 'update',
            'body' => 'A post with a very large picture.',
            'image' => UploadedFile::fake()->image('shot.jpg', 4000, 3000),
        ])->assertRedirect();

        [$width] = $this->sizeOf(Post::firstOrFail()->image_path);

        $this->assertSame(1600, $width);
    }

    public function test_an_avatar_is_shrunk(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/me/avatar', [
            // What a phone camera actually sends.
            'photo' => UploadedFile::fake()->image('selfie.jpg', 4032, 3024),
        ])->assertOk();

        [$width] = $this->sizeOf($user->fresh()->avatar_path);

        $this->assertSame(512, $width);
    }

    public function test_a_cover_already_small_enough_is_not_re_encoded(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        Category::factory()->create();

        $file = UploadedFile::fake()->image('cover.jpg', 800, 450);
        $original = file_get_contents($file->getRealPath());

        $this->actingAs($admin)->post('/admin/games', [
            'title' => 'Small cover',
            'rating' => 4.0,
            'source_type' => Game::SOURCE_URL,
            'game_url' => 'https://example.test/play',
            'cover' => $file,
        ])->assertRedirect();

        $this->assertSame(
            $original,
            Storage::disk('public')->get(Game::firstOrFail()->cover_path)
        );
    }
}
