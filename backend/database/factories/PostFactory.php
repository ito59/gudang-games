<?php

namespace Database\Factories;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class PostFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'game_id' => null,
            'body' => fake()->sentence(12),
            // Not news: that kind is an announcement with a headline, and a
            // factory picking it at random would make posts that the admin
            // form would refuse to save.
            'kind' => fake()->randomElement(
                array_values(array_diff(Post::KINDS, [Post::news]))
            ),
            'comments_count' => fake()->numberBetween(0, 50),
            'is_published' => true,
            'published_at' => now()->subMinutes(fake()->numberBetween(1, 600)),
        ];
    }

    public function hidden(): static
    {
        return $this->state(fn () => ['is_published' => false]);
    }

    public function news(): static
    {
        return $this->state(fn () => [
            'kind' => Post::news,
            'title' => fake()->sentence(5),
        ]);
    }
}
