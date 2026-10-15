<script setup>
import { computed, ref } from 'vue';
import { Head, Link, router, useForm } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

const props = defineProps({
    game: { type: Object, required: true },
    maxTrailerMb: { type: Number, default: 20 },
});

const form = useForm({ trailer: null });

const fileInput = ref(null);
const picked = ref(null);
const localPreview = ref(null);

const hasTrailer = computed(() => Boolean(props.game.trailer_url));

const pickFile = (event) => {
    const file = event.target.files[0] ?? null;
    form.trailer = file;
    picked.value = file;
    localPreview.value = file ? URL.createObjectURL(file) : null;
};

const submit = () => {
    form.post(`/admin/games/${props.game.id}/trailer`, {
        forceFormData: true,
        onSuccess: () => {
            form.reset();
            picked.value = null;
            localPreview.value = null;
            if (fileInput.value) fileInput.value.value = '';
        },
    });
};

const remove = () => {
    if (confirm('Remove this trailer?')) {
        router.delete(`/admin/games/${props.game.id}/trailer`, {
            preserveScroll: true,
        });
    }
};

const humanSize = (bytes) => {
    if (!bytes) return '';
    const mb = bytes / 1024 / 1024;
    return mb >= 1 ? `${mb.toFixed(1)} MB` : `${Math.round(bytes / 1024)} KB`;
};
</script>

<template>
    <Head :title="`Trailer — ${game.title}`" />

    <AdminLayout :title="`Trailer — ${game.title}`">
        <div class="max-w-2xl space-y-5">
            <p class="text-sm text-ink-muted">
                Uploaded separately from the game's details, because video
                files are large — a slow upload here never risks the rest of
                the game's data.
            </p>

            <!-- What is stored now -->
            <section
                v-if="hasTrailer"
                class="space-y-3 gg-card p-5"
            >
                <h2 class="font-display font-semibold text-ink">Current trailer</h2>

                <video
                    :src="game.trailer_url"
                    controls
                    preload="metadata"
                    class="w-full rounded-xl bg-ink"
                />

                <p class="text-xs text-ink-muted">
                    {{ game.trailer_mime }} · {{ humanSize(game.trailer_size) }}
                </p>

                <button
                    type="button"
                    class="text-sm gg-link-danger"
                    @click="remove"
                >
                    Remove trailer
                </button>
            </section>

            <p
                v-else
                class="gg-card px-5 py-8 text-center text-sm text-ink-muted"
            >
                No trailer uploaded yet.
            </p>

            <!-- Upload -->
            <form
                class="space-y-4 gg-card p-5"
                @submit.prevent="submit"
            >
                <h2 class="font-display font-semibold text-ink">
                    {{ hasTrailer ? 'Replace trailer' : 'Upload trailer' }}
                </h2>

                <input
                    ref="fileInput"
                    type="file"
                    accept="video/mp4,video/webm,video/quicktime"
                    class="gg-file"
                    @change="pickFile"
                />

                <p class="text-xs text-ink-muted">
                    MP4, WebM or MOV, up to {{ maxTrailerMb }} MB.
                    Uploading a new file replaces the current one.
                </p>

                <video
                    v-if="localPreview"
                    :src="localPreview"
                    controls
                    preload="metadata"
                    class="w-full rounded-xl bg-ink"
                />

                <p v-if="picked" class="text-xs text-gold-link">
                    {{ picked.name }} · {{ humanSize(picked.size) }}
                </p>

                <!-- Large files take a while; show real progress. -->
                <div v-if="form.progress" class="space-y-1">
                    <div class="h-2 overflow-hidden rounded-full bg-fill">
                        <div
                            class="h-full bg-gradient-to-r from-gold-deep via-gold to-gold-light transition-all"
                            :style="{ width: `${form.progress.percentage}%` }"
                        />
                    </div>
                    <p class="text-xs text-gold-link">
                        Uploading… {{ form.progress.percentage }}%
                    </p>
                </div>

                <p v-if="form.errors.trailer" class="gg-error">
                    {{ form.errors.trailer }}
                </p>

                <div class="flex items-center gap-3 pt-1">
                    <button
                        type="submit"
                        :disabled="form.processing || !picked"
                        class="btn-gold"
                    >
                        {{ form.processing ? 'Uploading…' : 'Upload' }}
                    </button>
                    <Link
                        :href="`/admin/games/${game.id}/edit`"
                        class="text-sm text-ink-soft hover:text-ink hover:underline"
                    >
                        Back to game
                    </Link>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>
