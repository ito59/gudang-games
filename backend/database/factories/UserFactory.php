<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            // Handles are validated as [a-zA-Z0-9_], and faker's userName()
            // yields dots; strip them so factory data is never invalid input.
            'username' => preg_replace(
                '/[^a-zA-Z0-9_]/', '', fake()->unique()->userName()
            ),
            'email' => fake()->unique()->safeEmail(),
            'bio' => fake()->sentence(10),
            'location' => fake()->city().', ID',
            'accent_color' => fake()->randomElement(
                ['#7C3AED', '#14D1FF', '#FFB2BA', '#4ADE80', '#FFC46B']
            ),
            'games_owned' => fake()->numberBetween(10, 200),
            'hours_played' => fake()->numberBetween(50, 2000),
            'achievements' => fake()->numberBetween(5, 150),
            'playing' => fake()->boolean(60) ? fake()->randomElement(
                ['Neon Guardian', 'Mystic Ruin', 'Quantum Rush', 'Nebula Conflict']
            ) : null,
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
        ];
    }

    /** An administrator who can reach the admin panel. */
    public function admin(): static
    {
        return $this->state(fn () => ['is_admin' => true]);
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
