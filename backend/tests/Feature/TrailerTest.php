<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class TrailerTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    /**
     * A file with real bytes. `UploadedFile::fake()->create()` only *reports*
     * a size — it stores nothing, so any Range request comes back 416.
     */
    private function video(string $name = 'trailer.mp4', int $bytes = 65536): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'vid').'.mp4';

        // The `mimetypes` rule sniffs the file's contents, so the fixture
        // needs a real MP4 `ftyp` box, not just an .mp4 extension.
        $header = "\x00\x00\x00\x20ftypisom\x00\x00\x02\x00isomiso2avc1mp41";
        file_put_contents($path, $header.random_bytes(max(0, $bytes - strlen($header))));

        return new UploadedFile($path, $name, 'video/mp4', null, true);
    }

    /** Puts a trailer on a game without going through HTTP. */
    private function giveTrailer(Game $game, int $bytes = 65536): Game
    {
        $path = Game::TRAILER_DIRECTORY.'/'.$game->slug.'.mp4';
        Storage::disk('local')->put($path, random_bytes($bytes));

        $game->forceFill([
            'trailer_path' => $path,
            'trailer_mime' => 'video/mp4',
            'trailer_size' => $bytes,
        ])->save();

        return $game;
    }

    public function test_the_trailer_page_is_admin_only(): void
    {
        $game = Game::factory()->create();

        $this->get("/admin/games/{$game->id}/trailer")->assertRedirect('/login');

        $this->actingAs(User::factory()->create())
            ->get("/admin/games/{$game->id}/trailer")
            ->assertForbidden();

        $this->actingAs($this->admin())
            ->get("/admin/games/{$game->id}/trailer")
            ->assertOk();
    }

    public function test_a_trailer_can_be_uploaded(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create();

        $this->actingAs($this->admin())
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video()])
            ->assertRedirect("/admin/games/{$game->id}/trailer");

        $game->refresh();

        $this->assertNotNull($game->trailer_path);
        $this->assertSame('video/mp4', $game->trailer_mime);
        $this->assertNotNull($game->trailer_size);
        Storage::disk('local')->assertExists($game->trailer_path);

        // Stored on the protected disk, never under a web-served directory.
        $this->assertStringStartsWith('trailers/', $game->trailer_path);
    }

    public function test_replacing_a_trailer_deletes_the_previous_file(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create();
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video('one.mp4')]);
        $first = $game->fresh()->trailer_path;

        $this->actingAs($admin)
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video('two.mp4')]);
        $second = $game->fresh()->trailer_path;

        $this->assertNotSame($first, $second);
        Storage::disk('local')->assertMissing($first);
        Storage::disk('local')->assertExists($second);
    }

    public function test_a_trailer_can_be_removed(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create();
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video()]);
        $path = $game->fresh()->trailer_path;

        $this->actingAs($admin)
            ->delete("/admin/games/{$game->id}/trailer")
            ->assertRedirect();

        $game->refresh();

        $this->assertNull($game->trailer_path);
        $this->assertNull($game->trailer_mime);
        Storage::disk('local')->assertMissing($path);
    }

    public function test_a_non_video_is_rejected(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create();

        $this->actingAs($this->admin())
            ->post("/admin/games/{$game->id}/trailer", [
                'trailer' => UploadedFile::fake()->create('notes.pdf', 32, 'application/pdf'),
            ])
            ->assertSessionHasErrors('trailer');

        $this->assertNull($game->fresh()->trailer_path);
    }

    public function test_deleting_a_game_removes_its_trailer(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create();
        $admin = $this->admin();

        $this->actingAs($admin)
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video()]);
        $path = $game->fresh()->trailer_path;

        $this->actingAs($admin)->delete("/admin/games/{$game->id}");

        Storage::disk('local')->assertMissing($path);
    }

    public function test_the_trailer_streams_and_accepts_ranges(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create(['is_published' => true]);

        $this->actingAs($this->admin())
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video()]);

        $game->refresh();

        $response = $this->get("/games/{$game->slug}/trailer")
            ->assertOk()
            ->assertHeader('accept-ranges', 'bytes')
            ->assertHeader('content-type', 'video/mp4');

        // Without ranges a player cannot seek, and some refuse to start.
        $this->assertNotNull($response->baseResponse->getFile());
    }

    public function test_a_range_request_returns_partial_content(): void
    {
        Storage::fake('local');
        $game = $this->giveTrailer(Game::factory()->create(['is_published' => true]));

        // Seeking is what Range buys; without it a player cannot scrub.
        $this->get("/games/{$game->slug}/trailer", ['Range' => 'bytes=0-1023'])
            ->assertStatus(206)
            ->assertHeader('content-length', '1024')
            ->assertHeader('content-range', 'bytes 0-1023/65536');
    }

    public function test_an_unpublished_trailer_is_hidden_from_the_public(): void
    {
        Storage::fake('local');
        // Seeded directly: actingAs would persist for the guest request too.
        $game = $this->giveTrailer(
            Game::factory()->create(['is_published' => false])
        );

        $this->get("/games/{$game->slug}/trailer")->assertNotFound();

        $this->actingAs($this->admin())
            ->get("/games/{$game->slug}/trailer")
            ->assertOk();
    }

    public function test_a_game_without_a_trailer_is_a_404(): void
    {
        $game = Game::factory()->create(['is_published' => true]);

        $this->get("/games/{$game->slug}/trailer")->assertNotFound();
    }

    public function test_the_api_exposes_the_trailer_url(): void
    {
        Storage::fake('local');
        $game = Game::factory()->create(['is_published' => true]);

        $this->getJson('/api/v1/games')->assertJsonPath('data.0.trailer_url', null);

        $this->actingAs($this->admin())
            ->post("/admin/games/{$game->id}/trailer", ['trailer' => $this->video()]);

        $this->getJson('/api/v1/games')
            ->assertJsonPath('data.0.trailer_url', route('games.trailer', ['game' => $game->slug]));
    }
}
