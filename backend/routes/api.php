<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AvatarController;
use App\Http\Controllers\Api\BlockController;
use App\Http\Controllers\Api\CatalogueController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ConfigController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\FriendController;
use App\Http\Controllers\Api\MemberController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PresenceController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Middleware\TrackPresence;
use Illuminate\Support\Facades\Route;

/*
 * Consumed by the Flutter client. Reads are public so the app can render its
 * home screen before anyone signs in; writes need a Sanctum token.
 */
Route::prefix('v1')->group(function () {
    Route::post('login', [AuthController::class, 'login'])->name('api.login');
    Route::post('auth/google', [AuthController::class, 'google'])->name('api.auth.google');

    Route::get('config', [ConfigController::class, 'show'])->name('api.config');
    Route::get('report-reasons', [ReportController::class, 'reasons']);

    Route::get('categories', [CatalogueController::class, 'categories']);
    Route::get('games', [CatalogueController::class, 'games']);
    Route::post('games/{game:slug}/play', [CatalogueController::class, 'recordPlay']);
    Route::get('featured', [CatalogueController::class, 'featured']);
    Route::get('members', [MemberController::class, 'index']);
    Route::get('members/{user}', [MemberController::class, 'show']);
    Route::get('feed', [FeedController::class, 'index']);
    Route::get('feed/{post}/comments', [FeedController::class, 'comments']);

    Route::middleware(['auth:sanctum', TrackPresence::class])->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('me/presence', [PresenceController::class, 'store']);
        Route::delete('me/presence', [PresenceController::class, 'destroy']);
        Route::patch('me', [AuthController::class, 'updateMe']);
        Route::get('me/notifications', [NotificationController::class, 'show']);
        Route::patch('me/notifications', [NotificationController::class, 'update']);
        Route::post('me/devices', [NotificationController::class, 'registerDevice']);
        Route::delete('me/devices', [NotificationController::class, 'forgetDevice']);
        Route::post('me/avatar', [AvatarController::class, 'store']);
        Route::delete('me/avatar', [AvatarController::class, 'destroy']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('feed', [FeedController::class, 'store']);
        Route::post('feed/{post}/comments', [FeedController::class, 'comment']);
        Route::post('feed/{post}/like', [FeedController::class, 'like']);
        Route::delete('feed/{post}/like', [FeedController::class, 'unlike']);
        Route::get('conversations', [ChatController::class, 'index']);
        Route::post('conversations', [ChatController::class, 'store']);
        Route::get('conversations/{conversation}/messages', [ChatController::class, 'messages']);
        Route::post('conversations/{conversation}/messages', [ChatController::class, 'send']);
        Route::post('conversations/{conversation}/read', [ChatController::class, 'read']);
        Route::post('reports', [ReportController::class, 'store']);
        Route::get('me/blocks', [BlockController::class, 'index']);
        Route::post('members/{user}/block', [BlockController::class, 'store']);
        Route::delete('members/{user}/block', [BlockController::class, 'destroy']);
        Route::get('friend-requests', [FriendController::class, 'index']);
        Route::post('members/{user}/friend', [FriendController::class, 'store']);
        Route::post('members/{user}/friend/accept', [FriendController::class, 'accept']);
        Route::delete('members/{user}/friend', [FriendController::class, 'destroy']);
    });
});
