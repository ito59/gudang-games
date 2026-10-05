<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class CategoryController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Admin/Categories/Index', [
            'categories' => Category::withCount('games')
                ->orderBy('sort_order')
                ->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        Category::create($this->validated($request));

        return back()->with('success', 'Category created.');
    }

    public function update(Request $request, Category $category): RedirectResponse
    {
        $category->update($this->validated($request, $category));

        return back()->with('success', 'Category updated.');
    }

    public function destroy(Category $category): RedirectResponse
    {
        // Games keep existing; their category is nulled by the FK rule.
        $category->delete();

        return back()->with('success', 'Category deleted.');
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request, ?Category $category = null): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:60'],
            'slug' => [
                'nullable', 'string', 'max:80',
                Rule::unique('categories', 'slug')->ignore($category?->id),
            ],
            'icon' => ['required', 'string', 'max:60'],
            'sort_order' => ['integer', 'min:0'],
        ]);
    }
}
