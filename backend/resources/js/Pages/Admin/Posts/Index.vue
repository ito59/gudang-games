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
                class="w-64 gg-input"
            />
            <select
                v-model="kind"
                class="gg-input"
            >
                <option value="">All kinds</option>
                <option v-for="k in kinds" :key="k" :value="k">{{ k }}</option>
            </select>
            <select
                v-model="status"
                class="gg-input"
            >
                <option value="">Any status</option>
                <option value="pending">Hidden only</option>
            </select>

            <Link
                href="/admin/posts/create"
                class="btn-gold ml-auto"
            >
                New post
            </Link>
        </div>

        <div class="space-y-3">
            <article
                v-for="post in posts.data"
                :key="post.id"
                class="gg-card p-4"
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
                            <span class="text-xs text-ink-muted">@{{ post.author?.username }}</span>
                            <span class="chip-gold">
                                {{ post.kind }}
                            </span>
                            <span v-if="post.game" class="text-xs text-ink-muted">
                                · {{ post.game.title }}
                            </span>
                            <span
                                class="text-xs"
                                :class="post.is_published ? 'text-online-ink' : 'text-brand'"
                            >
                                · {{ post.is_published ? 'Published' : 'Hidden' }}
                            </span>
                        </div>

                        <p v-if="post.title" class="mt-2 text-sm font-medium text-ink">
                            {{ post.title }}
                        </p>
                        <p class="mt-1 line-clamp-3 text-sm text-ink-soft">{{ post.body }}</p>

                        <div class="mt-3 flex flex-wrap items-center gap-4 text-xs text-ink-muted">
                            <span>{{ post.likes_count }} likes</span>
                            <span>{{ post.comments_count }} comments</span>
                            <Link
                                :href="`/admin/posts/${post.id}/edit`"
                                class="gg-link"
                            >
                                Edit
                            </Link>
                            <button class="gg-link" @click="toggle(post)">
                                {{ post.is_published ? 'Hide' : 'Publish' }}
                            </button>
                            <button class="gg-link-danger" @click="destroy(post)">
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            </article>

            <p v-if="!posts.data.length" class="gg-card px-4 py-8 text-center text-ink-muted">
                No posts match this filter.
            </p>
        </div>

        <Pagination :links="posts.links" />
    </AdminLayout>
</template>
