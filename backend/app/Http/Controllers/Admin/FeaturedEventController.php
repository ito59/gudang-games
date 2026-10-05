<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Concerns\SyncsUploadedImage;
use App\Http\Controllers\Controller;
use App\Models\FeaturedEvent;
use App\Models\Game;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/** Slides of the app's home carousel. */
class FeaturedEventController extends Controller
{
    use SyncsUploadedImage;

    public function index(): Response
    {
        return Inertia::render('Admin/Events/Index', [
            'events' => FeaturedEvent::with('game:id,title')
                ->orderBy('sort_order')
                ->get(),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Admin/Events/Form', [
            'event' => null,
            'games' => Game::orderBy('title')->get(['id', 'title']),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validated($request);
        unset($data['image'], $data['remove_image']);

        $event = new FeaturedEvent($data);
        $this->syncImage($request, $event, 'events');
        $event->save();

        return to_route('admin.events.index')->with('success', 'Event created.');
    }

    public function edit(FeaturedEvent $event): Response
    {
        return Inertia::render('Admin/Events/Form', [
            'event' => $event,
            'games' => Game::orderBy('title')->get(['id', 'title']),
        ]);
    }

    public function update(Request $request, FeaturedEvent $event): RedirectResponse
    {
        $data = $this->validated($request);
        unset($data['image'], $data['remove_image']);

        $event->fill($data);
        $this->syncImage($request, $event, 'events');
        $event->save();

        return to_route('admin.events.index')->with('success', 'Event updated.');
    }

    public function destroy(FeaturedEvent $event): RedirectResponse
    {
        $event->delete();

        return back()->with('success', 'Event deleted.');
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:140'],
            'description' => ['required', 'string', 'max:1000'],
            'season' => ['required', 'string', 'max:40'],
            'is_live' => ['boolean'],
            ...$this->imageRules(),
            'game_id' => ['nullable', 'exists:games,id'],
            'is_published' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ], $this->imageMessages());
    }
}
