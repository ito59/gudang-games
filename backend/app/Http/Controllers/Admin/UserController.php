<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Inertia\Inertia;
use Inertia\Response;

class UserController extends Controller
{
    public function index(Request $request): Response
    {
        $users = User::query()
            ->when($request->string('search')->trim()->value(), function ($query, string $search) {
                $query->where(fn ($q) => $q
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%"));
            })
            ->when($request->string('status')->value() === 'online', fn ($q) => $q->online())
            ->when($request->string('status')->value() === 'suspended', fn ($q) => $q->where('is_active', false))
            ->withCount('posts')
            ->orderBy('name')
            ->paginate(10)
            ->withQueryString()
            ->through(fn (User $user) => $user->setAttribute('is_online', $user->isOnline()));

        return Inertia::render('Admin/Users/Index', [
            'users' => $users,
            'filters' => $request->only('search', 'status'),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Admin/Users/Form', ['user' => null]);
    }

    /**
     * Opens an account from the panel, administrator or not.
     *
     * Only the essentials are asked for: the profile fields have defaults and
     * are editable straight afterwards, and a twelve-field form is a poor way
     * to ask for something as small as "let this person in".
     */
    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'username' => [
                'required', 'string', 'min:3', 'max:40',
                'regex:/^[a-zA-Z0-9_]+$/', Rule::unique('users', 'username'),
            ],
            'email' => ['required', 'email', 'max:190', Rule::unique('users', 'email')],
            // Matches `admin:create`: this account can edit every game,
            // member and post, so a guessable password is the whole panel.
            'password' => ['required', 'confirmed', Password::min(12)->letters()->numbers()],
            'is_admin' => ['boolean'],
            'is_active' => ['boolean'],
        ], [
            'username.regex' => 'A username can only use letters, numbers and underscores.',
        ]);

        $user = User::create([
            ...$data,
            'password' => Hash::make($data['password']),
            'is_admin' => $request->boolean('is_admin'),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return to_route('admin.users.index')->with(
            'success',
            $user->is_admin
                ? "Administrator {$user->name} created."
                : "Member {$user->name} created."
        );
    }

    public function edit(User $user): Response
    {
        return Inertia::render('Admin/Users/Form', [
            'user' => $user->loadCount('posts'),
        ]);
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'username' => [
                'required', 'string', 'max:40', 'regex:/^[a-zA-Z0-9_]+$/',
                Rule::unique('users', 'username')->ignore($user->id),
            ],
            'email' => [
                'required', 'email', 'max:190',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'bio' => ['nullable', 'string', 'max:280'],
            'location' => ['nullable', 'string', 'max:120'],
            'accent_color' => ['required', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'playing' => ['nullable', 'string', 'max:120'],
            'games_owned' => ['integer', 'min:0'],
            'hours_played' => ['integer', 'min:0'],
            'achievements' => ['integer', 'min:0'],
            'is_admin' => ['boolean'],
            'is_active' => ['boolean'],
        ]);

        $this->guardLastAdmin($user, (bool) ($data['is_admin'] ?? false));
        $user->update($data);

        return to_route('admin.users.index')->with('success', 'User updated.');
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        if ($request->user()->is($user)) {
            return back()->withErrors(['user' => 'You cannot delete your own account.']);
        }

        $this->guardLastAdmin($user, false);
        $user->delete();

        return back()->with('success', 'User deleted.');
    }

    /**
     * Removing the final administrator would lock everyone out of the panel.
     */
    private function guardLastAdmin(User $user, bool $willBeAdmin): void
    {
        if (! $user->is_admin || $willBeAdmin) {
            return;
        }

        abort_if(User::admins()->count() <= 1, 422, 'The last administrator cannot be removed.');
    }
}
