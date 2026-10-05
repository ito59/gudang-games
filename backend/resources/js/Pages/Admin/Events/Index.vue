<script setup>
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

defineProps({
    events: { type: Array, required: true },
});

const destroy = (event) => {
    if (confirm(`Delete "${event.title}"?`)) {
        router.delete(`/admin/events/${event.id}`, { preserveScroll: true });
    }
};
</script>

<template>
    <Head title="Featured events" />

    <AdminLayout title="Featured events">
        <div class="mb-4 flex items-center">
            <p class="text-sm text-[#8B84A3]">
                Slides of the app's home carousel, in sort order.
            </p>
            <Link
                href="/admin/events/create"
                class="ml-auto rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4]"
            >
                New event
            </Link>
        </div>

        <div class="space-y-3">
            <article
                v-for="event in events"
                :key="event.id"
                class="rounded-xl border border-white/5 bg-[#171F33] p-4"
            >
                <div class="flex flex-wrap items-center gap-2 text-xs">
                    <span
                        v-if="event.is_live"
                        class="rounded-full bg-[#CD0047]/30 px-2 py-0.5 text-[#FFB2BA]"
                    >
                        LIVE
                    </span>
                    <span class="rounded-full bg-white/10 px-2 py-0.5 text-[#CCC3D8]">
                        {{ event.season }}
                    </span>
                    <span v-if="event.game" class="text-[#8B84A3]">· {{ event.game.title }}</span>
                    <span :class="event.is_published ? 'text-emerald-300' : 'text-amber-300'">
                        · {{ event.is_published ? 'Published' : 'Draft' }}
                    </span>
                    <span class="text-[#8B84A3]">· order {{ event.sort_order }}</span>
                </div>

                <h3 class="mt-2 text-lg font-semibold">{{ event.title }}</h3>
                <p class="mt-1 text-sm text-[#CCC3D8]">{{ event.description }}</p>

                <div class="mt-3 flex gap-4 text-xs">
                    <Link
                        :href="`/admin/events/${event.id}/edit`"
                        class="text-[#D2BBFF] hover:underline"
                    >
                        Edit
                    </Link>
                    <button class="text-[#FFB2BA] hover:underline" @click="destroy(event)">
                        Delete
                    </button>
                </div>
            </article>

            <p
                v-if="!events.length"
                class="rounded-xl border border-white/5 bg-[#171F33] px-4 py-8 text-center text-[#8B84A3]"
            >
                No featured events yet.
            </p>
        </div>
    </AdminLayout>
</template>
