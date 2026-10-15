<?php

use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\GameController;
use App\Http\Controllers\Admin\GameTrailerController;
use App\Http\Controllers\Admin\PostController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\GamePlayController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\LegalController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TrailerController;
use Illuminate\Support\Facades\Route;

/*
 * The public landing page. Admins sign in at /login and work from /admin.
 */
Route::get('/', HomeController::class)->name('home');

/*
 * Public, because Play Console links to them. /privacy
 * is the address people guess, so it lands on the same page.
 */
Route::get('/policy', [LegalController::class, 'privacy'])->name('legal.privacy');
Route::redirect('/privacy', '/policy');
Route::get('/terms', [LegalController::class, 'terms'])->name('legal.terms');

/*
 * Breeze redirects here after login, registration and email verification, so
 * the name has to exist. Admins land in the panel; everyone else keeps their
 * account page, since the app itself is the Flutter client.
 */
Route::get('/dashboard', function () {
    return redirect(request()->user()->is_admin ? '/admin' : '/profile');
})->middleware(['auth'])->name('dashboard');

/*
 * Hosted game bundles live in protected storage, so they are streamed by the
 * app rather than served from a public directory.
 */
Route::get('/games/{game:slug}/play/{path?}', GamePlayController::class)
    ->where('path', '.*')
    ->name('games.play');

Route::get('/games/{game:slug}/trailer', TrailerController::class)
    ->name('games.trailer');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

Route::middleware(['auth', 'admin'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {
        Route::get('/', DashboardController::class)->name('dashboard');

        Route::resource('games', GameController::class)->except('show');

        // Trailers get their own page: the uploads are large enough that a
        // failure should not cost the rest of a game's edits.
        Route::get('games/{game}/trailer', [GameTrailerController::class, 'edit'])
            ->name('games.trailer.edit');
        Route::post('games/{game}/trailer', [GameTrailerController::class, 'update'])
            ->name('games.trailer.update');
        Route::delete('games/{game}/trailer', [GameTrailerController::class, 'destroy'])
            ->name('games.trailer.destroy');

        Route::resource('categories', CategoryController::class)
            ->only(['index', 'store', 'update', 'destroy']);

        Route::resource('users', UserController::class)
            ->only(['index', 'create', 'store', 'edit', 'update', 'destroy']);

        Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
        Route::patch('reports/{report}', [ReportController::class, 'update'])->name('reports.update');

        Route::resource('posts', PostController::class)->except('show');
        Route::patch('posts/{post}/toggle', [PostController::class, 'togglePublished'])
            ->name('posts.toggle');
    });

require __DIR__.'/auth.php';
