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
    { label: 'Featured events', route: 'admin.events.index', match: 'admin.events' },
    { label: 'User feed', route: 'admin.posts.index', match: 'admin.posts' },
    { label: 'Users', route: 'admin.users.index', match: 'admin.users' },
    { label: 'Reports', route: 'admin.reports.index', match: 'admin.reports' },
];

// `route()` is not available without Ziggy, so URLs are plain paths.
const paths = {
    'admin.dashboard': '/admin',
    'admin.games.index': '/admin/games',
    'admin.categories.index': '/admin/categories',
    'admin.events.index': '/admin/events',
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
    <div class="min-h-screen bg-[#0B1326] text-[#DAE2FD]">
        <div class="flex">
            <aside
                class="hidden w-60 shrink-0 border-r border-white/5 bg-[#131B2E] p-4 md:block"
            >
                <div class="mb-8 flex items-center gap-2 px-2">
                    <span class="text-lg font-bold text-[#D2BBFF]">BandarGames</span>
                </div>

                <nav class="space-y-1">
                    <Link
                        v-for="item in nav"
                        :key="item.route"
                        :href="paths[item.route]"
                        class="block rounded-lg px-3 py-2 text-sm transition"
                        :class="
                            isActive(item.match)
                                ? 'bg-[#7C3AED]/25 text-[#D2BBFF]'
                                : 'text-[#CCC3D8] hover:bg-white/5'
                        "
                    >
                        {{ item.label }}
                    </Link>
                </nav>
            </aside>

            <div class="min-w-0 flex-1">
                <header
                    class="flex items-center justify-between border-b border-white/5 bg-[#171F33] px-6 py-4"
                >
                    <div>
                        <h1 class="text-xl font-semibold text-[#D2BBFF]">
                            {{ title }}
                        </h1>
                    </div>

                    <div class="flex items-center gap-3">
                        <span class="hidden text-sm text-[#CCC3D8] sm:inline">
                            {{ user?.name }}
                        </span>
                        <button
                            class="rounded-lg border border-white/10 px-3 py-1.5 text-sm text-[#CCC3D8] hover:bg-white/5"
                            @click="logout"
                        >
                            Sign out
                        </button>
                    </div>
                </header>

                <!-- Mobile nav -->
                <div class="border-b border-white/5 bg-[#131B2E] px-4 py-2 md:hidden">
                    <button
                        class="text-sm text-[#CCC3D8]"
                        @click="open = !open"
                    >
                        Menu
                    </button>
                    <nav v-show="open" class="mt-2 space-y-1 pb-2">
                        <Link
                            v-for="item in nav"
                            :key="item.route"
                            :href="paths[item.route]"
                            class="block rounded px-3 py-2 text-sm"
                            :class="
                                isActive(item.match)
                                    ? 'bg-[#7C3AED]/25 text-[#D2BBFF]'
                                    : 'text-[#CCC3D8]'
                            "
                        >
                            {{ item.label }}
                        </Link>
                    </nav>
                </div>

                <main class="p-6">
                    <div
                        v-if="flash"
                        class="mb-4 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-200"
                    >
                        {{ flash }}
                    </div>

                    <slot />
                </main>
            </div>
        </div>
    </div>
</template>
