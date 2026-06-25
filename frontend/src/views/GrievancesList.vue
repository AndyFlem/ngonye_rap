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
                <td class="table-value left" style="white-space:nowrap">{{ g.grievance_ref || '—' }}</td>
                <td>
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
                </td>
                <td style="white-space:nowrap">
                  <v-chip v-if="g.is_current" size="x-small" color="green">Current</v-chip>
                  <v-chip v-else size="x-small" color="grey" variant="outlined">Closed</v-chip>
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
