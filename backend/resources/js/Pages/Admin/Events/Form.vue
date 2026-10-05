<script setup>
import { computed, ref } from 'vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

const props = defineProps({
    event: { type: Object, default: null },
    games: { type: Array, required: true },
});

const editing = Boolean(props.event);

const form = useForm({
    title: props.event?.title ?? '',
    description: props.event?.description ?? '',
    season: props.event?.season ?? 'SEASON 1',
    is_live: props.event?.is_live ?? false,
    image: null,
    remove_image: false,
    game_id: props.event?.game_id ?? '',
    is_published: props.event?.is_published ?? true,
    sort_order: props.event?.sort_order ?? 0,
});


const fileInput = ref(null);
const localPreview = ref(null);

// What the preview shows: a freshly picked file, else the stored image.
const preview = computed(() => {
    if (form.remove_image) return null;
    return localPreview.value ?? props.event?.image_url ?? null;
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
    form.remove_image = Boolean(props.event?.image_url);
};

const submit = () => {
    if (editing) {
        // Inertia cannot send files over PUT, so the method is spoofed.
        form
            .transform((data) => ({ ...data, _method: 'put' }))
            .post(`/admin/events/${props.event.id}`, { forceFormData: true });
    } else {
        form.post('/admin/events', { forceFormData: true });
    }
};

const field =
    'mt-1 w-full rounded-lg border-white/10 bg-[#0B1326] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]';
</script>

<template>
    <Head :title="editing ? 'Edit event' : 'New event'" />

    <AdminLayout :title="editing ? `Edit ${event.title}` : 'New featured event'">
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
                <label class="text-sm text-[#CCC3D8]">Description</label>
                <textarea v-model="form.description" rows="4" :class="field" />
                <p v-if="form.errors.description" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.description }}
                </p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Season badge</label>
                    <input v-model="form.season" type="text" :class="field" />
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Linked game</label>
                    <select v-model="form.game_id" :class="field">
                        <option value="">None</option>
                        <option v-for="g in games" :key="g.id" :value="g.id">
                            {{ g.title }}
                        </option>
                    </select>
                </div>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">Event image</label>

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

            <div>
                <label class="text-sm text-[#CCC3D8]">Sort order</label>
                <input v-model="form.sort_order" type="number" min="0" :class="field" />
            </div>

            <div class="space-y-2">
                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_live"
                        type="checkbox"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                    />
                    Live — shows the LIVE EVENT badge
                </label>
                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_published"
                        type="checkbox"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                    />
                    Published — appears in the carousel
                </label>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <button
                    type="submit"
                    :disabled="form.processing"
                    class="rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4] disabled:opacity-50"
                >
                    {{ editing ? 'Save changes' : 'Create event' }}
                </button>
                <Link href="/admin/events" class="text-sm text-[#CCC3D8] hover:underline">
                    Cancel
                </Link>
            </div>
        </form>
    </AdminLayout>
</template>
