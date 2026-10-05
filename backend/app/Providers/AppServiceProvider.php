<?php

namespace App\Providers;

use App\Services\Google\GoogleIdTokenVerifier;
use App\Services\Google\VerifiesGoogleIdTokens;
use App\Services\Push\FcmPush;
use App\Services\Push\LogPush;
use App\Services\Push\Push;
use Google\Auth\AccessToken;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Firebase when it is configured, a log line when it is not, so every
        // caller can be written and tested before anybody opens a console.
        $this->app->singleton(Push::class, function () {
            $fcm = new FcmPush(
                (string) config('push.fcm.project_id'),
                (string) config('push.fcm.credentials'),
            );

            return $fcm->isConfigured() ? $fcm : new LogPush;
        });

        // Behind an interface so a test can hand the controller a decided
        // answer instead of a real, signed, unexpired Google token.
        $this->app->singleton(
            VerifiesGoogleIdTokens::class,
            fn () => new GoogleIdTokenVerifier(new AccessToken),
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Vite::prefetch(concurrency: 3);
    }
}
