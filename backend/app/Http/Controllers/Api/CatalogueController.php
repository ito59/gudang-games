<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GameResource;
use App\Models\Category;
use App\Models\FeaturedEvent;
use App\Models\Game;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Read-only catalogue for the Flutter app's home screen. */
class CatalogueController extends Controller
{
    /**
     * The categories worth showing: the ones with something in them.
     *
     * A chip that leads to an empty list is a dead end, and an unpublished
     * game is no better than none — the app could not show it either.
     */
    public function categories(): JsonResponse
    {
        return response()->json([
            'data' => Category::whereHas('games', fn ($q) => $q->published())
                ->orderBy('sort_order')
                ->get()
                ->map(fn (Category $c) => [
                    'id' => $c->id,
                    'label' => $c->name,
                    'slug' => $c->slug,
                    'icon' => $c->icon,
                ]),
        ]);
    }

    public function games(): AnonymousResourceCollection
    {
        return GameResource::collection(
            Game::published()
                ->with('category:id,name,slug')
                ->orderBy('sort_order')
                ->orderBy('title')
                ->get()
        );
    }

    /**
     * Records one play.
     *
     * Counting here rather than inside the file server keeps asset requests
     * from inflating the number, and treats hosted and linked games alike.
     */
    public function recordPlay(Game $game): JsonResponse
    {
        abort_unless($game->is_published, 404);

        $game->recordPlay();

        return response()->json(['plays_count' => $game->fresh()->plays_count]);
    }

    /**
     * Slides for the app's home carousel.
     *
     * Two sources, one list: hand-written campaign slides, then games an
     * admin has flagged as featured. A game slide carries the game itself, so
     * the app can open it straight from the carousel.
     */
    public function featured(): JsonResponse
    {
        $events = FeaturedEvent::published()
            ->orderBy('sort_order')
            ->get()
            ->map(fn (FeaturedEvent $event) => [
                'id' => 'event-'.$event->id,
                'title' => $event->title,
                'description' => $event->description,
                'season' => $event->season,
                'is_live' => $event->is_live,
                // Uploaded images resolve to a URL; bundled asset paths pass
                // through, the same way a game's cover does.
                'image' => $event->image_url ?? $event->image_path,
                'game' => null,
            ]);

        $games = Game::featured()
            ->with('category:id,name,slug')
            ->orderBy('sort_order')
            ->orderBy('title')
            ->get()
            ->map(fn (Game $game) => [
                'id' => 'game-'.$game->id,
                'title' => $game->title,
                'description' => $game->description ?: 'Featured on BandarGames.',
                'season' => 'FEATURED',
                'is_live' => false,
                'image' => $game->cover_url ?? $game->cover_path,
                'game' => new GameResource($game),
            ]);

        return response()->json(['data' => $events->concat($games)->values()]);
    }
}
