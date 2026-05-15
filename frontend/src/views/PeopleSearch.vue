<script setup>
import { inject, nextTick, onMounted, ref, watch } from 'vue'
import TopBar from '@/components/TopBar.vue'
import PeopleSearchResult from '@/components/PeopleSearchResult.vue'

const STORAGE_KEY = 'person_search_state'
const GENDER_OPTIONS = ['Male', 'Female']

const defaultParams = () => ({
  name: '',
  nrc: '',
  nhs: '',
  pah: '',
  gender: null,
  is_fisher: null,
  is_head: null,
  is_cosignatory: null,
  is_disabled: null
})

const axiosSecure = inject('axiosSecure')

const search = ref({ params: defaultParams() })
const results = ref([])
const loading = ref(false)
const downloading = ref(false)
const error = ref('')
const page = ref(1)
let autoSearchReady = false

function saveSearchState () {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(search.value.params))
}

function restoreSearchState () {
  const saved = localStorage.getItem(STORAGE_KEY)
  if (saved) { search.value.params = { ...defaultParams(), ...JSON.parse(saved) } }
}

async function doSearch () {
  loading.value = true
  error.value = ''
  results.value = []
  page.value = 1
  saveSearchState()
  try {
    const response = await axiosSecure.post('/people_search', search.value.params)
    results.value = response.data
  } catch (err) {
    console.error('Search failed:', err)
    error.value = 'An error occurred while searching. Please try again.'
  } finally {
    loading.value = false
  }
}

function clearSearch () {
  search.value.params = defaultParams()
  results.value = []
  error.value = ''
  localStorage.removeItem(STORAGE_KEY)
}

function downloadCsv () {
  downloading.value = true
  axiosSecure.post('/people_export', search.value.params, { responseType: 'blob' })
    .then(response => {
      const url = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }))
      const link = document.createElement('a')
      link.href = url
      const name = `${new Date().toISOString().slice(0, 10)}_people_export.csv`
      link.setAttribute('download', name)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
    })
    .catch(err => { console.error('Export failed:', err) })
    .finally(() => { downloading.value = false })
}

const autoSearchFields = [
  () => search.value.params.gender,
  () => search.value.params.is_fisher,
  () => search.value.params.is_head,
  () => search.value.params.is_cosignatory,
  () => search.value.params.is_disabled
]

watch(autoSearchFields, () => {
  if (autoSearchReady) doSearch()
})

onMounted(() => {
  restoreSearchState()
  doSearch()
  nextTick(() => { autoSearchReady = true })
})
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row class="mb-4" align="center">
          <v-col cols="12">
            <h1 class="text-h4">People</h1>
          </v-col>
        </v-row>

        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12" md="3">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.name"
                  label="Name" placeholder="Enter name"
                  prepend-inner-icon="mdi-magnify"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.nrc"
                  label="NRC" placeholder="Enter NRC"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.nhs"
                  label="NHS No" placeholder="NHS No"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.pah"
                  label="PAH" placeholder="PAH"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
            </v-row>
            <v-row class="mt-2">
              <v-col cols="12" md="3">
                <v-select
                  density="compact" hide-details
                  v-model="search.params.gender"
                  :items="GENDER_OPTIONS"
                  label="Gender" placeholder="Any"
                  clearable
                />
              </v-col>
            </v-row>
            <v-row class="mt-4">
              <v-col cols="12" class="d-flex flex-wrap align-center ga-4">
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.is_fisher"
                    label="Fisher" hide-details
                    :indeterminate="search.params.is_fisher === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.is_fisher = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.is_head"
                    label="Household Head" hide-details
                    :indeterminate="search.params.is_head === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.is_head = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.is_cosignatory"
                    label="Cosignatory" hide-details
                    :indeterminate="search.params.is_cosignatory === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.is_cosignatory = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.is_disabled"
                    label="Disabled" hide-details
                    :indeterminate="search.params.is_disabled === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.is_disabled = null"
                  />
                </div>
              </v-col>
            </v-row>
            <v-row class="mt-2" align="center">
              <v-col cols="6">
                {{ results.length }} result(s) found.
              </v-col>
              <v-col cols="6" class="d-flex justify-end ga-2">
                <v-btn color="primary" append-icon="mdi-close" @click="clearSearch">Clear</v-btn>
                <v-btn color="primary" :loading="loading" append-icon="mdi-magnify" @click="doSearch">Search</v-btn>
                <v-btn color="primary" :loading="downloading" append-icon="mdi-download" @click="downloadCsv">Download</v-btn>
              </v-col>
            </v-row>
            <v-alert v-if="error" type="error" variant="tonal" class="mt-2">{{ error }}</v-alert>
          </v-card-text>
        </v-card>

        <v-progress-linear v-if="loading" indeterminate class="mb-2" />

        <v-card elevation="0">
          <v-data-iterator
            v-if="results"
            :items="results"
            :loading="loading"
            :page="page"
            :items-per-page="30"
          >
            <template v-slot:default="props">
              <v-row no-gutters>
                <v-col
                  v-for="item in props.items"
                  :key="item.raw.person_id"
                  cols="12"
                  class="pa-1"
                >
                  <people-search-result :person-id="item.raw.person_id" />
                </v-col>
              </v-row>
            </template>
            <template v-slot:footer="{ pageCount }">
              <v-pagination v-model="page" :length="pageCount" />
            </template>
          </v-data-iterator>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
