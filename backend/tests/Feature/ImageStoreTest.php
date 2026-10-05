<?php

namespace Tests\Feature;

use App\Services\ImageStore;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ImageStoreTest extends TestCase
{
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

    public function test_an_oversized_image_is_shrunk_to_the_limit(): void
    {
        $path = (new ImageStore(maxEdge: 600))
            ->store(UploadedFile::fake()->image('huge.jpg', 3000, 2000), 'covers');

        [$width, $height] = $this->sizeOf($path);

        $this->assertSame(600, $width);
        // Aspect ratio kept: 3000x2000 is 3:2, so 600 wide is 400 tall.
        $this->assertSame(400, $height);
    }

    public function test_the_long_edge_is_what_is_limited(): void
    {
        // Portrait: the height is the one that has to come down.
        $path = (new ImageStore(maxEdge: 600))
            ->store(UploadedFile::fake()->image('tall.jpg', 1000, 2000), 'covers');

        [$width, $height] = $this->sizeOf($path);

        $this->assertSame(600, $height);
        $this->assertSame(300, $width);
    }

    public function test_a_small_image_is_left_exactly_as_it_arrived(): void
    {
        $file = UploadedFile::fake()->image('small.jpg', 400, 300);
        $original = file_get_contents($file->getRealPath());

        $path = (new ImageStore(maxEdge: 1200))->store($file, 'covers');

        // Byte for byte: re-encoding something already small only loses
        // detail and gains nothing.
        $this->assertSame($original, Storage::disk('public')->get($path));
    }

    public function test_shrinking_actually_saves_space(): void
    {
        $file = UploadedFile::fake()->image('huge.jpg', 3000, 2000);
        $before = filesize($file->getRealPath());

        $path = (new ImageStore(maxEdge: 600))->store($file, 'covers');

        $this->assertLessThan($before, Storage::disk('public')->size($path));
    }

    public function test_the_file_type_does_not_change_underneath_the_upload(): void
    {
        $store = new ImageStore(maxEdge: 300);

        foreach (['jpg', 'png', 'webp'] as $extension) {
            $path = $store->store(
                UploadedFile::fake()->image("big.{$extension}", 1200, 900),
                'covers'
            );

            $this->assertStringEndsWith(".{$extension}", $path);
            $this->assertNotNull(
                getimagesizefromstring(Storage::disk('public')->get($path)),
                "$extension should still be a readable image"
            );
        }
    }

    public function test_a_file_that_is_not_an_image_is_stored_untouched(): void
    {
        // Validation is what rejects these; the store must not lose one by
        // failing to parse it.
        $file = UploadedFile::fake()->create('notes.jpg', 8, 'image/jpeg');

        $path = (new ImageStore(maxEdge: 100))->store($file, 'covers');

        Storage::disk('public')->assertExists($path);
    }

    public function test_it_stores_under_the_folder_it_was_given(): void
    {
        $path = (new ImageStore(maxEdge: 300))
            ->store(UploadedFile::fake()->image('a.jpg', 900, 900), 'avatars');

        $this->assertStringStartsWith('avatars/', $path);
    }
}
