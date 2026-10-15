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
                class="w-56 gg-input"
            />
            <select
                v-model="category"
                class="gg-input"
            >
                <option value="">All categories</option>
                <option v-for="c in categories" :key="c.id" :value="c.id">
                    {{ c.name }}
                </option>
            </select>

            <select
                v-model="featured"
                class="gg-input"
            >
                <option value="">All games</option>
                <option value="yes">Featured only</option>
            </select>

            <Link
                href="/admin/games/create"
                class="btn-gold ml-auto"
            >
                New game
            </Link>
        </div>

        <div class="overflow-x-auto gg-card">
            <table class="w-full text-left text-sm">
                <thead class="gg-thead">
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
                    <tr v-for="game in games.data" :key="game.id" class="gg-row">
                        <td class="px-4 py-3">
                            <div class="grid h-10 w-16 place-items-center overflow-hidden rounded-lg gg-well">
                                <img
                                    v-if="game.cover_url"
                                    :src="game.cover_url"
                                    :alt="game.title"
                                    class="h-full w-full object-cover"
                                />
                                <span v-else class="text-[10px] text-ink-muted">none</span>
                            </div>
                        </td>
                        <td class="px-4 py-3 font-medium">{{ game.title }}</td>
                        <td class="px-4 py-3 text-ink-soft">
                            {{ game.category?.name ?? '—' }}
                        </td>
                        <td class="px-4 py-3">
                            <span
                                class="chip"
                                :class="
                                    game.source_type === 'zip'
                                        ? 'bg-gold-light text-gold-on'
                                        : 'bg-fill text-ink-soft'
                                "
                            >
                                {{ game.source_type === 'zip' ? 'Hosted ZIP' : 'URL' }}
                            </span>
                            <a
                                v-if="game.play_url"
                                :href="game.play_url"
                                target="_blank"
                                rel="noopener"
                                class="ml-2 text-xs gg-link"
                            >
                                open ↗
                            </a>
                        </td>
                        <td class="px-4 py-3">{{ Number(game.rating).toFixed(1) }}</td>
                        <td class="px-4 py-3">
                            <span :class="game.is_published ? 'chip-green' : 'chip-neutral'">
                                {{ game.is_published ? 'Published' : 'Draft' }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            <span
                                v-if="game.is_featured"
                                class="chip-gold"
                            >
                                In slider
                            </span>
                            <span v-else class="text-xs text-ink-muted">—</span>
                        </td>
                        <td class="px-4 py-3 text-right whitespace-nowrap">
                            <Link
                                :href="`/admin/games/${game.id}/edit`"
                                class="gg-link"
                            >
                                Edit
                            </Link>
                            <Link
                                :href="`/admin/games/${game.id}/trailer`"
                                class="ml-3 gg-link"
                            >
                                {{ game.trailer_url ? 'Trailer ✓' : 'Trailer' }}
                            </Link>
                            <button
                                class="ml-3 gg-link-danger"
                                @click="destroy(game)"
                            >
                                Delete
                            </button>
                        </td>
                    </tr>
                    <tr v-if="!games.data.length">
                        <td colspan="8" class="px-4 py-8 text-center text-ink-muted">
                            No games match this filter.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <Pagination :links="games.links" />
    </AdminLayout>
</template>
