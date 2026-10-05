<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';

const props = defineProps({
    posts: { type: Object, required: true },
    kinds: { type: Array, required: true },
    filters: { type: Object, default: () => ({}) },
});

const search = ref(props.filters.search ?? '');
const kind = ref(props.filters.kind ?? '');
const status = ref(props.filters.status ?? '');

let timer;
watch([search, kind, status], () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
        router.get(
            '/admin/posts',
            {
                search: search.value || undefined,
                kind: kind.value || undefined,
                status: status.value || undefined,
            },
            { preserveState: true, replace: true },
        );
    }, 300);
});

const toggle = (post) =>
    router.patch(`/admin/posts/${post.id}/toggle`, {}, { preserveScroll: true });

const destroy = (post) => {
    if (confirm('Delete this post? This cannot be undone.')) {
        router.delete(`/admin/posts/${post.id}`, { preserveScroll: true });
    }
};
</script>

<template>
    <Head title="User feed" />

    <AdminLayout title="User feed">
        <div class="mb-4 flex flex-wrap items-center gap-3">
            <input
                v-model="search"
                type="search"
                placeholder="Search post text…"
                class="w-64 rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            />
            <select
                v-model="kind"
                class="rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            >
                <option value="">All kinds</option>
                <option v-for="k in kinds" :key="k" :value="k">{{ k }}</option>
            </select>
            <select
                v-model="status"
                class="rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            >
                <option value="">Any status</option>
                <option value="pending">Hidden only</option>
            </select>

            <Link
                href="/admin/posts/create"
                class="ml-auto rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4]"
            >
                New post
            </Link>
        </div>

        <div class="space-y-3">
            <article
                v-for="post in posts.data"
                :key="post.id"
                class="rounded-xl border border-white/5 bg-[#171F33] p-4"
            >
                <div class="flex flex-wrap items-start gap-3">
                    <span
                        class="grid h-9 w-9 shrink-0 place-items-center rounded-full text-xs font-semibold"
                        :style="{
                            backgroundColor: `${post.author?.accent_color}38`,
                            color: post.author?.accent_color,
                        }"
                    >
                        {{ post.author?.name.split(' ').map((p) => p[0]).slice(0, 2).join('') }}
                    </span>

                    <div class="min-w-0 flex-1">
                        <div class="flex flex-wrap items-center gap-2 text-sm">
                            <span class="font-medium">{{ post.author?.name }}</span>
                            <span class="text-xs text-[#8B84A3]">@{{ post.author?.username }}</span>
                            <span class="rounded-full bg-[#7C3AED]/25 px-2 py-0.5 text-xs text-[#D2BBFF]">
                                {{ post.kind }}
                            </span>
                            <span v-if="post.game" class="text-xs text-[#8B84A3]">
                                · {{ post.game.title }}
                            </span>
                            <span
                                class="text-xs"
                                :class="post.is_published ? 'text-emerald-300' : 'text-amber-300'"
                            >
                                · {{ post.is_published ? 'Published' : 'Hidden' }}
                            </span>
                        </div>

                        <p v-if="post.title" class="mt-2 text-sm font-medium text-[#DAE2FD]">
                            {{ post.title }}
                        </p>
                        <p class="mt-1 line-clamp-3 text-sm text-[#CCC3D8]">{{ post.body }}</p>

                        <div class="mt-3 flex flex-wrap items-center gap-4 text-xs text-[#8B84A3]">
                            <span>{{ post.likes_count }} likes</span>
                            <span>{{ post.comments_count }} comments</span>
                            <Link
                                :href="`/admin/posts/${post.id}/edit`"
                                class="text-[#D2BBFF] hover:underline"
                            >
                                Edit
                            </Link>
                            <button class="text-[#D2BBFF] hover:underline" @click="toggle(post)">
                                {{ post.is_published ? 'Hide' : 'Publish' }}
                            </button>
                            <button class="text-[#FFB2BA] hover:underline" @click="destroy(post)">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            </article>

            <p v-if="!posts.data.length" class="rounded-xl border border-white/5 bg-[#171F33] px-4 py-8 text-center text-[#8B84A3]">
                No posts match this filter.
            </p>
        </div>

        <Pagination :links="posts.links" />
    </AdminLayout>
</template>
