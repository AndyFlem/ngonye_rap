<script setup>
import { computed, inject, onMounted, ref } from 'vue'

const props = defineProps({
  pah: { type: String, default: null },
  nhs: { type: String, default: null }
})

const emit = defineEmits(['grievance-changed'])

const axiosSecure = inject('axiosSecure')

const grievances = ref([])
const loading = ref(false)
const error = ref('')

const dialog = ref(false)
const newGrievanceLink = ref('')
const newGrievanceRef = ref('')
const saving = ref(false)
const saveError = ref('')

const togglingId = ref(null)
const deletingId = ref(null)

const grievancesUrl = computed(() =>
  props.nhs
    ? `/fishers/${encodeURIComponent(props.nhs)}/grievances`
    : `/households/${encodeURIComponent(props.pah)}/grievances`
)

async function loadGrievances () {
  loading.value = true
  error.value = ''
  try {
    const r = await axiosSecure.get(grievancesUrl.value)
    grievances.value = Array.isArray(r.data) ? r.data : []
  } catch (err) {
    error.value = 'Failed to load grievances.'
  } finally {
    loading.value = false
  }
}

function openDialog () {
  newGrievanceLink.value = ''
  newGrievanceRef.value = ''
  saveError.value = ''
  dialog.value = true
}

async function submitGrievance () {
  if (!newGrievanceLink.value.trim() && !newGrievanceRef.value.trim()) {
    saveError.value = 'Please enter a grievance reference or link.'
    return
  }
  saving.value = true
  saveError.value = ''
  try {
    await axiosSecure.post(grievancesUrl.value, {
      grievance_link: newGrievanceLink.value.trim() || null,
      grievance_ref: newGrievanceRef.value.trim() || null
    })
    dialog.value = false
    await loadGrievances()
    emit('grievance-changed')
  } catch (err) {
    saveError.value = 'Failed to save grievance.'
  } finally {
    saving.value = false
  }
}

async function toggleIsCurrent (grievance) {
  togglingId.value = grievance.grievance_id
  try {
    await axiosSecure.patch(`/grievances/${grievance.grievance_id}`, { is_current: !grievance.is_current })
    await loadGrievances()
  } catch (err) {
    console.error('Failed to toggle grievance status:', err)
  } finally {
    togglingId.value = null
  }
}

async function deleteGrievance (grievance) {
  deletingId.value = grievance.grievance_id
  try {
    await axiosSecure.delete(`/grievances/${grievance.grievance_id}`)
    await loadGrievances()
    emit('grievance-changed')
  } catch (err) {
    console.error('Failed to delete grievance:', err)
  } finally {
    deletingId.value = null
  }
}

const getSafeUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  return /^https?:\/\//i.test(url) ? url : null
}

onMounted(loadGrievances)
defineExpose({ loadGrievances })
</script>

<template>
  <v-card elevation="1" class="mt-4">
    <v-card-title class="d-flex align-center table-heading">
      <span class="text-title-small">Grievances</span>
      <v-spacer />
      <v-btn size="small" color="primary" variant="tonal" prepend-icon="mdi-plus" @click="openDialog">
        Add Grievance
      </v-btn>
    </v-card-title>

    <v-progress-linear v-if="loading" indeterminate color="primary" />

    <v-alert v-if="error" type="error" variant="tonal" class="mx-4 my-2">{{ error }}</v-alert>

    <v-card-text v-if="grievances.length > 0" class="pa-0">
      <v-table density="compact">
        <thead>
          <tr>
            <th>Ref</th>
            <th>Link</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="g in grievances" :key="g.grievance_id">
            <td class="table-value left" style="white-space: nowrap;">{{ g.grievance_ref || '—' }}</td>
            <td class="table-value left">
              <span v-if="g.grievance_link">{{ decodeURIComponent(g.grievance_link.split('/').pop().split('?')[0]) }}</span>
              <span v-else>—</span>
              <v-btn v-if="getSafeUrl(g.grievance_link)"
                :href="getSafeUrl(g.grievance_link)"
                size="x-small" variant="text" icon="mdi-open-in-new"
                target="_blank" rel="noopener noreferrer" class="ml-1" />
            </td>
            <td style="white-space: nowrap;">
              <v-chip v-if="g.is_current" size="x-small" color="green">Current</v-chip>
            </td>
            <td style="white-space: nowrap; width: 80px;">
              <v-btn
                size="x-small"
                variant="text"
                :icon="g.is_current ? 'mdi-toggle-switch' : 'mdi-toggle-switch-off-outline'"
                :color="g.is_current ? 'green' : 'grey'"
                :loading="togglingId === g.grievance_id"
                @click="toggleIsCurrent(g)"
              />
              <v-btn
                size="x-small"
                variant="text"
                icon="mdi-delete"
                color="grey"
                :loading="deletingId === g.grievance_id"
                @click="deleteGrievance(g)"
              />
            </td>
          </tr>
        </tbody>
      </v-table>
    </v-card-text>
  </v-card>

  <v-dialog v-model="dialog" max-width="500">
    <v-card>
      <v-card-title>Add Grievance</v-card-title>
      <v-card-text>
        <v-alert v-if="saveError" type="error" variant="tonal" class="mb-3">{{ saveError }}</v-alert>
        <v-text-field v-model="newGrievanceRef" label="Grievance Ref" placeholder="e.g. GRV-001"
          density="compact" variant="outlined" class="mb-3" />
        <v-text-field v-model="newGrievanceLink" label="SharePoint Link" placeholder="https://..."
          density="compact" variant="outlined" />
      </v-card-text>
      <v-card-actions>
        <v-spacer />
        <v-btn variant="text" :disabled="saving" @click="dialog = false">Cancel</v-btn>
        <v-btn color="primary" variant="tonal" :loading="saving" @click="submitGrievance">Save</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>
