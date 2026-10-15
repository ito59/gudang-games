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
    'mt-1 w-full gg-input';
</script>

<template>
    <Head title="Categories" />

    <AdminLayout title="Categories">
        <div class="grid gap-6 lg:grid-cols-3">
            <div class="lg:col-span-2">
                <div class="overflow-x-auto gg-card">
                    <table class="w-full text-left text-sm">
                        <thead class="gg-thead">
                            <tr>
                                <th class="px-4 py-3">Name</th>
                                <th class="px-4 py-3">Icon</th>
                                <th class="px-4 py-3">Games</th>
                                <th class="px-4 py-3">Order</th>
                                <th class="px-4 py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="c in categories" :key="c.id" class="gg-row">
                                <td class="px-4 py-3 font-medium">{{ c.name }}</td>
                                <td class="px-4 py-3 text-xs text-ink-soft">
                                    {{ c.icon }}
                                </td>
                                <td class="px-4 py-3">{{ c.games_count }}</td>
                                <td class="px-4 py-3">{{ c.sort_order }}</td>
                                <td class="px-4 py-3 text-right whitespace-nowrap">
                                    <button class="gg-link" @click="startEdit(c)">
                                        Edit
                                    </button>
                                    <button class="ml-3 gg-link-danger" @click="destroy(c)">
                                        Delete
                                    </button>
                                </td>
                            </tr>
                            <tr v-if="!categories.length">
                                <td colspan="5" class="px-4 py-8 text-center text-ink-muted">
                                    No categories yet.
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <form
                class="space-y-4 gg-card p-5"
                @submit.prevent="submit"
            >
                <h2 class="font-display font-semibold text-ink">
                    {{ editingId ? 'Edit category' : 'New category' }}
                </h2>

                <div>
                    <label class="gg-label">Name</label>
                    <input v-model="form.name" type="text" :class="field" />
                    <p v-if="form.errors.name" class="mt-1 gg-error">
                        {{ form.errors.name }}
                    </p>
                </div>

                <div>
                    <label class="gg-label">
                        Icon
                        <span class="text-ink-muted">— Material Symbols name</span>
                    </label>
                    <input v-model="form.icon" type="text" :class="field" />
                    <p v-if="form.errors.icon" class="mt-1 gg-error">
                        {{ form.errors.icon }}
                    </p>
                </div>

                <div>
                    <label class="gg-label">Sort order</label>
                    <input v-model="form.sort_order" type="number" min="0" :class="field" />
                </div>

                <div class="flex items-center gap-3">
                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="btn-gold"
                    >
                        {{ editingId ? 'Save' : 'Add' }}
                    </button>
                    <button
                        v-if="editingId"
                        type="button"
                        class="text-sm text-ink-soft hover:text-ink hover:underline"
                        @click="cancel"
                    >
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>
