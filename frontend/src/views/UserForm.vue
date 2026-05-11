<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const isEdit = computed(() => Boolean(route.params.id))
const userId = computed(() => route.params.id)

const form = ref({
  first_name: '',
  last_name: '',
  email: '',
  organisation: '',
  can_login: true,
  admin: false,
  password: ''
})

const loading = ref(false)
const saving = ref(false)
const error = ref('')
const validationErrors = ref({})

const validate = () => {
  const errs = {}
  if (!form.value.first_name.trim()) errs.first_name = 'First name is required.'
  if (!form.value.last_name.trim()) errs.last_name = 'Last name is required.'
  if (!form.value.email.trim()) errs.email = 'Email is required.'
  if (!isEdit.value && !form.value.password) errs.password = 'Password is required.'
  validationErrors.value = errs
  return Object.keys(errs).length === 0
}

const load = async () => {
  if (!isEdit.value) return
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get(`/user/${userId.value}`)
    const u = response.data
    form.value.first_name = u.first_name ?? ''
    form.value.last_name = u.last_name ?? ''
    form.value.email = u.email ?? ''
    form.value.organisation = u.organisation ?? ''
    form.value.can_login = u.can_login ?? true
    form.value.admin = u.admin ?? false
    form.value.password = ''
  } catch (err) {
    error.value = 'Failed to load user.'
  } finally {
    loading.value = false
  }
}

const save = async () => {
  if (!validate()) return

  saving.value = true
  error.value = ''
  try {
    if (isEdit.value) {
      await axiosSecure.put(`/user/${userId.value}`, {
        first_name: form.value.first_name,
        last_name: form.value.last_name,
        email: form.value.email,
        organisation: form.value.organisation,
        can_login: form.value.can_login,
        admin: form.value.admin
      })
      if (form.value.password) {
        await axiosSecure.put(`/user/${userId.value}/updatepassword`, {
          password: form.value.password
        })
      }
    } else {
      await axiosSecure.post('/user', {
        first_name: form.value.first_name,
        last_name: form.value.last_name,
        email: form.value.email,
        organisation: form.value.organisation,
        can_login: form.value.can_login,
        admin: form.value.admin,
        password: form.value.password
      })
    }
    router.push('/users')
  } catch (err) {
    error.value = isEdit.value ? 'Failed to update user.' : 'Failed to create user.'
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-card elevation="1" max-width="560">
          <v-card-title class="table-heading">
            {{ isEdit ? 'Edit User' : 'Add User' }}
          </v-card-title>

          <v-card-text>
            <div v-if="loading" class="d-flex justify-center pa-6">
              <v-progress-circular indeterminate color="primary" />
            </div>

            <template v-else>
              <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>

              <v-row>
                <v-col cols="12" sm="6">
                  <v-text-field
                    v-model="form.first_name"
                    label="First Name"
                    density="compact"
                    variant="outlined"
                    :error-messages="validationErrors.first_name"
                    @input="delete validationErrors.first_name"
                  />
                </v-col>
                <v-col cols="12" sm="6">
                  <v-text-field
                    v-model="form.last_name"
                    label="Last Name"
                    density="compact"
                    variant="outlined"
                    :error-messages="validationErrors.last_name"
                    @input="delete validationErrors.last_name"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model="form.email"
                    label="Email"
                    type="email"
                    density="compact"
                    variant="outlined"
                    :error-messages="validationErrors.email"
                    @input="delete validationErrors.email"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model="form.organisation"
                    label="Organisation"
                    density="compact"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model="form.password"
                    label="Password"
                    type="password"
                    density="compact"
                    variant="outlined"
                    :placeholder="isEdit ? 'Leave blank to keep existing password' : ''"
                    :hint="isEdit ? 'Leave blank to keep existing password' : ''"
                    persistent-hint
                    :error-messages="validationErrors.password"
                    @input="delete validationErrors.password"
                  />
                </v-col>
                <v-col cols="12">
                  <v-checkbox
                    v-model="form.can_login"
                    label="Can log in"
                    density="compact"
                    hide-details
                  />
                </v-col>
                <v-col cols="12">
                  <v-checkbox
                    v-model="form.admin"
                    label="Admin"
                    density="compact"
                    hide-details
                  />
                </v-col>
              </v-row>
            </template>
          </v-card-text>

          <v-card-actions>
            <v-spacer />
            <v-btn variant="text" :disabled="saving" @click="router.push('/users')">Cancel</v-btn>
            <v-btn color="primary" variant="tonal" :loading="saving" @click="save">
              {{ isEdit ? 'Save' : 'Create' }}
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
