<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';

const props = defineProps({
    games: { type: Object, required: true },
    categories: { type: Array, required: true },
    filters: { type: Object, default: () => ({}) },
});

const search = ref(props.filters.search ?? '');
const category = ref(props.filters.category ?? '');
const featured = ref(props.filters.featured ?? '');

let timer;
watch([search, category, featured], () => {
    clearTimeout(timer);
    // Debounced so typing does not fire a request per keystroke.
    timer = setTimeout(() => {
        router.get(
            '/admin/games',
            {
                search: search.value || undefined,
                category: category.value || undefined,
                featured: featured.value || undefined,
            },
            { preserveState: true, replace: true },
        );
    }, 300);
});

const destroy = (game) => {
    if (confirm(`Delete "${game.title}"? This cannot be undone.`)) {
        router.delete(`/admin/games/${game.id}`, { preserveScroll: true });
    }
};
</script>

<template>
    <Head title="Games" />

    <AdminLayout title="Games">
        <div class="mb-4 flex flex-wrap items-center gap-3">
            <input
                v-model="search"
                type="search"
                placeholder="Search games…"
                class="w-56 rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            />
            <select
                v-model="category"
                class="rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            >
                <option value="">All categories</option>
                <option v-for="c in categories" :key="c.id" :value="c.id">
                    {{ c.name }}
                </option>
            </select>

            <select
                v-model="featured"
                class="rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            >
                <option value="">All games</option>
                <option value="yes">Featured only</option>
            </select>

            <Link
                href="/admin/games/create"
                class="ml-auto rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4]"
            >
                New game
            </Link>
        </div>

        <div class="overflow-x-auto rounded-xl border border-white/5 bg-[#171F33]">
            <table class="w-full text-left text-sm">
                <thead class="bg-white/5 text-xs uppercase text-[#8B84A3]">
                    <tr>
                        <th class="px-4 py-3">Cover</th>
                        <th class="px-4 py-3">Title</th>
                        <th class="px-4 py-3">Category</th>
                        <th class="px-4 py-3">Type</th>
                        <th class="px-4 py-3">Rating</th>
                        <th class="px-4 py-3">Status</th>
                        <th class="px-4 py-3">Featured</th>
                        <th class="px-4 py-3 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="game in games.data" :key="game.id" class="border-t border-white/5">
                        <td class="px-4 py-3">
                            <div class="grid h-10 w-16 place-items-center overflow-hidden rounded border border-white/10 bg-[#0B1326]">
                                <img
                                    v-if="game.cover_url"
                                    :src="game.cover_url"
                                    :alt="game.title"
                                    class="h-full w-full object-cover"
                                />
                                <span v-else class="text-[10px] text-[#8B84A3]">none</span>
                            </div>
                        </td>
                        <td class="px-4 py-3 font-medium">{{ game.title }}</td>
                        <td class="px-4 py-3 text-[#CCC3D8]">
                            {{ game.category?.name ?? '—' }}
                        </td>
                        <td class="px-4 py-3">
                            <span
                                class="rounded-full px-2 py-0.5 text-xs"
                                :class="
                                    game.source_type === 'zip'
                                        ? 'bg-[#7C3AED]/25 text-[#D2BBFF]'
                                        : 'bg-white/10 text-[#CCC3D8]'
                                "
                            >
                                {{ game.source_type === 'zip' ? 'Hosted ZIP' : 'URL' }}
                            </span>
                            <a
                                v-if="game.play_url"
                                :href="game.play_url"
                                target="_blank"
                                rel="noopener"
                                class="ml-2 text-xs text-[#D2BBFF] hover:underline"
                            >
                                open ↗
                            </a>
                        </td>
                        <td class="px-4 py-3">{{ Number(game.rating).toFixed(1) }}</td>
                        <td class="px-4 py-3">
                            <span :class="game.is_published ? 'text-emerald-300' : 'text-amber-300'">
                                {{ game.is_published ? 'Published' : 'Draft' }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            <span
                                v-if="game.is_featured"
                                class="rounded-full bg-[#7C3AED]/25 px-2 py-0.5 text-xs text-[#D2BBFF]"
                            >
                                In slider
                            </span>
                            <span v-else class="text-xs text-[#8B84A3]">—</span>
                        </td>
                        <td class="px-4 py-3 text-right whitespace-nowrap">
                            <Link
                                :href="`/admin/games/${game.id}/edit`"
                                class="text-[#D2BBFF] hover:underline"
                            >
                                Edit
                            </Link>
                            <Link
                                :href="`/admin/games/${game.id}/trailer`"
                                class="ml-3 text-[#D2BBFF] hover:underline"
                            >
                                {{ game.trailer_url ? 'Trailer ✓' : 'Trailer' }}
                            </Link>
                            <button
                                class="ml-3 text-[#FFB2BA] hover:underline"
                                @click="destroy(game)"
                            >
                                Delete
                            </button>
                        </td>
                    </tr>
                    <tr v-if="!games.data.length">
                        <td colspan="8" class="px-4 py-8 text-center text-[#8B84A3]">
                            No games match this filter.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <Pagination :links="games.links" />
    </AdminLayout>
</template>
