<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Google\GoogleAccount;
use App\Services\Google\VerifiesGoogleIdTokens;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Token auth for the Flutter client (Sanctum personal access tokens). */
class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['required', 'string', 'max:120'],
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['These credentials do not match our records.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['This account is suspended.'],
            ]);
        }

        return response()->json([
            'token' => $user->createToken($credentials['device_name'])->plainTextToken,
            'user' => new UserResource($user),
        ]);
    }

    /**
     * Signs in with a Google ID token obtained by the app.
     *
     * The token is verified here rather than trusted: anything the client
     * sends is just a claim until Google's signature says otherwise.
     */
    public function google(Request $request, VerifiesGoogleIdTokens $google): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['required', 'string'],
            'device_name' => ['required', 'string', 'max:120'],
        ]);

        if (! $google->isConfigured()) {
            return response()->json([
                'message' => 'Google sign-in is not enabled on this server.',
            ], 503);
        }

        $account = $google->verify($data['id_token']);

        if (! $account instanceof GoogleAccount) {
            throw ValidationException::withMessages([
                'id_token' => ['That Google sign-in could not be verified.'],
            ]);
        }

        if (! $account->emailVerified) {
            // Matching on an address Google has not confirmed would let anyone
            // who merely claims it walk into an existing account.
            throw ValidationException::withMessages([
                'id_token' => ['This Google account has no verified email address.'],
            ]);
        }

        $user = User::where('google_id', $account->subject)->first()
            ?? User::where('email', $account->email)->first();

        if ($user && ! $user->is_active) {
            throw ValidationException::withMessages([
                'id_token' => ['This account is suspended.'],
            ]);
        }

        $user = $user ? $this->linkGoogleAccount($user, $account) : $this->createFromGoogle($account);

        return response()->json([
            'token' => $user->createToken($data['device_name'])->plainTextToken,
            'user' => new UserResource($user),
            'created' => $user->wasRecentlyCreated,
        ]);
    }

    /** Attaches the Google identity to an account that already existed here. */
    private function linkGoogleAccount(User $user, GoogleAccount $account): User
    {
        $user->google_id = $account->subject;
        $user->google_avatar_url = $account->picture;
        $user->email_verified_at ??= now();
        $user->save();

        return $user;
    }

    private function createFromGoogle(GoogleAccount $account): User
    {
        $user = new User([
            'name' => $account->name ?: 'Player',
            'username' => User::uniqueUsername($account->email),
            'email' => $account->email,
            'accent_color' => $this->accentFor($account->subject),
            'location' => '',
            'bio' => '',
        ]);

        // Not fillable on purpose: an identity must never arrive through mass
        // assignment on some other endpoint.
        $user->google_id = $account->subject;
        $user->google_avatar_url = $account->picture;
        $user->email_verified_at = now();
        $user->save();

        return $user;
    }

    /** Stable per account, so someone's avatar tint does not change on them. */
    private function accentFor(string $subject): string
    {
        $palette = ['#7C3AED', '#14D1FF', '#FFB2BA', '#4ADE80', '#FFC46B'];

        return $palette[abs(crc32($subject)) % count($palette)];
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    /**
     * Updates the fields a member owns.
     *
     * Deliberately narrow: email, stats and admin flags are not editable from
     * the app, so only these four are read off the request.
     */
    public function updateMe(Request $request): UserResource
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'username' => [
                'required', 'string', 'min:3', 'max:40', 'regex:/^[a-zA-Z0-9_]+$/',
                Rule::unique('users', 'username')->ignore($user->id),
            ],
            'bio' => ['nullable', 'string', 'max:280'],
            'location' => ['nullable', 'string', 'max:120'],
        ], [
            'username.regex' => 'A username can only use letters, numbers and underscores.',
            'username.unique' => 'That username is taken.',
        ]);

        $user->update([
            'name' => $data['name'],
            'username' => $data['username'],
            // Cleared fields arrive as null; store them as empty strings so
            // the app never has to tell null and "" apart.
            'bio' => $data['bio'] ?? '',
            'location' => $data['location'] ?? '',
        ]);

        return new UserResource($user);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        $request->user()->markAway();

        return response()->json(['message' => 'Signed out.']);
    }
}
