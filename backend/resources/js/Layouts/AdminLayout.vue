<script setup>
import { computed, ref } from 'vue';
import { Link, router, usePage } from '@inertiajs/vue3';

defineProps({
    title: { type: String, default: '' },
});

const page = usePage();
const flash = computed(() => page.props.flash?.success);
const user = computed(() => page.props.auth?.user);
const open = ref(false);

const nav = [
    { label: 'Dashboard', route: 'admin.dashboard', match: 'admin.dashboard' },
    { label: 'Games', route: 'admin.games.index', match: 'admin.games' },
    { label: 'Categories', route: 'admin.categories.index', match: 'admin.categories' },
    { label: 'User feed', route: 'admin.posts.index', match: 'admin.posts' },
    { label: 'Users', route: 'admin.users.index', match: 'admin.users' },
    { label: 'Reports', route: 'admin.reports.index', match: 'admin.reports' },
];

// `route()` is not available without Ziggy, so URLs are plain paths.
const paths = {
    'admin.dashboard': '/admin',
    'admin.games.index': '/admin/games',
    'admin.categories.index': '/admin/categories',
    'admin.posts.index': '/admin/posts',
    'admin.users.index': '/admin/users',
    'admin.reports.index': '/admin/reports',
};

const isActive = (match) => {
    const url = page.url;
    if (match === 'admin.dashboard') return url === '/admin';
    return url.startsWith(paths[`${match}.index`] ?? '');
};

const logout = () => router.post('/logout');
</script>

<template>
    <div class="min-h-screen bg-cream font-sans text-ink">
        <div class="flex">
            <aside
                class="hidden min-h-screen w-60 shrink-0 border-r border-line-soft bg-white md:block"
            >
                <div class="gg-gold-band flex h-[72px] items-center px-4">
                    <span class="gg-wordmark">
                        Gudang<span class="text-brand">Games</span>
                    </span>
                </div>

                <nav class="space-y-1 p-4">
                    <Link
                        v-for="item in nav"
                        :key="item.route"
                        :href="paths[item.route]"
                        class="block rounded-full px-4 py-2 text-sm transition"
                        :class="
                            isActive(item.match)
                                ? 'bg-brand/10 font-semibold text-brand'
                                : 'font-medium text-ink-soft hover:bg-fill hover:text-ink'
                        "
                    >
                        {{ item.label }}
                    </Link>
                </nav>
            </aside>

            <div class="min-w-0 flex-1">
                <header
                    class="gg-gold-band flex min-h-[72px] items-center justify-between gap-4 px-6 py-3 shadow-card"
                >
                    <div class="flex min-w-0 items-center gap-3">
                        <span class="gg-wordmark md:hidden">
                            Gudang<span class="text-brand">Games</span>
                        </span>
                        <h1 class="truncate font-display text-xl font-semibold text-gold-on">
                            {{ title }}
                        </h1>
                    </div>

                    <div class="flex shrink-0 items-center gap-3">
                        <span
                            class="hidden rounded-full bg-white/70 px-3 py-1 text-sm font-medium text-gold-on sm:inline"
                        >
                            {{ user?.name }}
                        </span>
                        <button
                            class="btn btn-sm border border-gold-deep/40 bg-white text-gold-on hover:bg-cream"
                            @click="logout"
                        >
                            Sign out
                        </button>
                    </div>
                </header>

                <!-- Mobile nav -->
                <div class="border-b border-line-soft bg-white px-4 py-2 md:hidden">
                    <button
                        class="text-sm font-semibold text-ink-soft"
                        @click="open = !open"
                    >
                        Menu
                    </button>
                    <nav v-show="open" class="mt-2 space-y-1 pb-2">
                        <Link
                            v-for="item in nav"
                            :key="item.route"
                            :href="paths[item.route]"
                            class="block rounded-full px-4 py-2 text-sm"
                            :class="
                                isActive(item.match)
                                    ? 'bg-brand/10 font-semibold text-brand'
                                    : 'font-medium text-ink-soft'
                            "
                        >
                            {{ item.label }}
                        </Link>
                    </nav>
                </div>

                <main class="p-6">
                    <div
                        v-if="flash"
                        class="mb-4 rounded-card border border-online/30 bg-online/10 px-4 py-3 text-sm font-medium text-online-ink"
                    >
                        {{ flash }}
                    </div>

                    <slot />
                </main>
            </div>
        </div>
    </div>
</template>
