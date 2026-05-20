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
const sortKey = ref(null)   // 'ref' | 'entity'
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
    const va = sortKey.value === 'ref'
      ? (a.grievance_ref ?? '')
      : (a.pah ?? a.nhs ?? '')
    const vb = sortKey.value === 'ref'
      ? (b.grievance_ref ?? '')
      : (b.pah ?? b.nhs ?? '')
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
          <span>All Grievances</span>
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
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="g in displayed"
                :key="g.grievance_id"
                style="cursor:pointer"
                @click="router.push(entityPath(g))"
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
                  <span
                    class="text-primary"
                    style="text-decoration:underline"
                    @click.stop="router.push(entityPath(g))"
                  >{{ entityId(g) }}</span>
                </td>
                <td class="table-value left">{{ g.person_name || '—' }}</td>
              </tr>
              <tr v-if="displayed.length === 0 && !loading">
                <td colspan="5" class="text-center text-disabled pa-4">No grievances found.</td>
              </tr>
            </tbody>
          </v-table>
        </v-card-text>
      </v-card>
    </v-container>
  </v-main>
</template>
