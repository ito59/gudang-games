<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Game;
use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeds the same catalogue the Flutter app ships as mock data, so the app can
 * be pointed at this API and look identical.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::create([
            'name' => 'Rey Anandra',
            'username' => 'neonrey',
            'email' => 'admin@bandargames.test',
            'password' => Hash::make('password'),
            'bio' => 'Night-shift raider. Chasing platinum trophies and clean apex lines.',
            'location' => 'Jakarta, ID',
            'accent_color' => '#D2BBFF',
            'games_owned' => 128,
            'hours_played' => 1472,
            'achievements' => 96,
            'playing' => 'Neon Guardian',
            'is_admin' => true,
            'email_verified_at' => now(),
        ]);

        $categories = collect([
            ['name' => 'Action', 'icon' => 'swords'],
            ['name' => 'RPG', 'icon' => 'magic_button'],
            ['name' => 'Strategy', 'icon' => 'chess'],
            ['name' => 'Sports', 'icon' => 'sports_soccer'],
            ['name' => 'Racing', 'icon' => 'speed'],
        ])->map(fn (array $data, int $i) => Category::create($data + ['sort_order' => $i]));

        $bySlug = $categories->keyBy('slug');

        $games = collect([
            ['title' => 'Neon Guardian', 'category' => 'action', 'rating' => 4.9],
            ['title' => 'Mystic Ruin', 'category' => 'rpg', 'rating' => 4.7],
            ['title' => 'Quantum Rush', 'category' => 'racing', 'rating' => 4.8],
            ['title' => 'Nebula Conflict', 'category' => 'strategy', 'rating' => 4.6],
        ])->map(fn (array $data, int $i) => Game::create([
            'title' => $data['title'],
            'category_id' => $bySlug[$data['category']]->id,
            'rating' => $data['rating'],
            'sort_order' => $i,
            'description' => "{$data['title']} — seeded from the app's mock catalogue.",
        ]))->keyBy('title');

        // The home carousel shows featured games.
        $games['Neon Guardian']->update(['is_featured' => true]);
        $games['Quantum Rush']->update(['is_featured' => true]);

        $members = collect([
            [
                'name' => 'Dita Prameswari', 'username' => 'ditaprams',
                'accent_color' => '#14D1FF', 'playing' => 'Mystic Ruin',
                'bio' => 'Support main. If you are still standing, you are welcome.',
                'games_owned' => 74, 'hours_played' => 980, 'achievements' => 61,
            ],
            [
                'name' => 'Bagas Wirawan', 'username' => 'bagaswr',
                'accent_color' => '#FFB2BA', 'playing' => 'Quantum Rush',
                'bio' => 'Time-trial grinder. Tuning setups until the lap times stop hurting.',
                'games_owned' => 52, 'hours_played' => 1310, 'achievements' => 44,
            ],
            [
                'name' => 'Salsa Nurhaliza', 'username' => 'salsanh',
                'accent_color' => '#4ADE80', 'playing' => 'Nebula Conflict',
                'bio' => 'Strategy nerd. I read patch notes for fun so you do not have to.',
                'games_owned' => 96, 'hours_played' => 720, 'achievements' => 88,
            ],
            [
                'name' => 'Ilham Pratama', 'username' => 'ilhamp',
                'accent_color' => '#FFC46B', 'playing' => 'Neon Guardian',
                'bio' => 'Clip hunter. Every match is a highlight reel waiting to happen.',
                'games_owned' => 41, 'hours_played' => 505, 'achievements' => 33,
            ],
            [
                'name' => 'Kirana Ayu', 'username' => 'kiranaayu',
                'accent_color' => '#7C3AED', 'playing' => null,
                'bio' => 'Taking a break from ranked. Back for the next season.',
                'games_owned' => 63, 'hours_played' => 1104, 'achievements' => 52,
            ],
        ])->map(fn (array $data) => User::create($data + [
            'email' => $data['username'].'@bandargames.test',
            'password' => Hash::make('password'),
            'location' => 'Jakarta, ID',
            'email_verified_at' => now(),
        ]))->keyBy('username');

        $posts = [
            [
                'author' => 'ditaprams', 'kind' => 'clip', 'game' => 'Neon Guardian',
                'body' => 'Finally cleared the Ascension raid without a single wipe. '
                    .'The trick is holding the west bridge until the second phase.',
                'comments' => 31, 'likes' => 3, 'minutes' => 12,
            ],
            [
                'author' => 'bagaswr', 'kind' => 'squad', 'game' => 'Quantum Rush',
                'body' => 'Squad needs one more for the weekend time trials. '
                    .'Bring a tuned build and good vibes.',
                'comments' => 18, 'likes' => 2, 'minutes' => 48,
            ],
            [
                'author' => 'salsanh', 'kind' => 'update', 'game' => null,
                'body' => 'Season 4 patch notes are live — cooldowns on the support '
                    .'tree got a big rework. Worth respeccing before ranked resets.',
                'comments' => 87, 'likes' => 4, 'minutes' => 120,
            ],
            [
                'author' => 'ilhamp', 'kind' => 'clip', 'game' => 'Nebula Conflict',
                'body' => 'Nebula Conflict late-game push, 200 IQ or pure luck? You decide.',
                'comments' => 24, 'likes' => 1, 'minutes' => 300,
            ],
        ];

        $everyone = $members->values()->push($admin);

        // One announcement, so the feed shows what the dashboard's news kind
        // looks like beside the members' own posts.
        $news = Post::create([
            'user_id' => $admin->id,
            'game_id' => $games['Neon Guardian']->id ?? null,
            'kind' => Post::news,
            'title' => 'Season 2 lands next week',
            'body' => 'Ranked resets on Monday morning, and everybody starts the '
                ."climb from placement again.\n\nTwo maps join the rotation with "
                .'it, both built for the faster respawn timers we tested last '
                ."month.\n\nPatch notes go up here the day before.",
            'comments_count' => 6,
            'published_at' => now()->subMinutes(20),
        ]);
        $news->likers()->attach($everyone->random(3)->pluck('id'));

        foreach ($posts as $data) {
            $post = Post::create([
                'user_id' => $members[$data['author']]->id,
                'game_id' => $data['game'] ? $games[$data['game']]->id : null,
                'body' => $data['body'],
                'kind' => $data['kind'],
                'comments_count' => $data['comments'],
                'published_at' => now()->subMinutes($data['minutes']),
            ]);

            // Spread a few real likes so the counter is not a bare number.
            $post->likers()->attach(
                $everyone->random(min($data['likes'], $everyone->count()))->pluck('id')
            );
        }
    }
}
