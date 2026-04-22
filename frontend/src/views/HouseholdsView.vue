<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'

const axiosSecure = inject('axiosSecure')
const router = useRouter()

const searchPah = ref('')
const searchHouseholdHead = ref('')
const searchNrc = ref('')
const selectedVillageId = ref('all')
const villages = ref([])
const filterVulnerable = ref(false)
const filterPhysicallyDisplaced = ref(false)
const filterNonaffected = ref(false)
const households = ref([])
const loading = ref(false)
const error = ref('')

const headers = [
  { title: 'PAH', key: 'pah', sortable: true },
  { title: 'Household Head', key: 'household_head', sortable: true },
  { title: 'NRC', key: 'nrc', sortable: true },
  { title: 'Village', key: 'village', sortable: true },
  { title: 'Vulnerable', key: 'vulnerable', sortable: true },
  { title: 'Physically Displaced', key: 'physically_displaced', sortable: true }
]

const villageOptions = computed(() => [
  { village_id: 'all', village: 'All villages' },
  ...villages.value
])

const loadVillages = async () => {
  try {
    const response = await axiosSecure.get('/villages')
    villages.value = Array.isArray(response.data) ? response.data : []
  } catch (err) {
    console.error('Failed to load villages:', err)
  }
}

const loadHouseholds = async () => {
  loading.value = true
  error.value = ''

  try {
    const params = {}

    const normalizeFilter = (value) => {
      if (typeof value === 'string') return value.trim()
      if (value == null) return ''
      return String(value).trim()
    }

    const pah = normalizeFilter(searchPah.value)
    const household_head = normalizeFilter(searchHouseholdHead.value)
    const nrc = normalizeFilter(searchNrc.value)
    const village_id = normalizeFilter(selectedVillageId.value)

    if (pah) params.pah = pah
    if (household_head) params.household_head = household_head
    if (nrc) params.nrc = nrc
    if (village_id && village_id !== 'all') params.village_id = village_id
    if (filterVulnerable.value) params.vulnerable = true
    if (filterPhysicallyDisplaced.value) params.physically_displaced = true
    if (filterNonaffected.value) params.nonaffected = true

    const response = await axiosSecure.get('/households', {
      params
    })

    households.value = Array.isArray(response.data) ? response.data : []
  } catch (err) {
    error.value = 'Failed to load households. Please try again.'
    console.error('Failed to load households:', err)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  loadHouseholds()
}

const handleReset = () => {
  searchPah.value = ''
  searchHouseholdHead.value = ''
  searchNrc.value = ''
  selectedVillageId.value = 'all'
  filterVulnerable.value = false
  filterPhysicallyDisplaced.value = false
  filterNonaffected.value = false
  loadHouseholds()
}

const handleRowClick = (_event, rowData) => {
  const row = rowData?.item?.raw || rowData?.item || null
  const pah = row?.pah

  if (pah) {
    router.push(`/households/${encodeURIComponent(pah)}`)
  }
}

onMounted(() => {
  loadVillages()
  loadHouseholds()
})
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row class="mb-4" align="center">
          <v-col cols="12" md="8">
            <h1 class="text-h4 mb-2">Households (PAHs)</h1>
            <p class="text-body2 text-medium-emphasis">
              Search by PAH, household head, NRC, or select a village. Use checkboxes for vulnerable, physically displaced, and nonaffected.
            </p>
          </v-col>
        </v-row>

        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12" md="3">
                <v-text-field
                  v-model="searchPah"
                  label="PAH"
                  placeholder="Enter PAH"
                  prepend-inner-icon="mdi-magnify"
                  clearable
                  @keyup.enter="handleSearch"
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-text-field
                  v-model="searchHouseholdHead"
                  label="Household Head"
                  placeholder="Enter household head"
                  clearable
                  @keyup.enter="handleSearch"
                />
              </v-col>
              <v-col cols="12" md="2">
                <v-text-field
                  v-model="searchNrc"
                  label="NRC"
                  placeholder="Enter NRC"
                  clearable
                  @keyup.enter="handleSearch"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-autocomplete
                  v-model="selectedVillageId"
                  :items="villageOptions"
                  item-title="village"
                  item-value="village_id"
                  label="Village"
                  placeholder="All villages"
                  clearable
                  no-data-text="No villages found"
                />
              </v-col>
            </v-row>

            <v-row>
              <v-col cols="12" md="8" class="d-flex flex-wrap align-center ga-4">
                <v-checkbox
                  v-model="filterVulnerable"
                  label="Vulnerable only"
                  hide-details
                  density="comfortable"
                />
                <v-checkbox
                  v-model="filterPhysicallyDisplaced"
                  label="Physically displaced only"
                  hide-details
                  density="comfortable"
                />
                <v-checkbox
                  v-model="filterNonaffected"
                  label="Nonaffected only"
                  hide-details
                  density="comfortable"
                />
              </v-col>
              <v-col cols="12" md="4" class="d-flex align-center ga-2 justify-md-end">
                <v-btn color="primary" :loading="loading" @click="handleSearch">Search</v-btn>
                <v-btn variant="text" @click="handleReset">Reset</v-btn>
              </v-col>
            </v-row>

            <v-alert v-if="error" type="error" variant="tonal" class="mt-2">
              {{ error }}
            </v-alert>
          </v-card-text>
        </v-card>

        <v-card elevation="1">
          <v-data-table
            :headers="headers"
            :items="households"
            :loading="loading"
            density="compact"
            :items-per-page="10"
            :row-props="() => ({ class: 'household-row' })"
            @click:row="handleRowClick"
            loading-text="Loading households..."
            no-data-text="No households found"
          >
            <template #[`item.pah`]="{ item }">
              <router-link class="primary white--text" :to="{ name: 'HouseholdDetails', params: { pah: item.pah } }">{{ item.pah }}</router-link>
            </template>
            <template #[`item.vulnerable`]="{ item }">
              <v-chip size="small" :color="item.vulnerable ? 'warning' : 'default'" variant="tonal">
                {{ item.vulnerable ? 'Yes' : 'No' }}
              </v-chip>
            </template>

            <template #[`item.physically_displaced`]="{ item }">
              <v-chip size="small" :color="item.physically_displaced ? 'error' : 'default'" variant="tonal">
                {{ item.physically_displaced ? 'Yes' : 'No' }}
              </v-chip>
            </template>
          </v-data-table>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>

<style scoped>
:deep(.household-row) {
  cursor: pointer;
}
</style>
