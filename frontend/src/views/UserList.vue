<script setup>
import { inject, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'

const axiosSecure = inject('axiosSecure')
const router = useRouter()

const users = ref([])
const loading = ref(false)
const error = ref('')
const deleteDialog = ref(false)
const deleting = ref(false)
const deleteError = ref('')
const userToDelete = ref(null)

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get('/users')
    users.value = Array.isArray(response.data) ? response.data : []
  } catch (err) {
    error.value = 'Failed to load users.'
  } finally {
    loading.value = false
  }
}

function openDeleteDialog (user) {
  userToDelete.value = user
  deleteError.value = ''
  deleteDialog.value = true
}

const confirmDelete = async () => {
  deleting.value = true
  deleteError.value = ''
  try {
    await axiosSecure.delete(`/user/${userToDelete.value.user_id}`)
    users.value = users.value.filter(u => u.user_id !== userToDelete.value.user_id)
    deleteDialog.value = false
  } catch (err) {
    deleteError.value = 'Failed to delete user.'
  } finally {
    deleting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-card elevation="1">
          <v-card-title class="d-flex align-center table-heading">
            <span>Users</span>
            <v-spacer />
            <v-btn
              size="small"
              color="primary"
              variant="tonal"
              prepend-icon="mdi-plus"
              @click="router.push('/users/new')"
            >
              Add User
            </v-btn>
          </v-card-title>

          <v-card-text class="pa-0">
            <v-alert v-if="error" type="error" variant="tonal" class="ma-4">{{ error }}</v-alert>

            <v-table density="compact" v-if="!loading">
              <thead>
                <tr>
                  <th class="table-heading">Name</th>
                  <th class="table-heading">Email</th>
                  <th class="table-heading">Organisation</th>
                  <th class="table-heading center">Can Login</th>
                  <th class="table-heading center">Status</th>
                  <th class="table-heading"></th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="user in users"
                  :key="user.user_id"
                  :class="user.is_deleted ? 'text-disabled' : ''"
                >
                  <td>{{ user.user_name }}</td>
                  <td>{{ user.email }}</td>
                  <td>{{ user.organisation ?? '—' }}</td>
                  <td class="center">
                    <v-icon v-if="user.can_login" icon="mdi-check" color="success" size="small" />
                    <v-icon v-else icon="mdi-close" color="grey" size="small" />
                  </td>
                  <td class="center">
                    <v-chip v-if="user.is_deleted" size="x-small" color="error">Deleted</v-chip>
                    <v-chip v-else size="x-small" color="success">Active</v-chip>
                  </td>
                  <td class="right">
                    <v-btn
                      size="x-small"
                      icon="mdi-pencil"
                      variant="text"
                      @click="router.push(`/users/${user.user_id}/edit`)"
                    />
                    <v-btn
                      size="x-small"
                      icon="mdi-delete"
                      variant="text"
                      color="red"
                      @click="openDeleteDialog(user)"
                    />
                  </td>
                </tr>
                <tr v-if="users.length === 0">
                  <td colspan="6" class="text-center text-disabled pa-4">No users found.</td>
                </tr>
              </tbody>
            </v-table>

            <div v-if="loading" class="d-flex justify-center pa-6">
              <v-progress-circular indeterminate color="primary" />
            </div>
          </v-card-text>
        </v-card>
      </v-container>
    </v-main>

    <v-dialog v-model="deleteDialog" max-width="420">
      <v-card>
        <v-card-title>Delete User</v-card-title>
        <v-card-text>
          <v-alert v-if="deleteError" type="error" variant="tonal" class="mb-3">{{ deleteError }}</v-alert>
          Are you sure you want to delete <strong>{{ userToDelete?.user_name }}</strong>? This action cannot be easily undone.
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" :disabled="deleting" @click="deleteDialog = false">Cancel</v-btn>
          <v-btn color="red" variant="tonal" :loading="deleting" @click="confirmDelete">Delete</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>
