<script setup>
import { computed, ref } from 'vue';
import { Head, Link, useForm, usePage } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

const props = defineProps({
    post: { type: Object, default: null },
    kinds: { type: Array, required: true },
    games: { type: Array, required: true },
});

const editing = Boolean(props.post);

// Not a field: a new post is written by whoever is signed in, and editing
// somebody else's post never reassigns it.
const author = computed(() =>
    editing ? props.post.author : usePage().props.auth.user,
);

const form = useForm({
    game_id: props.post?.game_id ?? '',
    title: props.post?.title ?? '',
    body: props.post?.body ?? '',
    kind: props.post?.kind ?? 'update',
    image: null,
    remove_image: false,
    comments_count: props.post?.comments_count ?? 0,
    is_published: props.post?.is_published ?? true,
});

// News is the announcement kind: it is the one that carries a headline, and
// the app gives it a page of its own.
const isNews = computed(() => form.kind === 'news');

const fileInput = ref(null);
const localPreview = ref(null);

// What the preview shows: a freshly picked file, else the stored image.
const preview = computed(() => {
    if (form.remove_image) return null;
    return localPreview.value ?? props.post?.image_url ?? null;
});

const pickFile = (event) => {
    const file = event.target.files[0] ?? null;
    form.image = file;
    form.remove_image = false;
    localPreview.value = file ? URL.createObjectURL(file) : null;
};

const clearImage = () => {
    form.image = null;
    localPreview.value = null;
    if (fileInput.value) fileInput.value.value = '';
    // Only meaningful when a stored image exists.
    form.remove_image = Boolean(props.post?.image_url);
};

const submit = () => {
    if (editing) {
        // Inertia cannot send files over PUT, so the method is spoofed.
        form
            .transform((data) => ({ ...data, _method: 'put' }))
            .post(`/admin/posts/${props.post.id}`, { forceFormData: true });
    } else {
        form.post('/admin/posts', { forceFormData: true });
    }
};

const field =
    'mt-1 w-full rounded-lg border-white/10 bg-[#0B1326] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]';
</script>

<template>
    <Head :title="editing ? 'Edit post' : 'New post'" />

    <AdminLayout :title="editing ? 'Edit post' : 'New post'">
        <form
            class="max-w-2xl space-y-5 rounded-xl border border-white/5 bg-[#171F33] p-6"
            @submit.prevent="submit"
        >
            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Author</label>
                    <div
                        class="mt-1 rounded-lg border border-white/10 bg-[#0B1326] px-3 py-2 text-sm text-[#DAE2FD]"
                    >
                        {{ author?.name }}
                        <span class="text-xs text-[#8B84A3]">
                            @{{ author?.username }}
                        </span>
                    </div>
                    <p class="mt-1 text-xs text-[#8B84A3]">
                        {{
                            editing
                                ? 'Whoever wrote it. Editing does not reassign a post.'
                                : 'Posted as you.'
                        }}
                    </p>
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Kind</label>
                    <select v-model="form.kind" :class="field">
                        <option v-for="k in kinds" :key="k" :value="k">{{ k }}</option>
                    </select>
                </div>
            </div>

            <div v-if="isNews">
                <label class="text-sm text-[#CCC3D8]">Headline</label>
                <input
                    v-model="form.title"
                    type="text"
                    maxlength="120"
                    placeholder="Season 2 lands next week"
                    :class="field"
                />
                <p class="mt-1 text-xs text-[#8B84A3]">
                    Shown on the feed card and at the top of the article page.
                </p>
                <p v-if="form.errors.title" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.title }}
                </p>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">
                    {{ isNews ? 'Article' : 'Body' }}
                </label>
                <textarea
                    v-model="form.body"
                    :rows="isNews ? 12 : 5"
                    :class="field"
                />
                <p v-if="isNews" class="mt-1 text-xs text-[#8B84A3]">
                    Blank lines start a new paragraph in the app.
                </p>
                <p v-if="form.errors.body" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.body }}
                </p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Tagged game</label>
                    <select v-model="form.game_id" :class="field">
                        <option value="">None</option>
                        <option v-for="g in games" :key="g.id" :value="g.id">
                            {{ g.title }}
                        </option>
                    </select>
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Comments count</label>
                    <input v-model="form.comments_count" type="number" min="0" :class="field" />
                </div>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">
                    {{ isNews ? 'Cover image' : 'Image' }}
                </label>

                <div class="mt-2 flex flex-wrap items-start gap-4">
                    <div
                        class="grid h-28 w-44 shrink-0 place-items-center overflow-hidden rounded-lg border border-white/10 bg-[#0B1326]"
                    >
                        <img
                            v-if="preview"
                            :src="preview"
                            alt="Image preview"
                            class="h-full w-full object-cover"
                        />
                        <span v-else class="text-xs text-[#8B84A3]">No image</span>
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
                            @click="clearImage"
                        >
                            Remove image
                        </button>

                        <p v-if="form.progress" class="text-xs text-[#D2BBFF]">
                            Uploading… {{ form.progress.percentage }}%
                        </p>
                        <p v-if="form.errors.image" class="text-xs text-[#FFB2BA]">
                            {{ form.errors.image }}
                        </p>
                    </div>
                </div>
            </div>

            <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                <input
                    v-model="form.is_published"
                    type="checkbox"
                    class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                />
                Published — visible in the app feed
            </label>

            <div class="flex items-center gap-3 pt-2">
                <button
                    type="submit"
                    :disabled="form.processing"
                    class="rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4] disabled:opacity-50"
                >
                    {{ editing ? 'Save changes' : 'Create post' }}
                </button>
                <Link href="/admin/posts" class="text-sm text-[#CCC3D8] hover:underline">
                    Cancel
                </Link>
            </div>
        </form>
    </AdminLayout>
</template>
