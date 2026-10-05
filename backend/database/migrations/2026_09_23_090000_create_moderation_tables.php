<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('blocks', function (Blueprint $table) {
            $table->id();
            // Who did the blocking, and who they no longer want to hear from.
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            // Blocking twice is the same as blocking once.
            $table->unique(['user_id', 'blocked_user_id']);
            // Both directions are read on every feed and thread request: a
            // block hides its two people from each other, so the lookup runs
            // from either end.
            $table->index('blocked_user_id');
        });

        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            // A message, post, comment or member. Polymorphic because the
            // queue reads the same either way, and because a fifth kind of
            // reportable thing should not need a fifth table.
            $table->morphs('reportable');
            $table->string('reason', 32);
            $table->string('note', 500)->nullable();
            // A snapshot of what was reported. The content may be deleted —
            // by its author, or by the admin acting on this very report — and
            // a queue that cannot say what it was about is unreviewable.
            $table->text('excerpt')->nullable();
            // Denormalised so the queue can be filtered by who is being
            // reported without a join per kind of reportable.
            $table->foreignId('reported_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 16)->default('pending');
            $table->string('resolution', 32)->nullable();
            $table->foreignId('resolved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            // One report per person per thing: reporting twice is impatience,
            // not new information, and a queue full of duplicates hides the
            // thing that ten different people reported once.
            $table->unique(['reporter_id', 'reportable_type', 'reportable_id'], 'reports_reporter_target_unique');
            $table->index(['status', 'created_at']);
            $table->index(['reported_user_id', 'status']);
        });

        Schema::create('moderation_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            // chat | post | comment — what the author was trying to write.
            $table->string('context', 16);
            // profanity | spam
            $table->string('reason', 16);
            // Which rule it was: the word, or `burst`, `links`, `repeat`…
            $table->string('rule', 64)->nullable();
            // What they tried to send. Kept because a filter nobody can audit
            // is a filter nobody can tune — and a run of these against one
            // member is the evidence for acting on them.
            $table->text('body');
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['reason', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('moderation_events');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('blocks');
    }
};
