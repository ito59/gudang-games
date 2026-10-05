<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Comment;
use App\Models\FeaturedEvent;
use App\Models\Game;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_catalogue_is_public(): void
    {
        $action = Category::factory()->create(['name' => 'Action']);
        // In the category, so it is one the app has reason to show.
        Game::factory()->for($action)->create(['title' => 'Neon Guardian']);
        FeaturedEvent::factory()->create(['title' => 'Ascension']);

        // Present, not first: the featured event's factory quietly makes a
        // game of its own, and its category sorts wherever it likes.
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonFragment(['label' => 'Action']);

        $this->getJson('/api/v1/games')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Neon Guardian');

        $this->getJson('/api/v1/featured')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Ascension');
    }

    public function test_an_empty_category_is_not_offered(): void
    {
        $full = Category::factory()->create(['name' => 'Action', 'sort_order' => 1]);
        Category::factory()->create(['name' => 'Nobody plays this', 'sort_order' => 2]);
        Game::factory()->for($full)->create();

        // A chip that leads to an empty list is a dead end.
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.label', 'Action');
    }

    public function test_a_category_holding_only_unpublished_games_is_hidden(): void
    {
        $category = Category::factory()->create(['name' => 'Coming soon']);
        Game::factory()->for($category)->create(['is_published' => false]);

        // The app could not show that game either, so the category leads
        // nowhere just the same.
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_publishing_a_game_brings_its_category_back(): void
    {
        $category = Category::factory()->create(['name' => 'Racing']);
        $game = Game::factory()->for($category)->create(['is_published' => false]);

        $this->getJson('/api/v1/categories')->assertJsonCount(0, 'data');

        $game->update(['is_published' => true]);

        $this->getJson('/api/v1/categories')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.label', 'Racing');
    }

    public function test_the_remaining_categories_keep_their_order(): void
    {
        foreach ([['Strategy', 3], ['Action', 1], ['RPG', 2]] as [$name, $order]) {
            $category = Category::factory()->create(['name' => $name, 'sort_order' => $order]);
            Game::factory()->for($category)->create();
        }
        // Empty, and between two that are not.
        Category::factory()->create(['name' => 'Empty', 'sort_order' => 2]);

        $labels = collect($this->getJson('/api/v1/categories')->json('data'))
            ->pluck('label')
            ->all();

        $this->assertSame(['Action', 'RPG', 'Strategy'], $labels);
    }

    public function test_unpublished_records_stay_out_of_the_api(): void
    {
        Game::factory()->create(['title' => 'Live game']);
        Game::factory()->create(['title' => 'Draft game', 'is_published' => false]);

        $this->getJson('/api/v1/games')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Live game');
    }

    public function test_the_feed_hides_unpublished_posts(): void
    {
        Post::factory()->create(['body' => 'Shown']);
        Post::factory()->hidden()->create(['body' => 'Hidden']);

        $this->getJson('/api/v1/feed')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.body', 'Shown');
    }

    public function test_featured_games_join_the_carousel(): void
    {
        FeaturedEvent::factory()->create(['title' => 'Campaign slide']);
        Game::factory()->create(['title' => 'Plain game', 'is_published' => true]);
        Game::factory()->create([
            'title' => 'Promoted game',
            'is_published' => true,
            'is_featured' => true,
            'description' => 'Worth your evening.',
        ]);

        $response = $this->getJson('/api/v1/featured')->assertOk();

        $titles = collect($response->json('data'))->pluck('title');

        // Hand-written slides first, then featured games.
        $this->assertSame(['Campaign slide', 'Promoted game'], $titles->all());
        $this->assertNull($response->json('data.0.game'));

        // A game slide carries the game, so the carousel can open it.
        $this->assertSame('Promoted game', $response->json('data.1.game.title'));
        $this->assertSame('Worth your evening.', $response->json('data.1.description'));
        $this->assertSame('FEATURED', $response->json('data.1.season'));
    }

    public function test_an_unpublished_game_cannot_be_featured_in_the_carousel(): void
    {
        Game::factory()->create([
            'title' => 'Hidden favourite',
            'is_published' => false,
            'is_featured' => true,
        ]);

        $this->getJson('/api/v1/featured')->assertJsonCount(0, 'data');
    }

    public function test_a_play_can_be_recorded(): void
    {
        $game = Game::factory()->create(['is_published' => true, 'plays_count' => 0]);

        $this->postJson("/api/v1/games/{$game->slug}/play")
            ->assertOk()
            ->assertJsonPath('plays_count', 1);

        $this->postJson("/api/v1/games/{$game->slug}/play")
            ->assertOk()
            ->assertJsonPath('plays_count', 2);

        $this->assertSame(2, $game->fresh()->plays_count);
    }

    public function test_an_unpublished_game_cannot_be_played(): void
    {
        $game = Game::factory()->create(['is_published' => false]);

        $this->postJson("/api/v1/games/{$game->slug}/play")->assertNotFound();

        $this->assertSame(0, $game->fresh()->plays_count);
    }

    public function test_the_catalogue_reports_popularity(): void
    {
        Game::factory()->create(['is_published' => true, 'plays_count' => 42]);

        $this->getJson('/api/v1/games')->assertJsonPath('data.0.plays_count', 42);
    }

    public function test_login_returns_a_token(): void
    {
        $user = User::factory()->create([
            'email' => 'member@example.test',
            'password' => 'secret-password',
        ]);

        $this->postJson('/api/v1/login', [
            'email' => 'member@example.test',
            'password' => 'secret-password',
            'device_name' => 'Pixel',
        ])
            ->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'handle']]);

        $this->assertCount(1, $user->fresh()->tokens);
    }

    public function test_a_suspended_account_cannot_sign_in(): void
    {
        User::factory()->create([
            'email' => 'banned@example.test',
            'password' => 'secret-password',
            'is_active' => false,
        ]);

        $this->postJson('/api/v1/login', [
            'email' => 'banned@example.test',
            'password' => 'secret-password',
            'device_name' => 'Pixel',
        ])->assertStatus(422);
    }

    public function test_posting_to_the_feed_requires_a_token(): void
    {
        $this->postJson('/api/v1/feed', ['body' => 'Hi', 'kind' => 'update'])
            ->assertUnauthorized();
    }

    public function test_a_member_can_post_and_like(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/feed', ['body' => 'First post', 'kind' => 'clip'])
            ->assertCreated()
            ->assertJsonPath('data.body', 'First post');

        $post = Post::first();

        $this->postJson("/api/v1/feed/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('likes', 1);

        // Liking twice must not double count — the unique index enforces it.
        $this->postJson("/api/v1/feed/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('likes', 1);

        $this->deleteJson("/api/v1/feed/{$post->id}/like")
            ->assertOk()
            ->assertJsonPath('likes', 0);
    }

    public function test_comments_require_a_token(): void
    {
        $post = Post::factory()->create();

        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => 'Hi'])
            ->assertUnauthorized();
    }

    public function test_a_member_can_comment_and_the_count_follows(): void
    {
        $post = Post::factory()->create(['comments_count' => 0]);
        Sanctum::actingAs(User::factory()->create(['name' => 'Dita']));

        $this->postJson("/api/v1/feed/{$post->id}/comments", [
            'body' => 'Nice run!',
        ])
            ->assertCreated()
            ->assertJsonPath('data.body', 'Nice run!')
            ->assertJsonPath('data.author.name', 'Dita');

        // The denormalised counter must not drift from the rows.
        $this->assertSame(1, $post->fresh()->comments_count);

        $this->getJson("/api/v1/feed/{$post->id}/comments")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.body', 'Nice run!');
    }

    public function test_an_empty_comment_is_rejected(): void
    {
        $post = Post::factory()->create(['comments_count' => 0]);
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => '  '])
            ->assertStatus(422);

        $this->assertSame(0, $post->fresh()->comments_count);
    }

    public function test_comments_on_a_hidden_post_are_not_reachable(): void
    {
        $post = Post::factory()->hidden()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/feed/{$post->id}/comments")->assertNotFound();
        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => 'Hi'])
            ->assertNotFound();
    }

    public function test_deleting_a_comment_decrements_the_count(): void
    {
        $post = Post::factory()->create(['comments_count' => 0]);
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => 'Bye']);
        $this->assertSame(1, $post->fresh()->comments_count);

        Comment::first()->delete();
        $this->assertSame(0, $post->fresh()->comments_count);
    }

    public function test_the_feed_reports_whether_the_viewer_liked_a_post(): void
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();
        $post->likers()->attach($user->id);

        $this->getJson('/api/v1/feed')->assertJsonPath('data.0.liked_by_me', false);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/feed')->assertJsonPath('data.0.liked_by_me', true);
    }

    /**
     * The feed is a public route, so a Bearer token is the only thing telling
     * it who is reading. actingAs() would swap the default guard and hide a
     * controller that asked the session guard instead.
     */
    public function test_a_bearer_token_identifies_the_viewer_on_the_public_feed(): void
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();
        $post->likers()->attach($user->id);

        $this->withHeader('Authorization', 'Bearer '.$user->createToken('phone')->plainTextToken)
            ->getJson('/api/v1/feed')
            ->assertJsonPath('data.0.liked_by_me', true);
    }

    /**
     * A separate test on purpose: within one test the guard caches the user it
     * already resolved, so a second request would inherit the first reader.
     */
    public function test_a_bearer_token_for_someone_else_does_not_report_a_like(): void
    {
        $post = Post::factory()->create();
        $post->likers()->attach(User::factory()->create()->id);

        $other = User::factory()->create();

        $this->withHeader('Authorization', 'Bearer '.$other->createToken('phone')->plainTextToken)
            ->getJson('/api/v1/feed')
            ->assertJsonPath('data.0.liked_by_me', false)
            ->assertJsonPath('data.0.likes', 1);
    }

    public function test_a_new_post_reports_a_zero_comment_count(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/feed', ['body' => 'Hello.', 'kind' => 'update'])
            ->assertCreated()
            ->assertJsonPath('data.comments', 0)
            ->assertJsonPath('data.likes', 0);
    }
}
