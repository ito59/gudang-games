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
    { key: 'events', label: 'Featured events', href: '/admin/events' },
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
                class="rounded-xl border border-white/5 bg-[#171F33] p-5 transition hover:border-[#7C3AED]/50"
            >
                <p class="text-sm text-[#CCC3D8]">{{ card.label }}</p>
                <p class="mt-2 text-3xl font-bold text-[#D2BBFF]">
                    {{ stats[card.key] }}
                </p>
                <p v-if="card.sub" class="mt-1 text-xs text-[#8B84A3]">
                    {{ stats[card.sub] }} {{ card.subLabel }}
                </p>
            </Link>
        </div>

        <section class="mt-8">
            <h2 class="mb-3 text-lg font-semibold text-[#D2BBFF]">Latest feed posts</h2>

            <div class="overflow-hidden rounded-xl border border-white/5 bg-[#171F33]">
                <table class="w-full text-left text-sm">
                    <thead class="bg-white/5 text-xs uppercase text-[#8B84A3]">
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
                            class="border-t border-white/5"
                        >
                            <td class="px-4 py-3 whitespace-nowrap">{{ post.author }}</td>
                            <td class="px-4 py-3 text-[#CCC3D8]">{{ post.body }}</td>
                            <td class="px-4 py-3">
                                <span class="rounded-full bg-[#7C3AED]/25 px-2 py-0.5 text-xs">
                                    {{ post.kind }}
                                </span>
                            </td>
                            <td class="px-4 py-3">
                                <span :class="post.is_published ? 'text-emerald-300' : 'text-amber-300'">
                                    {{ post.is_published ? 'Published' : 'Hidden' }}
                                </span>
                            </td>
                        </tr>
                        <tr v-if="!latestPosts.length">
                            <td colspan="4" class="px-4 py-6 text-center text-[#8B84A3]">
                                No posts yet.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </AdminLayout>
</template>
