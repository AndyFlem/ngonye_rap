<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'

const axiosSecure = inject('axiosSecure')
const router = useRouter()

const grievances = ref([])
const loading = ref(false)
const error = ref('')
const showCurrentOnly = ref(false)
const sortKey = ref(null)   // 'ref' | 'entity' | 'date'
const sortDir = ref(1)      // 1 = asc, -1 = desc

const toggleSort = (key) => {
  if (sortKey.value === key) {
    sortDir.value *= -1
  } else {
    sortKey.value = key
    sortDir.value = 1
  }
}

const sortIcon = (key) => {
  if (sortKey.value !== key) return 'mdi-unfold-more-horizontal'
  return sortDir.value === 1 ? 'mdi-arrow-up' : 'mdi-arrow-down'
}

const displayed = computed(() => {
  let rows = showCurrentOnly.value
    ? grievances.value.filter(g => g.is_current)
    : grievances.value

  if (!sortKey.value) return rows

  return [...rows].sort((a, b) => {
    let va, vb
    if (sortKey.value === 'ref') {
      va = a.grievance_ref ?? ''
      vb = b.grievance_ref ?? ''
    } else if (sortKey.value === 'date') {
      va = a.date_received ?? ''
      vb = b.date_received ?? ''
    } else {
      va = a.pah ?? a.nhs ?? ''
      vb = b.pah ?? b.nhs ?? ''
    }
    return va.localeCompare(vb, undefined, { numeric: true }) * sortDir.value
  })
})

const getSafeUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  return /^https?:\/\//i.test(url) ? url : null
}

const entityId = (g) => g.pah ?? g.nhs

const entityPath = (g) => g.pah
  ? `/households/${encodeURIComponent(g.pah)}`
  : `/fishers/${encodeURIComponent(g.nhs)}`

const editingDateId = ref(null)
const draftEditDate = ref('')
const savingEditDate = ref(false)

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
    const idx = grievances.value.findIndex(x => x.grievance_id === g.grievance_id)
    if (idx !== -1) grievances.value[idx].date_received = draftEditDate.value || null
  } catch (err) {
    console.error('Failed to update date received:', err)
  } finally {
    savingEditDate.value = false
  }
}

const editingRefId = ref(null)
const draftEditRef = ref('')
const savingEditRef = ref(false)

function startEditRef (g) {
  editingRefId.value = g.grievance_id
  draftEditRef.value = g.grievance_ref ?? ''
}

async function saveEditRef (g) {
  savingEditRef.value = true
  try {
    await axiosSecure.patch(`/grievances/${g.grievance_id}`, {
      grievance_ref: draftEditRef.value || null
    })
    editingRefId.value = null
    const idx = grievances.value.findIndex(x => x.grievance_id === g.grievance_id)
    if (idx !== -1) grievances.value[idx].grievance_ref = draftEditRef.value || null
  } catch (err) {
    console.error('Failed to update ref:', err)
  } finally {
    savingEditRef.value = false
  }
}

const editingLinkId = ref(null)
const draftEditLink = ref('')
const savingEditLink = ref(false)

function startEditLink (g) {
  editingLinkId.value = g.grievance_id
  draftEditLink.value = g.grievance_link ?? ''
}

async function saveEditLink (g) {
  savingEditLink.value = true
  try {
    await axiosSecure.patch(`/grievances/${g.grievance_id}`, {
      grievance_link: draftEditLink.value || null
    })
    editingLinkId.value = null
    const idx = grievances.value.findIndex(x => x.grievance_id === g.grievance_id)
    if (idx !== -1) grievances.value[idx].grievance_link = draftEditLink.value || null
  } catch (err) {
    console.error('Failed to update link:', err)
  } finally {
    savingEditLink.value = false
  }
}

const editingStatusId = ref(null)
const draftEditStatus = ref(true)
const savingEditStatus = ref(false)

function startEditStatus (g) {
  editingStatusId.value = g.grievance_id
  draftEditStatus.value = g.is_current
}

async function saveEditStatus (g) {
  savingEditStatus.value = true
  try {
    await axiosSecure.patch(`/grievances/${g.grievance_id}`, {
      is_current: draftEditStatus.value
    })
    editingStatusId.value = null
    const idx = grievances.value.findIndex(x => x.grievance_id === g.grievance_id)
    if (idx !== -1) grievances.value[idx].is_current = draftEditStatus.value
  } catch (err) {
    console.error('Failed to update status:', err)
  } finally {
    savingEditStatus.value = false
  }
}

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axiosSecure.get('/grievances')
    grievances.value = Array.isArray(res.data) ? res.data : []
  } catch {
    error.value = 'Failed to load grievances.'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <TopBar />
  <v-main>
    <v-container class="pa-6">
      <v-card elevation="1">
        <v-card-title class="d-flex align-center table-heading">
          <span>Grievances</span><span v-if="!loading">&nbsp;({{ grievances.length }})</span>
          <v-spacer />
          <v-switch
            v-model="showCurrentOnly"
            label="Current only"
            density="compact"
            hide-details
            class="mr-2"
          />
        </v-card-title>

        <v-progress-linear v-if="loading" indeterminate color="primary" />
        <v-alert v-if="error" type="error" variant="tonal" class="ma-4">{{ error }}</v-alert>

        <v-card-text class="pa-0">
          <v-table density="compact" v-if="!loading">
            <thead>
              <tr>
                <th class="table-heading" style="cursor:pointer; white-space:nowrap" @click="toggleSort('ref')">
                  Ref <v-icon size="x-small" :icon="sortIcon('ref')" />
                </th>
                <th class="table-heading">Link</th>
                <th class="table-heading">Status</th>
                <th class="table-heading" style="cursor:pointer; white-space:nowrap" @click="toggleSort('entity')">
                  PAH / NHS <v-icon size="x-small" :icon="sortIcon('entity')" />
                </th>
                <th class="table-heading">Name</th>
                <th class="table-heading" style="cursor:pointer; white-space:nowrap" @click="toggleSort('date')">
                  Date Received <v-icon size="x-small" :icon="sortIcon('date')" />
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="g in displayed"
                :key="g.grievance_id"
                style="cursor:pointer"
              >
                <td class="table-value left" style="white-space:nowrap" @click.stop>
                  <template v-if="editingRefId !== g.grievance_id">
                    <span>{{ g.grievance_ref || '—' }}</span>
                    <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                      style="height:1em;width:1em;min-height:unset;min-width:unset"
                      @click="startEditRef(g)" />
                  </template>
                  <template v-else>
                    <v-text-field v-model="draftEditRef" density="compact" hide-details
                      variant="underlined" style="max-width:140px" />
                    <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                      :loading="savingEditRef" @click="saveEditRef(g)" />
                    <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                      @click="editingRefId = null" />
                  </template>
                </td>
                <td @click.stop>
                  <template v-if="editingLinkId !== g.grievance_id">
                    <a
                      v-if="getSafeUrl(g.grievance_link)"
                      :href="getSafeUrl(g.grievance_link)"
                      target="_blank"
                      rel="noopener noreferrer"
                      @click.stop
                    >
                      View
                      <v-icon size="x-small" icon="mdi-open-in-new" />
                    </a>
                    <span v-else class="text-disabled">—</span>
                    <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                      style="height:1em;width:1em;min-height:unset;min-width:unset"
                      @click="startEditLink(g)" />
                  </template>
                  <template v-else>
                    <v-text-field v-model="draftEditLink" density="compact" hide-details
                      variant="underlined" style="max-width:260px" placeholder="https://…" />
                    <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                      :loading="savingEditLink" @click="saveEditLink(g)" />
                    <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                      @click="editingLinkId = null" />
                  </template>
                </td>
                <td style="white-space:nowrap" @click.stop>
                  <template v-if="editingStatusId !== g.grievance_id">
                    <v-chip v-if="g.is_current" size="x-small" color="green">Current</v-chip>
                    <v-chip v-else size="x-small" color="grey" variant="outlined">Closed</v-chip>
                    <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                      style="height:1em;width:1em;min-height:unset;min-width:unset"
                      @click="startEditStatus(g)" />
                  </template>
                  <template v-else>
                    <v-select v-model="draftEditStatus" density="compact" hide-details
                      variant="underlined" style="max-width:120px"
                      :items="[{ title: 'Current', value: true }, { title: 'Closed', value: false }]"
                      item-title="title" item-value="value" />
                    <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                      :loading="savingEditStatus" @click="saveEditStatus(g)" />
                    <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                      @click="editingStatusId = null" />
                  </template>
                </td>
                <td style="white-space:nowrap">
                  <router-link :to="entityPath(g)" class="">{{ entityId(g) }}</router-link>
                </td>
                <td class="table-value left" @click.stop>
                  <router-link :to="`/people/${g.person_id}`">{{ g.person_name }}</router-link>
                </td>
                <td style="white-space:nowrap" @click.stop>
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
              </tr>
              <tr v-if="displayed.length === 0 && !loading">
                <td colspan="6" class="text-center text-disabled pa-4">No grievances found.</td>
              </tr>
            </tbody>
          </v-table>
        </v-card-text>
      </v-card>
    </v-container>
  </v-main>
</template>
