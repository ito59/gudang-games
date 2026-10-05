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
                class="rounded px-3 py-1.5 text-sm text-[#8B84A3]"
                v-html="link.label"
            />
            <Link
                v-else
                :href="link.url"
                class="rounded px-3 py-1.5 text-sm transition"
                :class="
                    link.active
                        ? 'bg-[#7C3AED] text-white'
                        : 'text-[#CCC3D8] hover:bg-white/5'
                "
                v-html="link.label"
            />
        </template>
    </nav>
</template>
