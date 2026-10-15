<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';

const props = defineProps({
    users: { type: Object, required: true },
    filters: { type: Object, default: () => ({}) },
});

const search = ref(props.filters.search ?? '');
const status = ref(props.filters.status ?? '');

let timer;
watch([search, status], () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
        router.get(
            '/admin/users',
            { search: search.value || undefined, status: status.value || undefined },
            { preserveState: true, replace: true },
        );
    }, 300);
});

const destroy = (user) => {
    if (confirm(`Delete ${user.name}? Their posts go with them.`)) {
        router.delete(`/admin/users/${user.id}`, { preserveScroll: true });
    }
};
</script>

<template>
    <Head title="Users" />

    <AdminLayout title="Users">
        <div class="mb-4 flex flex-wrap items-center gap-3">
            <input
                v-model="search"
                type="search"
                placeholder="Name, handle or email…"
                class="w-64 gg-input"
            />
            <select
                v-model="status"
                class="gg-input"
            >
                <option value="">All members</option>
                <option value="online">Online now</option>
                <option value="suspended">Suspended</option>
            </select>

            <Link
                href="/admin/users/create"
                class="btn-gold ml-auto"
            >
                New account
            </Link>
        </div>

        <div class="overflow-x-auto gg-card">
            <table class="w-full text-left text-sm">
                <thead class="gg-thead">
                    <tr>
                        <th class="px-4 py-3">Member</th>
                        <th class="px-4 py-3">Email</th>
                        <th class="px-4 py-3">Status</th>
                        <th class="px-4 py-3">Posts</th>
                        <th class="px-4 py-3">Role</th>
                        <th class="px-4 py-3 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="user in users.data" :key="user.id" class="gg-row">
                        <td class="px-4 py-3">
                            <div class="flex items-center gap-3">
                                <span
                                    class="grid h-8 w-8 place-items-center rounded-full text-xs font-semibold"
                                    :style="{
                                        backgroundColor: `${user.accent_color}38`,
                                        color: user.accent_color,
                                    }"
                                >
                                    {{ user.name.split(' ').map((p) => p[0]).slice(0, 2).join('') }}
                                </span>
                                <div>
                                    <div class="font-medium">{{ user.name }}</div>
                                    <div class="text-xs text-ink-muted">@{{ user.username }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-4 py-3 text-ink-soft">{{ user.email }}</td>
                        <td class="px-4 py-3">
                            <span v-if="user.is_online" class="chip-green">
                                {{ user.playing ? user.playing : 'Online' }}
                            </span>
                            <span v-else class="text-ink-muted">Offline</span>
                        </td>
                        <td class="px-4 py-3">{{ user.posts_count }}</td>
                        <td class="px-4 py-3">
                            <span v-if="user.is_admin" class="chip-gold">
                                Admin
                            </span>
                            <span v-else-if="!user.is_active" class="chip-red">Suspended</span>
                            <span v-else class="text-ink-soft">Member</span>
                        </td>
                        <td class="px-4 py-3 text-right whitespace-nowrap">
                            <Link
                                :href="`/admin/users/${user.id}/edit`"
                                class="gg-link"
                            >
                                Edit
                            </Link>
                            <button
                                class="ml-3 gg-link-danger"
                                @click="destroy(user)"
                            >
                                Delete
                            </button>
                        </td>
                    </tr>
                    <tr v-if="!users.data.length">
                        <td colspan="6" class="px-4 py-8 text-center text-ink-muted">
                            No members match this filter.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <Pagination :links="users.links" />
    </AdminLayout>
</template>
