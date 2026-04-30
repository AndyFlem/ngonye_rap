<script setup>
import { computed, inject, onMounted, ref, watch } from 'vue'

import TopBar from '@/components/TopBar.vue'
import HouseholdSearchResult from '@/views/HouseholdSearchResult.vue'

const axiosSecure = inject('axiosSecure')


const icarequired = ref(true)

const search = ref({
  params: {
    pah: '',
    household_head: '',
    nrc: '',
    village_id: 'all',
    vulnerable: null,
    physically_displaced: null,
    nonaffected: null,
    no_ica_required: false,
    icasigned: null
  }
})

const getICARequiredIndet = computed(() => icarequired.value === null)
const villages = ref([])
const loading = ref(false)
const error = ref('')
const page = ref(1)
const pahs = ref([])

watch(icarequired, (newValue) => {
  if (newValue === null) {
    search.value.params.no_ica_required = null
  } else {
    search.value.params.no_ica_required = !newValue
  }
}, { immediate: true })

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

function doSearch () {
  loading.value = true
  error.value = ''
  pahs.value = []

  axiosSecure.post('/households_search', search.value.params)
    .then(response => {
      pahs.value = response.data
      console.log('Search results:', pahs.value)
    })
    .catch(err => {
      console.error('Search failed:', err)
      error.value = 'An error occurred while searching. Please try again.'
    })
    .finally(() => {
      loading.value = false
    })
}

onMounted(() => {
  loadVillages()
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
          </v-col>
        </v-row>

        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12" md="3">
                <v-text-field
                  v-model="search.params.pah"
                  label="PAH"
                  placeholder="PAH No"
                  prepend-inner-icon="mdi-magnify"
                  clearable
                  @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-text-field
                  v-model="search.params.household_head"
                  label="Household Head"
                  placeholder="Enter household head"
                  clearable
                  @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="2">
                <v-text-field
                  v-model="search.params.nrc"
                  label="NRC"
                  placeholder="Enter NRC"
                  clearable
                  @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-autocomplete
                  v-model="search.params.village_id"
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
                <div class="d-flex align-center ga-1 pr-4 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.nonaffected"
                    label="Non-affected"
                    hide-details
                    density="comfortable"
                  />
                </div>
                <div class="d-flex align-center ga-1 pr-4 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="icarequired"
                    label="ICA Required"
                    hide-details
                    :indeterminate="getICARequiredIndet"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="icarequired = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.icasigned"
                    label="ICA Signed"
                    hide-details
                    :indeterminate="search.params.icasigned === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    :loading="loading"
                    variant="text"
                    @click="search.params.icasigned = null"
                  />
                </div>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="8" class="d-flex flex-wrap align-center ga-4">
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.vulnerable"
                    label="Vulnerable"
                    hide-details
                    :indeterminate="search.params.vulnerable === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="search.params.vulnerable = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.physically_displaced"
                    label="Physically displaced"
                    hide-details
                    :indeterminate="search.params.physically_displaced === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="search.params.physically_displaced = null"
                  />
                </div>
              </v-col>
            </v-row>
            <v-row >
              <v-col cols="6">
                {{ pahs.length }} result(s) found.
              </v-col>
              <v-col cols="6" class="d-flex align-center ga-2 justify-end">
                <v-btn color="primary" :loading="loading" @click="doSearch">Search</v-btn>
              </v-col>
            </v-row>

            <v-alert v-if="error" type="error" variant="tonal" class="mt-2">
              {{ error }}
            </v-alert>
          </v-card-text>
        </v-card>

        <v-card elevation="0">
            <v-data-iterator
              v-if="pahs"
              :items="pahs"
              :loading="loading"
              :page="page"
              :items-per-page="30"
            >
              <template v-slot:default="props">
                <v-row no-gutters>
                  <v-col
                    v-for="item in props.items"
                    :key="item.raw.pah"
                    cols="12"
                    class="pl-1 pr-1 pt-1 pb-1"
                  >
                    <household-search-result :pah-no="item.raw.pah" />
                  </v-col>
                </v-row>
              </template>
              <template v-slot:footer="{ pageCount }">
                <v-pagination v-model="page" :length="pageCount"></v-pagination>
              </template>
            </v-data-iterator>
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
