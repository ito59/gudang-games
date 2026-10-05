<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class GameFactory extends Factory
{
    public function definition(): array
    {
        $title = fake()->unique()->words(2, true);

        return [
            'title' => ucwords($title),
            'slug' => Str::slug($title),
            'category_id' => Category::factory(),
            'description' => fake()->sentence(),
            'rating' => fake()->randomFloat(1, 3, 5),
            'is_published' => true,
            'sort_order' => 0,
        ];
    }
}
