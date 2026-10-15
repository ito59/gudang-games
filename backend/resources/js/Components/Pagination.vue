<script setup>
import { Link } from '@inertiajs/vue3';

defineProps({
    links: { type: Array, required: true },
});
</script>

<template>
    <nav v-if="links.length > 3" class="mt-4 flex flex-wrap gap-1">
        <template v-for="link in links" :key="link.label">
            <span
                v-if="!link.url"
                class="rounded-full px-3 py-1.5 text-sm text-ink-muted"
                v-html="link.label"
            />
            <Link
                v-else
                :href="link.url"
                class="rounded-full px-3 py-1.5 text-sm transition"
                :class="
                    link.active
                        ? 'bg-brand font-semibold text-white'
                        : 'text-ink-soft hover:bg-white hover:text-ink'
                "
                v-html="link.label"
            />
        </template>
    </nav>
</template>
