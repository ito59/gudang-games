<script setup>
import { computed, ref } from 'vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

const props = defineProps({
    game: { type: Object, default: null },
    categories: { type: Array, required: true },
    sourceTypes: { type: Array, default: () => ['url', 'zip'] },
    maxBundleMb: { type: Number, default: 20 },
});

const editing = Boolean(props.game);

const form = useForm({
    title: props.game?.title ?? '',
    slug: props.game?.slug ?? '',
    category_id: props.game?.category_id ?? '',
    description: props.game?.description ?? '',
    rating: props.game?.rating ?? 0,
    cover: null,
    remove_cover: false,
    source_type: props.game?.source_type ?? 'url',
    game_url: props.game?.game_url ?? '',
    bundle: null,
    is_published: props.game?.is_published ?? true,
    is_featured: props.game?.is_featured ?? false,
    sort_order: props.game?.sort_order ?? 0,
});

const fileInput = ref(null);
const localPreview = ref(null);
const bundleInput = ref(null);
const bundleName = ref(null);

const isHosted = computed(() => form.source_type === 'zip');
const hasBundle = computed(() => Boolean(props.game?.entry_path));

const pickBundle = (event) => {
    const file = event.target.files[0] ?? null;
    form.bundle = file;
    bundleName.value = file?.name ?? null;
};

const humanSize = (bytes) => {
    if (!bytes) return '';
    const mb = bytes / 1024 / 1024;
    return mb >= 1 ? `${mb.toFixed(1)} MB` : `${Math.round(bytes / 1024)} KB`;
};

// What the preview shows: a freshly picked file, else the stored cover.
const preview = computed(() => {
    if (form.remove_cover) return null;
    return localPreview.value ?? props.game?.cover_url ?? null;
});

const pickFile = (event) => {
    const file = event.target.files[0] ?? null;
    form.cover = file;
    form.remove_cover = false;
    localPreview.value = file ? URL.createObjectURL(file) : null;
};

const clearCover = () => {
    form.cover = null;
    localPreview.value = null;
    if (fileInput.value) fileInput.value.value = '';
    // Only meaningful when a stored cover exists.
    form.remove_cover = Boolean(props.game?.cover_url);
};

const submit = () => {
    if (editing) {
        // Inertia cannot send files over PUT, so the method is spoofed.
        form
            .transform((data) => ({ ...data, _method: 'put' }))
            .post(`/admin/games/${props.game.id}`, { forceFormData: true });
    } else {
        form.post('/admin/games', { forceFormData: true });
    }
};

const field =
    'mt-1 w-full gg-input';
</script>

<template>
    <Head :title="editing ? 'Edit game' : 'New game'" />

    <AdminLayout :title="editing ? `Edit ${game.title}` : 'New game'">
        <form
            class="max-w-2xl space-y-5 gg-card p-6"
            @submit.prevent="submit"
        >
            <div>
                <label class="gg-label">Title</label>
                <input v-model="form.title" type="text" :class="field" />
                <p v-if="form.errors.title" class="mt-1 gg-error">
                    {{ form.errors.title }}
                </p>
            </div>

            <div>
                <label class="gg-label">
                    Slug
                    <span class="text-ink-muted">— left blank, generated from the title</span>
                </label>
                <input v-model="form.slug" type="text" :class="field" />
                <p v-if="form.errors.slug" class="mt-1 gg-error">
                    {{ form.errors.slug }}
                </p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="gg-label">Category</label>
                    <select v-model="form.category_id" :class="field">
                        <option value="">Uncategorised</option>
                        <option v-for="c in categories" :key="c.id" :value="c.id">
                            {{ c.name }}
                        </option>
                    </select>
                </div>

                <div>
                    <label class="gg-label">Rating (0–5)</label>
                    <input
                        v-model="form.rating"
                        type="number"
                        step="0.1"
                        min="0"
                        max="5"
                        :class="field"
                    />
                    <p v-if="form.errors.rating" class="mt-1 gg-error">
                        {{ form.errors.rating }}
                    </p>
                </div>
            </div>

            <div>
                <label class="gg-label">Description</label>
                <textarea v-model="form.description" rows="4" :class="field" />
            </div>

            <!-- How the game is delivered -->
            <div class="rounded-card border border-line-soft bg-fill-alt/50 p-4">
                <p class="gg-label">Game type</p>

                <div class="mt-3 flex flex-wrap gap-2">
                    <button
                        v-for="type in sourceTypes"
                        :key="type"
                        type="button"
                        class="rounded-full border px-4 py-2 text-sm font-medium capitalize transition"
                        :class="
                            form.source_type === type
                                ? 'border-brand/30 bg-brand/10 text-brand'
                                : 'border-line bg-white text-ink-soft hover:bg-fill'
                        "
                        @click="form.source_type = type"
                    >
                        {{ type === 'url' ? 'External URL' : 'Upload ZIP' }}
                    </button>
                </div>
                <p v-if="form.errors.source_type" class="mt-1 gg-error">
                    {{ form.errors.source_type }}
                </p>

                <!-- URL -->
                <div v-if="!isHosted" class="mt-4">
                    <label class="gg-label">Game URL</label>
                    <input
                        v-model="form.game_url"
                        type="url"
                        placeholder="https://games.example.com/neon-guardian"
                        :class="field"
                    />
                    <p v-if="form.errors.game_url" class="mt-1 gg-error">
                        {{ form.errors.game_url }}
                    </p>
                    <p class="mt-1 text-xs text-ink-muted">
                        The app opens this link. Nothing is hosted here.
                    </p>
                </div>

                <!-- ZIP -->
                <div v-else class="mt-4 space-y-2">
                    <label class="gg-label">Game bundle (.zip)</label>
                    <input
                        ref="bundleInput"
                        type="file"
                        accept=".zip,application/zip"
                        class="gg-file"
                        @change="pickBundle"
                    />
                    <p class="text-xs text-ink-muted">
                        Must contain an <code>index.html</code>, at the root or inside a
                        single folder. Up to {{ maxBundleMb }} MB.
                    </p>

                    <p v-if="bundleName" class="text-xs text-gold-link">
                        Selected: {{ bundleName }}
                    </p>

                    <div
                        v-else-if="hasBundle"
                        class="rounded-xl gg-well p-3 text-xs"
                    >
                        <p class="text-ink-soft">
                            Hosted: <code>{{ game.entry_path }}</code>
                            <span v-if="game.bundle_size" class="text-ink-muted">
                                · {{ humanSize(game.bundle_size) }}
                            </span>
                        </p>
                        <a
                            v-if="game.play_url"
                            :href="game.play_url"
                            target="_blank"
                            rel="noopener"
                            class="mt-1 inline-block gg-link"
                        >
                            Open the game ↗
                        </a>
                        <p class="mt-1 text-ink-muted">
                            Uploading a new ZIP replaces it.
                        </p>
                    </div>

                    <p v-if="form.errors.bundle" class="gg-error">
                        {{ form.errors.bundle }}
                    </p>
                </div>
            </div>

            <!-- Cover upload -->
            <div>
                <label class="gg-label">Cover image</label>

                <div class="mt-2 flex flex-wrap items-start gap-4">
                    <div
                        class="grid h-28 w-44 shrink-0 place-items-center overflow-hidden rounded-xl gg-well"
                    >
                        <img
                            v-if="preview"
                            :src="preview"
                            alt="Cover preview"
                            class="h-full w-full object-cover"
                        />
                        <span v-else class="text-xs text-ink-muted">No cover</span>
                    </div>

                    <div class="space-y-2">
                        <input
                            ref="fileInput"
                            type="file"
                            accept="image/jpeg,image/png,image/webp"
                            class="gg-file"
                            @change="pickFile"
                        />
                        <p class="text-xs text-ink-muted">
                            JPG, PNG or WebP, up to 4 MB.
                        </p>

                        <button
                            v-if="preview"
                            type="button"
                            class="text-xs gg-link-danger"
                            @click="clearCover"
                        >
                            Remove cover
                        </button>

                        <p v-if="form.progress" class="text-xs text-gold-link">
                            Uploading… {{ form.progress.percentage }}%
                        </p>
                        <p v-if="form.errors.cover" class="gg-error">
                            {{ form.errors.cover }}
                        </p>
                    </div>
                </div>
            </div>

            <div>
                <label class="gg-label">Sort order</label>
                <input v-model="form.sort_order" type="number" min="0" :class="field" />
            </div>

            <div class="space-y-2">
                <label class="flex items-center gap-2 text-sm text-ink-soft">
                    <input
                        v-model="form.is_published"
                        type="checkbox"
                        class="gg-check"
                    />
                    Published — visible in the app
                </label>

                <label class="flex items-center gap-2 text-sm text-ink-soft">
                    <input
                        v-model="form.is_featured"
                        type="checkbox"
                        :disabled="!form.is_published"
                        class="gg-check disabled:opacity-40"
                    />
                    Featured — shown in the app's home slider
                </label>
                <p v-if="!form.is_published" class="pl-6 text-xs text-ink-muted">
                    Only a published game can be featured.
                </p>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <button
                    type="submit"
                    :disabled="form.processing"
                    class="btn-gold"
                >
                    {{ editing ? 'Save changes' : 'Create game' }}
                </button>
                <Link href="/admin/games" class="text-sm text-ink-soft hover:text-ink hover:underline">
                    Cancel
                </Link>
                <Link
                    v-if="editing"
                    :href="`/admin/games/${game.id}/trailer`"
                    class="ml-auto text-sm gg-link"
                >
                    Trailer video →
                </Link>
            </div>
        </form>
    </AdminLayout>
</template>
