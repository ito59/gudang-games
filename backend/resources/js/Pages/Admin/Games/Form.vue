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
    'mt-1 w-full rounded-lg border-white/10 bg-[#0B1326] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]';
</script>

<template>
    <Head :title="editing ? 'Edit game' : 'New game'" />

    <AdminLayout :title="editing ? `Edit ${game.title}` : 'New game'">
        <form
            class="max-w-2xl space-y-5 rounded-xl border border-white/5 bg-[#171F33] p-6"
            @submit.prevent="submit"
        >
            <div>
                <label class="text-sm text-[#CCC3D8]">Title</label>
                <input v-model="form.title" type="text" :class="field" />
                <p v-if="form.errors.title" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.title }}
                </p>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">
                    Slug
                    <span class="text-[#8B84A3]">— left blank, generated from the title</span>
                </label>
                <input v-model="form.slug" type="text" :class="field" />
                <p v-if="form.errors.slug" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.slug }}
                </p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Category</label>
                    <select v-model="form.category_id" :class="field">
                        <option value="">Uncategorised</option>
                        <option v-for="c in categories" :key="c.id" :value="c.id">
                            {{ c.name }}
                        </option>
                    </select>
                </div>

                <div>
                    <label class="text-sm text-[#CCC3D8]">Rating (0–5)</label>
                    <input
                        v-model="form.rating"
                        type="number"
                        step="0.1"
                        min="0"
                        max="5"
                        :class="field"
                    />
                    <p v-if="form.errors.rating" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.rating }}
                    </p>
                </div>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">Description</label>
                <textarea v-model="form.description" rows="4" :class="field" />
            </div>

            <!-- How the game is delivered -->
            <div class="rounded-lg border border-white/10 p-4">
                <p class="text-sm text-[#CCC3D8]">Game type</p>

                <div class="mt-3 flex flex-wrap gap-2">
                    <button
                        v-for="type in sourceTypes"
                        :key="type"
                        type="button"
                        class="rounded-lg border px-4 py-2 text-sm capitalize transition"
                        :class="
                            form.source_type === type
                                ? 'border-[#7C3AED] bg-[#7C3AED]/25 text-[#D2BBFF]'
                                : 'border-white/10 text-[#CCC3D8] hover:bg-white/5'
                        "
                        @click="form.source_type = type"
                    >
                        {{ type === 'url' ? 'External URL' : 'Upload ZIP' }}
                    </button>
                </div>
                <p v-if="form.errors.source_type" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.source_type }}
                </p>

                <!-- URL -->
                <div v-if="!isHosted" class="mt-4">
                    <label class="text-sm text-[#CCC3D8]">Game URL</label>
                    <input
                        v-model="form.game_url"
                        type="url"
                        placeholder="https://games.example.com/neon-guardian"
                        :class="field"
                    />
                    <p v-if="form.errors.game_url" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.game_url }}
                    </p>
                    <p class="mt-1 text-xs text-[#8B84A3]">
                        The app opens this link. Nothing is hosted here.
                    </p>
                </div>

                <!-- ZIP -->
                <div v-else class="mt-4 space-y-2">
                    <label class="text-sm text-[#CCC3D8]">Game bundle (.zip)</label>
                    <input
                        ref="bundleInput"
                        type="file"
                        accept=".zip,application/zip"
                        class="block w-full text-sm text-[#CCC3D8] file:mr-3 file:rounded-lg file:border-0 file:bg-[#7C3AED] file:px-4 file:py-2 file:text-sm file:font-medium file:text-white hover:file:bg-[#732EE4]"
                        @change="pickBundle"
                    />
                    <p class="text-xs text-[#8B84A3]">
                        Must contain an <code>index.html</code>, at the root or inside a
                        single folder. Up to {{ maxBundleMb }} MB.
                    </p>

                    <p v-if="bundleName" class="text-xs text-[#D2BBFF]">
                        Selected: {{ bundleName }}
                    </p>

                    <div
                        v-else-if="hasBundle"
                        class="rounded-lg border border-white/10 bg-[#0B1326] p-3 text-xs"
                    >
                        <p class="text-[#CCC3D8]">
                            Hosted: <code>{{ game.entry_path }}</code>
                            <span v-if="game.bundle_size" class="text-[#8B84A3]">
                                · {{ humanSize(game.bundle_size) }}
                            </span>
                        </p>
                        <a
                            v-if="game.play_url"
                            :href="game.play_url"
                            target="_blank"
                            rel="noopener"
                            class="mt-1 inline-block text-[#D2BBFF] hover:underline"
                        >
                            Open the game ↗
                        </a>
                        <p class="mt-1 text-[#8B84A3]">
                            Uploading a new ZIP replaces it.
                        </p>
                    </div>

                    <p v-if="form.errors.bundle" class="text-xs text-[#FFB2BA]">
                        {{ form.errors.bundle }}
                    </p>
                </div>
            </div>

            <!-- Cover upload -->
            <div>
                <label class="text-sm text-[#CCC3D8]">Cover image</label>

                <div class="mt-2 flex flex-wrap items-start gap-4">
                    <div
                        class="grid h-28 w-44 shrink-0 place-items-center overflow-hidden rounded-lg border border-white/10 bg-[#0B1326]"
                    >
                        <img
                            v-if="preview"
                            :src="preview"
                            alt="Cover preview"
                            class="h-full w-full object-cover"
                        />
                        <span v-else class="text-xs text-[#8B84A3]">No cover</span>
                    </div>

                    <div class="space-y-2">
                        <input
                            ref="fileInput"
                            type="file"
                            accept="image/jpeg,image/png,image/webp"
                            class="block w-full text-sm text-[#CCC3D8] file:mr-3 file:rounded-lg file:border-0 file:bg-[#7C3AED] file:px-4 file:py-2 file:text-sm file:font-medium file:text-white hover:file:bg-[#732EE4]"
                            @change="pickFile"
                        />
                        <p class="text-xs text-[#8B84A3]">
                            JPG, PNG or WebP, up to 4 MB.
                        </p>

                        <button
                            v-if="preview"
                            type="button"
                            class="text-xs text-[#FFB2BA] hover:underline"
                            @click="clearCover"
                        >
                            Remove cover
                        </button>

                        <p v-if="form.progress" class="text-xs text-[#D2BBFF]">
                            Uploading… {{ form.progress.percentage }}%
                        </p>
                        <p v-if="form.errors.cover" class="text-xs text-[#FFB2BA]">
                            {{ form.errors.cover }}
                        </p>
                    </div>
                </div>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">Sort order</label>
                <input v-model="form.sort_order" type="number" min="0" :class="field" />
            </div>

            <div class="space-y-2">
                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_published"
                        type="checkbox"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                    />
                    Published — visible in the app
                </label>

                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_featured"
                        type="checkbox"
                        :disabled="!form.is_published"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED] disabled:opacity-40"
                    />
                    Featured — shown in the app's home slider
                </label>
                <p v-if="!form.is_published" class="pl-6 text-xs text-[#8B84A3]">
                    Only a published game can be featured.
                </p>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <button
                    type="submit"
                    :disabled="form.processing"
                    class="rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4] disabled:opacity-50"
                >
                    {{ editing ? 'Save changes' : 'Create game' }}
                </button>
                <Link href="/admin/games" class="text-sm text-[#CCC3D8] hover:underline">
                    Cancel
                </Link>
                <Link
                    v-if="editing"
                    :href="`/admin/games/${game.id}/trailer`"
                    class="ml-auto text-sm text-[#D2BBFF] hover:underline"
                >
                    Trailer video →
                </Link>
            </div>
        </form>
    </AdminLayout>
</template>
