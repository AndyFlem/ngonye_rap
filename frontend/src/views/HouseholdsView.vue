<script setup>
import { inject, onMounted, ref } from 'vue'
import TopBar from '@/components/TopBar.vue'

const axiosSecure = inject('axiosSecure')

const search = ref('')
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

const loadHouseholds = async () => {
  loading.value = true
  error.value = ''

  try {
    const q = search.value.trim()
    const response = await axiosSecure.get('/households', {
      params: q ? { q } : {}
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
  search.value = ''
  loadHouseholds()
}

onMounted(() => {
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
              Search by PAH, household head, NRC, or village.
            </p>
          </v-col>
        </v-row>

        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12" md="8">
                <v-text-field
                  v-model="search"
                  label="Search households"
                  placeholder="Enter PAH, household head, NRC, or village"
                  prepend-inner-icon="mdi-magnify"
                  clearable
                  @keyup.enter="handleSearch"
                />
              </v-col>
              <v-col cols="12" md="4" class="d-flex align-center ga-2">
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
            :items-per-page="10"
            loading-text="Loading households..."
            no-data-text="No households found"
          >
            <template #item.vulnerable="{ item }">
              <v-chip size="small" :color="item.vulnerable ? 'warning' : 'default'" variant="tonal">
                {{ item.vulnerable ? 'Yes' : 'No' }}
              </v-chip>
            </template>

            <template #item.physically_displaced="{ item }">
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
