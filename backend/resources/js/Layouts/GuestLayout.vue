<script setup>
import ApplicationLogo from '@/Components/ApplicationLogo.vue';
import { Link } from '@inertiajs/vue3';
</script>

<template>
    <div
        class="flex min-h-screen flex-col items-center bg-cream pt-6 font-sans text-ink sm:justify-center sm:pt-0"
    >
        <div
            class="gg-gold-band flex w-full justify-center rounded-b-[28px] px-6 py-8 shadow-card sm:max-w-md sm:rounded-card"
        >
            <Link href="/">
                <ApplicationLogo class="text-2xl" />
            </Link>
        </div>

        <div
            class="mt-6 w-full overflow-hidden gg-card px-6 py-6 sm:max-w-md"
        >
            <slot />
        </div>
    </div>
</template>
