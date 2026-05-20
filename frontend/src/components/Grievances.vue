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
const newDateReceived = ref('')
const saving = ref(false)
const saveError = ref('')

const togglingId = ref(null)
const deletingId = ref(null)

const editingGrievanceId = ref(null)
const draftEditRef = ref('')
const draftEditLink = ref('')
const savingEdit = ref(false)

const editingDateId = ref(null)
const draftEditDate = ref('')
const savingEditDate = ref(false)

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
  newDateReceived.value = ''
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
      grievance_ref: newGrievanceRef.value.trim() || null,
      date_received: newDateReceived.value || null
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

function startEditGrievance (g) {
  editingGrievanceId.value = g.grievance_id
  draftEditRef.value = g.grievance_ref ?? ''
  draftEditLink.value = g.grievance_link ?? ''
}

async function saveEditGrievance (g) {
  savingEdit.value = true
  try {
    await axiosSecure.patch(`/grievances/${g.grievance_id}`, {
      grievance_ref: draftEditRef.value.trim() || null,
      grievance_link: draftEditLink.value.trim() || null
    })
    editingGrievanceId.value = null
    await loadGrievances()
  } catch (err) {
    console.error('Failed to update grievance:', err)
  } finally {
    savingEdit.value = false
  }
}

function startEditDate (g) {
  editingDateId.value = g.grievance_id
  draftEditDate.value = g.date_received ?? ''
}

async function saveEditDate (g) {
  savingEditDate.value = true
  try {
    await axiosSecure.patch(`/grievances/${g.grievance_id}`, {
      date_received: draftEditDate.value || null
    })
    editingDateId.value = null
    await loadGrievances()
  } catch (err) {
    console.error('Failed to update date received:', err)
  } finally {
    savingEditDate.value = false
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
            <th style="white-space:nowrap">Date Received</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="g in grievances" :key="g.grievance_id">
            <td class="table-value left" style="white-space: nowrap;">
              <template v-if="editingGrievanceId !== g.grievance_id">
                <span>{{ g.grievance_ref || '—' }}</span>
                <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                  style="height:1em;width:1em;min-height:unset;min-width:unset"
                  @click="startEditGrievance(g)" />
              </template>
              <template v-else>
                <v-text-field v-model="draftEditRef" density="compact" hide-details
                  variant="underlined" style="max-width:140px" placeholder="e.g. GRV-001" />
              </template>
            </td>
            <td class="table-value left">
              <template v-if="editingGrievanceId !== g.grievance_id">
                <span v-if="g.grievance_link">{{ decodeURIComponent(g.grievance_link.split('/').pop().split('?')[0]) }}</span>
                <span v-else>—</span>
                <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                  style="height:1em;width:1em;min-height:unset;min-width:unset"
                  @click="startEditGrievance(g)" />
                <v-btn v-if="getSafeUrl(g.grievance_link)"
                  :href="getSafeUrl(g.grievance_link)"
                  size="x-small" variant="text" icon="mdi-open-in-new"
                  target="_blank" rel="noopener noreferrer" class="ml-1" />
              </template>
              <template v-else>
                <v-text-field v-model="draftEditLink" density="compact" hide-details
                  variant="underlined" style="max-width:320px" placeholder="https://..." />
                <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                  :loading="savingEdit" @click="saveEditGrievance(g)" />
                <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                  @click="editingGrievanceId = null" />
              </template>
            </td>
            <td style="white-space: nowrap;">
              <template v-if="editingDateId !== g.grievance_id">
                <span>{{ g.date_received || '—' }}</span>
                <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                  style="height:1em;width:1em;min-height:unset;min-width:unset"
                  @click="startEditDate(g)" />
              </template>
              <template v-else>
                <v-text-field v-model="draftEditDate" type="date" density="compact" hide-details
                  variant="underlined" style="max-width:160px" />
                <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                  :loading="savingEditDate" @click="saveEditDate(g)" />
                <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                  @click="editingDateId = null" />
              </template>
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
          density="compact" variant="outlined" class="mb-3" />
        <v-text-field v-model="newDateReceived" label="Date Received" type="date"
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
