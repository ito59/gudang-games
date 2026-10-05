<script setup>
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';

const props = defineProps({
    reports: { type: Object, required: true },
    flagged: { type: Object, required: true },
    filters: { type: Object, default: () => ({}) },
    counts: { type: Object, default: () => ({}) },
});

const status = ref(props.filters.status ?? 'pending');
const tab = ref('reports');

const filter = (value) => {
    status.value = value;
    router.get('/admin/reports', { status: value }, { preserveState: true, replace: true });
};

// Every action closes the report, so each one is confirmed: there is no
// "unresolve", and suspending the wrong member is a bad afternoon.
const act = (report, resolution, question) => {
    if (question && !confirm(question)) return;

    router.patch(`/admin/reports/${report.id}`, { resolution }, { preserveScroll: true });
};

const targetLabel = {
    message: 'Chat message',
    post: 'Post',
    comment: 'Comment',
    user: 'Member',
};
</script>

<template>
    <Head title="Reports" />

    <AdminLayout title="Reports">
        <div class="mb-4 flex flex-wrap items-center gap-2">
            <button
                v-for="item in [
                    { key: 'reports', label: `Reports (${counts.pending ?? 0} pending)` },
                    { key: 'flagged', label: `Filtered automatically (${counts.flagged ?? 0})` },
                ]"
                :key="item.key"
                class="rounded-lg px-3 py-1.5 text-sm transition"
                :class="
                    tab === item.key
                        ? 'bg-[#7C3AED]/25 text-[#D2BBFF]'
                        : 'text-[#CCC3D8] hover:bg-white/5'
                "
                @click="tab = item.key"
            >
                {{ item.label }}
            </button>

            <div v-if="tab === 'reports'" class="ml-auto flex items-center gap-2">
                <button
                    v-for="option in ['pending', 'resolved', 'dismissed', 'all']"
                    :key="option"
                    class="rounded-lg border px-3 py-1.5 text-xs capitalize transition"
                    :class="
                        status === option
                            ? 'border-[#7C3AED] text-[#D2BBFF]'
                            : 'border-white/10 text-[#8B84A3] hover:bg-white/5'
                    "
                    @click="filter(option)"
                >
                    {{ option }}
                </button>
            </div>
        </div>

        <!-- What members reported -->
        <div v-if="tab === 'reports'">
            <p
                v-if="!reports.data.length"
                class="rounded-xl border border-white/5 bg-[#171F33] px-4 py-10 text-center text-sm text-[#8B84A3]"
            >
                Nothing {{ status === 'all' ? 'reported' : status }} right now.
            </p>

            <div
                v-for="report in reports.data"
                :key="report.id"
                class="mb-3 rounded-xl border border-white/5 bg-[#171F33] p-4"
            >
                <div class="flex flex-wrap items-start gap-3">
                    <span
                        class="rounded-md bg-[#7C3AED]/20 px-2 py-1 text-xs font-medium text-[#D2BBFF]"
                    >
                        {{ targetLabel[report.target] ?? report.target }}
                    </span>
                    <span class="rounded-md bg-white/5 px-2 py-1 text-xs text-[#CCC3D8]">
                        {{ report.reason }}
                    </span>
                    <span
                        v-if="report.status !== 'pending'"
                        class="rounded-md bg-emerald-400/10 px-2 py-1 text-xs capitalize text-emerald-200"
                    >
                        {{ report.status }}<template v-if="report.resolved_by">
                            · {{ report.resolved_by }}</template>
                    </span>
                    <span class="ml-auto text-xs text-[#8B84A3]">{{ report.created_at }}</span>
                </div>

                <!-- The excerpt is a snapshot taken when the report was
                     filed, so it survives the content being deleted. -->
                <blockquote
                    v-if="report.excerpt"
                    class="mt-3 border-l-2 border-[#7C3AED]/40 pl-3 text-sm text-[#DAE2FD]"
                >
                    {{ report.excerpt }}
                    <span v-if="!report.content_exists" class="text-xs text-[#8B84A3]">
                        (deleted)
                    </span>
                </blockquote>

                <p v-if="report.note" class="mt-2 text-sm text-[#CCC3D8]">
                    <span class="text-xs uppercase text-[#8B84A3]">Note</span>
                    — {{ report.note }}
                </p>

                <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-[#8B84A3]">
                    <span>
                        Reported by
                        <span class="text-[#CCC3D8]">@{{ report.reporter?.username ?? 'gone' }}</span>
                    </span>
                    <span v-if="report.reported_user">
                        About
                        <Link
                            :href="`/admin/users/${report.reported_user.id}/edit`"
                            class="text-[#D2BBFF] hover:underline"
                        >
                            @{{ report.reported_user.username }}
                        </Link>
                        <template v-if="report.reported_user.pending_reports > 1">
                            · {{ report.reported_user.pending_reports }} open reports
                        </template>
                        <template v-if="!report.reported_user.is_active">
                            · suspended
                        </template>
                    </span>
                </div>

                <div v-if="report.status === 'pending'" class="mt-4 flex flex-wrap gap-2">
                    <button
                        class="rounded-lg border border-white/10 px-3 py-1.5 text-sm text-[#CCC3D8] hover:bg-white/5"
                        @click="act(report, 'dismiss')"
                    >
                        Dismiss
                    </button>
                    <button
                        v-if="report.target !== 'user' && report.content_exists"
                        class="rounded-lg bg-[#7C3AED] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#732EE4]"
                        @click="act(report, 'delete_content', 'Delete this content? It cannot be undone.')"
                    >
                        Delete content
                    </button>
                    <button
                        v-if="report.reported_user?.is_active"
                        class="rounded-lg border border-red-400/30 px-3 py-1.5 text-sm text-red-200 hover:bg-red-400/10"
                        @click="
                            act(
                                report,
                                'suspend_user',
                                `Suspend ${report.reported_user.name}? They lose access until reactivated.`,
                            )
                        "
                    >
                        Suspend member
                    </button>
                </div>
            </div>

            <Pagination :links="reports.links" />
        </div>

        <!-- What the filter refused before it was ever stored -->
        <div v-else class="overflow-x-auto rounded-xl border border-white/5 bg-[#171F33]">
            <table class="w-full text-left text-sm">
                <thead class="bg-white/5 text-xs uppercase text-[#8B84A3]">
                    <tr>
                        <th class="px-4 py-3">Member</th>
                        <th class="px-4 py-3">Where</th>
                        <th class="px-4 py-3">Why</th>
                        <th class="px-4 py-3">What they wrote</th>
                        <th class="px-4 py-3">When</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-if="!flagged.data.length">
                        <td colspan="5" class="px-4 py-10 text-center text-[#8B84A3]">
                            The filter has not refused anything yet.
                        </td>
                    </tr>
                    <tr
                        v-for="event in flagged.data"
                        :key="event.id"
                        class="border-t border-white/5"
                    >
                        <td class="px-4 py-3">
                            <Link
                                v-if="event.author"
                                :href="`/admin/users/${event.author.id}/edit`"
                                class="text-[#D2BBFF] hover:underline"
                            >
                                @{{ event.author.username }}
                            </Link>
                            <span v-else class="text-[#8B84A3]">gone</span>
                        </td>
                        <td class="px-4 py-3 capitalize text-[#CCC3D8]">{{ event.context }}</td>
                        <td class="px-4 py-3">
                            <span class="capitalize text-[#CCC3D8]">{{ event.reason }}</span>
                            <span v-if="event.rule" class="text-xs text-[#8B84A3]">
                                · {{ event.rule }}
                            </span>
                        </td>
                        <td class="max-w-md px-4 py-3 text-[#DAE2FD]">{{ event.body }}</td>
                        <td class="px-4 py-3 text-xs text-[#8B84A3]">{{ event.created_at }}</td>
                    </tr>
                </tbody>
            </table>

            <div class="p-4">
                <Pagination :links="flagged.links" />
            </div>
        </div>
    </AdminLayout>
</template>
