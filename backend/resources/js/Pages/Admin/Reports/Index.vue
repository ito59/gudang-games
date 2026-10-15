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
                :class="tab === item.key ? 'gg-tab-active' : 'gg-tab'"
                @click="tab = item.key"
            >
                {{ item.label }}
            </button>

            <div v-if="tab === 'reports'" class="ml-auto flex items-center gap-2">
                <button
                    v-for="option in ['pending', 'resolved', 'dismissed', 'all']"
                    :key="option"
                    class="rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition"
                    :class="
                        status === option
                            ? 'border-brand/30 bg-brand/10 text-brand'
                            : 'border-line bg-white text-ink-soft hover:bg-fill'
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
                class="gg-card px-4 py-10 text-center text-sm text-ink-muted"
            >
                Nothing {{ status === 'all' ? 'reported' : status }} right now.
            </p>

            <div
                v-for="report in reports.data"
                :key="report.id"
                class="mb-3 gg-card p-4"
            >
                <div class="flex flex-wrap items-start gap-3">
                    <span
                        class="chip-gold"
                    >
                        {{ targetLabel[report.target] ?? report.target }}
                    </span>
                    <span class="chip-neutral">
                        {{ report.reason }}
                    </span>
                    <span
                        v-if="report.status !== 'pending'"
                        class="chip-green capitalize"
                    >
                        {{ report.status }}<template v-if="report.resolved_by">
                            · {{ report.resolved_by }}</template>
                    </span>
                    <span class="ml-auto text-xs text-ink-muted">{{ report.created_at }}</span>
                </div>

                <!-- The excerpt is a snapshot taken when the report was
                     filed, so it survives the content being deleted. -->
                <blockquote
                    v-if="report.excerpt"
                    class="mt-3 border-l-2 border-gold pl-3 text-sm text-ink"
                >
                    {{ report.excerpt }}
                    <span v-if="!report.content_exists" class="text-xs text-ink-muted">
                        (deleted)
                    </span>
                </blockquote>

                <p v-if="report.note" class="mt-2 text-sm text-ink-soft">
                    <span class="text-xs uppercase text-ink-muted">Note</span>
                    — {{ report.note }}
                </p>

                <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-ink-muted">
                    <span>
                        Reported by
                        <span class="text-ink-soft">@{{ report.reporter?.username ?? 'gone' }}</span>
                    </span>
                    <span v-if="report.reported_user">
                        About
                        <Link
                            :href="`/admin/users/${report.reported_user.id}/edit`"
                            class="gg-link"
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
                        class="btn-outline btn-sm"
                        @click="act(report, 'dismiss')"
                    >
                        Dismiss
                    </button>
                    <button
                        v-if="report.target !== 'user' && report.content_exists"
                        class="btn-red btn-sm"
                        @click="act(report, 'delete_content', 'Delete this content? It cannot be undone.')"
                    >
                        Delete content
                    </button>
                    <button
                        v-if="report.reported_user?.is_active"
                        class="btn-outline-red btn-sm"
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
        <div v-else class="overflow-x-auto gg-card">
            <table class="w-full text-left text-sm">
                <thead class="gg-thead">
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
                        <td colspan="5" class="px-4 py-10 text-center text-ink-muted">
                            The filter has not refused anything yet.
                        </td>
                    </tr>
                    <tr
                        v-for="event in flagged.data"
                        :key="event.id"
                        class="gg-row"
                    >
                        <td class="px-4 py-3">
                            <Link
                                v-if="event.author"
                                :href="`/admin/users/${event.author.id}/edit`"
                                class="gg-link"
                            >
                                @{{ event.author.username }}
                            </Link>
                            <span v-else class="text-ink-muted">gone</span>
                        </td>
                        <td class="px-4 py-3 capitalize text-ink-soft">{{ event.context }}</td>
                        <td class="px-4 py-3">
                            <span class="capitalize text-ink-soft">{{ event.reason }}</span>
                            <span v-if="event.rule" class="text-xs text-ink-muted">
                                · {{ event.rule }}
                            </span>
                        </td>
                        <td class="max-w-md px-4 py-3 text-ink">{{ event.body }}</td>
                        <td class="px-4 py-3 text-xs text-ink-muted">{{ event.created_at }}</td>
                    </tr>
                </tbody>
            </table>

            <div class="p-4">
                <Pagination :links="flagged.links" />
            </div>
        </div>
    </AdminLayout>
</template>
