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
                class="w-64 rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            />
            <select
                v-model="status"
                class="rounded-lg border-white/10 bg-[#171F33] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]"
            >
                <option value="">All members</option>
                <option value="online">Online now</option>
                <option value="suspended">Suspended</option>
            </select>

            <Link
                href="/admin/users/create"
                class="ml-auto rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4]"
            >
                New account
            </Link>
        </div>

        <div class="overflow-x-auto rounded-xl border border-white/5 bg-[#171F33]">
            <table class="w-full text-left text-sm">
                <thead class="bg-white/5 text-xs uppercase text-[#8B84A3]">
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
                    <tr v-for="user in users.data" :key="user.id" class="border-t border-white/5">
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
                                    <div class="text-xs text-[#8B84A3]">@{{ user.username }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-4 py-3 text-[#CCC3D8]">{{ user.email }}</td>
                        <td class="px-4 py-3">
                            <span v-if="user.is_online" class="text-emerald-300">
                                {{ user.playing ? user.playing : 'Online' }}
                            </span>
                            <span v-else class="text-[#8B84A3]">Offline</span>
                        </td>
                        <td class="px-4 py-3">{{ user.posts_count }}</td>
                        <td class="px-4 py-3">
                            <span v-if="user.is_admin" class="rounded-full bg-[#7C3AED]/25 px-2 py-0.5 text-xs text-[#D2BBFF]">
                                Admin
                            </span>
                            <span v-else-if="!user.is_active" class="text-amber-300">Suspended</span>
                            <span v-else class="text-[#CCC3D8]">Member</span>
                        </td>
                        <td class="px-4 py-3 text-right whitespace-nowrap">
                            <Link
                                :href="`/admin/users/${user.id}/edit`"
                                class="text-[#D2BBFF] hover:underline"
                            >
                                Edit
                            </Link>
                            <button
                                class="ml-3 text-[#FFB2BA] hover:underline"
                                @click="destroy(user)"
                            >
                                Delete
                            </button>
                        </td>
                    </tr>
                    <tr v-if="!users.data.length">
                        <td colspan="6" class="px-4 py-8 text-center text-[#8B84A3]">
                            No members match this filter.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <Pagination :links="users.links" />
    </AdminLayout>
</template>
