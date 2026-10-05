<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class FeaturedEventFactory extends Factory
{
    public function definition(): array
    {
        return [
            'title' => fake()->catchPhrase(),
            'description' => fake()->paragraph(),
            'season' => 'SEASON '.fake()->numberBetween(1, 5),
            'is_live' => fake()->boolean(),
            'is_published' => true,
            'sort_order' => 0,
        ];
    }
}
