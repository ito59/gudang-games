<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

/**
 * Makes an administrator without anyone having to paste PHP into tinker.
 *
 * An email that already belongs to a member promotes them instead of failing,
 * because "make this person an admin" and "create an admin" are the same
 * intent arriving from two different starting points.
 */
class CreateAdmin extends Command
{
    protected $signature = 'admin:create
        {--name= : Display name}
        {--username= : Handle, letters, numbers and underscores}
        {--email= : Sign-in address}
        {--password= : Leave unset to be prompted without it being echoed}';

    protected $description = 'Create an administrator, or promote an existing member to one';

    public function handle(): int
    {
        $email = $this->option('email') ?: $this->ask('Email');

        $existing = User::where('email', $email)->first();

        if ($existing !== null) {
            return $this->promote($existing);
        }

        $name = $this->option('name') ?: $this->ask('Name');
        $username = $this->option('username')
            ?: $this->ask('Username', User::uniqueUsername($email));
        $password = $this->option('password') ?: $this->secret('Password');

        $data = compact('name', 'username', 'email', 'password');

        $validator = Validator::make($data, [
            'name' => ['required', 'string', 'max:120'],
            'username' => [
                'required', 'string', 'min:3', 'max:40',
                'regex:/^[a-zA-Z0-9_]+$/', Rule::unique('users', 'username'),
            ],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')],
            // The panel edits every game, member and post, so a guessable
            // password here is the whole dashboard.
            'password' => ['required', Password::min(12)->letters()->numbers()],
        ]);

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }

        $user = User::create($data + [
            'password' => Hash::make($password),
            'is_admin' => true,
            'is_active' => true,
        ]);

        $this->info("Administrator created: {$user->email} (@{$user->username})");

        return self::SUCCESS;
    }

    private function promote(User $user): int
    {
        if ($user->is_admin) {
            $this->line("{$user->email} is already an administrator.");

            return self::SUCCESS;
        }

        if (! $this->confirm("{$user->name} <{$user->email}> already exists. Make them an administrator?", true)) {
            return self::FAILURE;
        }

        $user->update(['is_admin' => true]);
        $this->info("Promoted: {$user->email} (@{$user->username})");

        return self::SUCCESS;
    }
}
