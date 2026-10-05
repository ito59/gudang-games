<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';

const props = defineProps({
    user: { type: Object, default: null },
});

const editing = Boolean(props.user);

// Creating asks only for what an account cannot exist without. The profile
// fields have defaults and are editable the moment it is made.
const form = editing
    ? useForm({
          name: props.user.name,
          username: props.user.username,
          email: props.user.email,
          bio: props.user.bio ?? '',
          location: props.user.location ?? '',
          accent_color: props.user.accent_color,
          playing: props.user.playing ?? '',
          games_owned: props.user.games_owned,
          hours_played: props.user.hours_played,
          achievements: props.user.achievements,
          is_admin: props.user.is_admin,
          is_active: props.user.is_active,
      })
    : useForm({
          name: '',
          username: '',
          email: '',
          password: '',
          password_confirmation: '',
          is_admin: false,
          is_active: true,
      });

const submit = () =>
    editing ? form.put(`/admin/users/${props.user.id}`) : form.post('/admin/users');

const field =
    'mt-1 w-full rounded-lg border-white/10 bg-[#0B1326] text-sm text-[#DAE2FD] placeholder:text-[#8B84A3] focus:border-[#7C3AED] focus:ring-[#7C3AED]';
</script>

<template>
    <Head :title="editing ? `Edit ${user.name}` : 'New account'" />

    <AdminLayout :title="editing ? `Edit ${user.name}` : 'New account'">
        <form
            class="max-w-2xl space-y-5 rounded-xl border border-white/5 bg-[#171F33] p-6"
            @submit.prevent="submit"
        >
            <div class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Display name</label>
                    <input v-model="form.name" type="text" :class="field" />
                    <p v-if="form.errors.name" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.name }}
                    </p>
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Username</label>
                    <input v-model="form.username" type="text" :class="field" />
                    <p v-if="form.errors.username" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.username }}
                    </p>
                </div>
            </div>

            <div>
                <label class="text-sm text-[#CCC3D8]">Email</label>
                <input v-model="form.email" type="email" :class="field" />
                <p v-if="form.errors.email" class="mt-1 text-xs text-[#FFB2BA]">
                    {{ form.errors.email }}
                </p>
            </div>

            <div v-if="!editing" class="grid gap-4 sm:grid-cols-2">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Password</label>
                    <input
                        v-model="form.password"
                        type="password"
                        autocomplete="new-password"
                        :class="field"
                    />
                    <p class="mt-1 text-xs text-[#8B84A3]">
                        At least 12 characters, with letters and numbers.
                    </p>
                    <p v-if="form.errors.password" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.password }}
                    </p>
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Confirm password</label>
                    <input
                        v-model="form.password_confirmation"
                        type="password"
                        autocomplete="new-password"
                        :class="field"
                    />
                </div>
            </div>

            <div v-if="editing">
                <label class="text-sm text-[#CCC3D8]">Bio</label>
                <textarea v-model="form.bio" rows="3" :class="field" />
            </div>

            <div v-if="editing" class="grid gap-4 sm:grid-cols-3">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Location</label>
                    <input v-model="form.location" type="text" :class="field" />
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Accent colour</label>
                    <input v-model="form.accent_color" type="text" placeholder="#7C3AED" :class="field" />
                    <p v-if="form.errors.accent_color" class="mt-1 text-xs text-[#FFB2BA]">
                        {{ form.errors.accent_color }}
                    </p>
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">
                        Playing
                        <span class="text-[#8B84A3]">— blank is offline</span>
                    </label>
                    <input v-model="form.playing" type="text" :class="field" />
                </div>
            </div>

            <div v-if="editing" class="grid gap-4 sm:grid-cols-3">
                <div>
                    <label class="text-sm text-[#CCC3D8]">Games owned</label>
                    <input v-model="form.games_owned" type="number" min="0" :class="field" />
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Hours played</label>
                    <input v-model="form.hours_played" type="number" min="0" :class="field" />
                </div>
                <div>
                    <label class="text-sm text-[#CCC3D8]">Achievements</label>
                    <input v-model="form.achievements" type="number" min="0" :class="field" />
                </div>
            </div>

            <div class="space-y-2">
                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_admin"
                        type="checkbox"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                    />
                    Administrator — can reach this panel
                </label>
                <label class="flex items-center gap-2 text-sm text-[#CCC3D8]">
                    <input
                        v-model="form.is_active"
                        type="checkbox"
                        class="rounded border-white/20 bg-[#0B1326] text-[#7C3AED] focus:ring-[#7C3AED]"
                    />
                    Active — unchecking suspends the account
                </label>
            </div>

            <div class="flex items-center gap-3 pt-2">
                <button
                    type="submit"
                    :disabled="form.processing"
                    class="rounded-lg bg-[#7C3AED] px-4 py-2 text-sm font-medium text-white hover:bg-[#732EE4] disabled:opacity-50"
                >
                    {{ editing ? 'Save changes' : 'Create account' }}
                </button>
                <Link href="/admin/users" class="text-sm text-[#CCC3D8] hover:underline">
                    Cancel
                </Link>
                <span v-if="editing" class="ml-auto text-xs text-[#8B84A3]">
                    {{ user.posts_count }} posts
                </span>
            </div>
        </form>
    </AdminLayout>
</template>
