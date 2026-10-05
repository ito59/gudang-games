<?php

namespace Tests\Feature\Api;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NewsTest extends TestCase
{
    use RefreshDatabase;

    public function test_news_reaches_the_feed_with_its_headline(): void
    {
        $team = User::factory()->create(['is_admin' => true]);

        Post::factory()->for($team, 'author')->create([
            'kind' => Post::news,
            'title' => 'Season 2 lands next week',
            'body' => "Ranked resets on Monday.\n\nNew maps come with it.",
        ]);

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonPath('data.0.kind', 'news')
            ->assertJsonPath('data.0.title', 'Season 2 lands next week');
    }

    public function test_an_ordinary_post_carries_no_headline(): void
    {
        Post::factory()->create(['kind' => 'update']);

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonPath('data.0.title', null);
    }

    public function test_the_feed_can_be_filtered_to_news(): void
    {
        Post::factory()->create(['kind' => 'news', 'title' => 'Announced', 'body' => 'x']);
        Post::factory()->create(['kind' => 'update', 'body' => 'Ordinary']);

        $this->getJson('/api/v1/feed?kind=news')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Announced');
    }

    public function test_the_app_cannot_post_news(): void
    {
        // Even an admin: news is written in the dashboard, where it gets a
        // headline. The app's composer has no field for one.
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->postJson('/api/v1/feed', ['body' => 'We are pleased to…', 'kind' => 'news'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('kind');

        $this->assertSame(0, Post::where('kind', 'news')->count());
    }

    public function test_an_unpublished_announcement_stays_out_of_the_feed(): void
    {
        Post::factory()->hidden()->create([
            'kind' => 'news',
            'title' => 'Draft',
            'body' => 'Not yet',
        ]);

        $this->getJson('/api/v1/feed')->assertOk()->assertJsonCount(0, 'data');
    }
}
