<script setup>
import { ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

defineProps({
    categories: { type: Array, required: true },
});

const editingId = ref(null);

const form = useForm({ name: '', slug: '', icon: 'sports_esports', sort_order: 0 });

const startEdit = (category) => {
    editingId.value = category.id;
    form.defaults();
    form.name = category.name;
    form.slug = category.slug;
    form.icon = category.icon;
    form.sort_order = category.sort_order;
};

const cancel = () => {
    editingId.value = null;
    form.reset();
    form.clearErrors();
};

const submit = () => {
    if (editingId.value) {
        form.put(`/admin/categories/${editingId.value}`, { onSuccess: cancel });
    } else {
        form.post('/admin/categories', { onSuccess: () => form.reset() });
    }
};

const destroy = (category) => {
    if (confirm(`Delete "${category.name}"? Its games stay but become uncategorised.`)) {
        router.delete(`/admin/categories/${category.id}`, { preserveScroll: true });
    }
};

const field =
    'mt-1 w-full rounded-lg border-white/10 bg-[#0B1326] text-sm text-[#DAE2FD] focus:border-[#7C3AED] focus:ring-[#7C3AED]';
</script>

<template>
    <Head title="Categories" />

    <AdminLayout title="Categories">
        <div class="grid gap-6 lg:grid-cols-3">
            <div class="lg:col-span-2">
                <div class="overflow-x-auto rounded-xl border border-white/5 bg-[#171F33]">
                    <table class="w-full text-left text-sm">
                        <thead class="bg-white/5 text-xs uppercase text-[#8B84A3]">
                            <tr>
                                <th class="px-4 py-3">Name</th>
                                <th class="px-4 py-3">Icon</th>
                                <th class="px-4 py-3">Games</th>
                                <th class="px-4 py-3">Order</th>
                                <th class="px-4 py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="c in categories" :key="c.id" class="border-t border-white/5">
                                <td class="px-4 py-3 font-medium">{{ c.name }}</td>
                                <td class="px-4 py-3 font-mono text-xs text-[#CCC3D8]">
                                    {{ c.icon }}
                                </td>
                                <td class="px-4 py-3">{{ c.games_count }}</td>
                                <td class="px-4 py-3">{{ c.sort_order }}</td>
                                <td class="px-4 py-3 text-right whitespace-nowrap">
                                    <button class="text-[#D2BBFF] hover:underline" @click="startEdit(c)">
                                        Edit
                                    </button>
                                    <button class="ml-3 text-[#FFB2BA] hover:underline" @click="destroy(c)">
                                        Delete
                                    </button>
                                </td>
                            </tr>
                            <tr v-if="!categories.length">
                                <td colspan="5" class="px-4 py-8 text-center text-[#8B84A3]">
                                    No categories yet.
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <form
                class="space-y-4 rounded-xl border border-white/5 bg-[#171F33] p-5"
                @submit.prevent="submit"
            >
                <h2 class="font-semibold text-[#D2BBFF]">
                    {{ editingId ? 'Edit category' : 'New category' }}
                </h2>

                <div>
                    <label class="text-sm text-[#CCC3D8]">Name</label>
                    <input v-model="form.name" type="text" :class="field" />
                    <p v-if="form.errors.name" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.name }}
                    </p>
                </div>

                <div>
                    <label class="text-sm text-[#CCC3D8]">
                        Icon
                        <span class="text-[#8B84A3]">— Material Symbols name</span>
                    </label>
                    <input v-model="form.icon" type="text" :class="field" />
                    <p v-if="form.errors.icon" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.icon }}
                    </p>
                </div>

                <div>
                    <label class="text-sm text-[#CCC3D8]">Sort order</label>
                    <input v-model="form.sort_order" type="number" min="0" :class="field" />
                </div>

                <div class="flex items-center gap-3">
                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4] disabled:opacity-50"
                    >
                        {{ editingId ? 'Save' : 'Add' }}
                    </button>
                    <button
                        v-if="editingId"
                        type="button"
                        class="text-sm text-[#CCC3D8] hover:underline"
                        @click="cancel"
                    >
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>
