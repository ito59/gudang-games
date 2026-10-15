<script setup>
import { Head, Link } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

defineProps({
    stats: { type: Object, required: true },
    latestPosts: { type: Array, required: true },
});

const cards = [
    { key: 'games', label: 'Games', sub: 'published_games', subLabel: 'published', href: '/admin/games' },
    { key: 'categories', label: 'Categories', href: '/admin/categories' },
    { key: 'featured', label: 'Featured games', href: '/admin/games?featured=yes' },
    { key: 'users', label: 'Users', sub: 'online', subLabel: 'online now', href: '/admin/users' },
    { key: 'posts', label: 'Feed posts', sub: 'pending_posts', subLabel: 'hidden', href: '/admin/posts' },
];
</script>

<template>
    <Head title="Dashboard" />

    <AdminLayout title="Dashboard">
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <Link
                v-for="card in cards"
                :key="card.key"
                :href="card.href"
                class="gg-card p-5 transition hover:-translate-y-0.5 hover:border-gold hover:shadow-lift"
            >
                <p class="gg-label">{{ card.label }}</p>
                <p class="mt-2 font-display text-3xl font-bold text-gold-link">
                    {{ stats[card.key] }}
                </p>
                <p v-if="card.sub" class="mt-1 text-xs text-ink-muted">
                    {{ stats[card.sub] }} {{ card.subLabel }}
                </p>
            </Link>
        </div>

        <section class="mt-8">
            <h2 class="mb-3 font-display text-lg font-semibold text-ink">Latest feed posts</h2>

            <div class="overflow-hidden gg-card">
                <table class="w-full text-left text-sm">
                    <thead class="gg-thead">
                        <tr>
                            <th class="px-4 py-3">Author</th>
                            <th class="px-4 py-3">Post</th>
                            <th class="px-4 py-3">Kind</th>
                            <th class="px-4 py-3">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr
                            v-for="post in latestPosts"
                            :key="post.id"
                            class="gg-row"
                        >
                            <td class="px-4 py-3 whitespace-nowrap">{{ post.author }}</td>
                            <td class="px-4 py-3 text-ink-soft">{{ post.body }}</td>
                            <td class="px-4 py-3">
                                <span class="chip-gold">
                                    {{ post.kind }}
                                </span>
                            </td>
                            <td class="px-4 py-3">
                                <span :class="post.is_published ? 'chip-green' : 'chip-red'">
                                    {{ post.is_published ? 'Published' : 'Hidden' }}
                                </span>
                            </td>
                        </tr>
                        <tr v-if="!latestPosts.length">
                            <td colspan="4" class="px-4 py-6 text-center text-ink-muted">
                                No posts yet.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </AdminLayout>
</template>
