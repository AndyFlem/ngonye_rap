<script setup>
import { inject, nextTick, onMounted, ref, watch } from 'vue'
import TopBar from '@/components/TopBar.vue'
import FishersSearchResult from '@/components/FishersSearchResult.vue'

const STORAGE_KEY = 'fisher_search_state'

const TYPE_OPTIONS = ['Limbelo', 'Maungwe', 'Both']
const ACTIVE_OPTIONS = ['Active', 'Inactive', 'N/A']
const SURVEY_PHASE_OPTIONS = [1, 2, 3, 4]

const defaultParams = () => ({
  nhs: '',
  name: '',
  nrc: '',
  type: null,
  survey_phase: null,
  social_survey: null,
  catch_survey: null,
  maungwe_active: null,
  limbelo_active: null,
  followup_flag: null,
  ica_signed: null,
  new_ica_required: null,
  has_multiple_icas: null,
  has_linked_household: null,
  has_notes: null,
  has_grievances: null
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
    const response = await axiosSecure.post('/fishers_search', search.value.params)
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
  axiosSecure.post('/fishers_export', search.value.params, { responseType: 'blob' })
    .then(response => {
      const url = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }))
      const link = document.createElement('a')
      link.href = url
      const name = `${new Date().toISOString().slice(0, 10)}_fishers_export.csv`
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
  () => search.value.params.type,
  () => search.value.params.survey_phase,
  () => search.value.params.social_survey,
  () => search.value.params.catch_survey,
  () => search.value.params.maungwe_active,
  () => search.value.params.limbelo_active,
  () => search.value.params.followup_flag,
  () => search.value.params.ica_signed,
  () => search.value.params.new_ica_required,
  () => search.value.params.has_multiple_icas,
  () => search.value.params.has_linked_household,
  () => search.value.params.has_notes,
  () => search.value.params.has_grievances
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
            <h1 class="text-h4">Fishers</h1>
          </v-col>
        </v-row>

        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.nhs"
                  label="NHS No" placeholder="NHS No"
                  prepend-inner-icon="mdi-magnify"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.name"
                  label="Name" placeholder="Enter name"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  density="compact" hide-details
                  v-model="search.params.nrc"
                  label="NRC" placeholder="Enter NRC"
                  clearable @keyup.enter="doSearch"
                />
              </v-col>
            </v-row>
            <v-row class="mt-2">
              <v-col cols="12" md="3">
                <v-select
                  density="compact" hide-details
                  v-model="search.params.type"
                  :items="TYPE_OPTIONS"
                  label="Type" placeholder="Any"
                  clearable
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-select
                  density="compact" hide-details
                  v-model="search.params.maungwe_active"
                  :items="ACTIVE_OPTIONS"
                  label="Maungwe Active" placeholder="Any"
                  clearable
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-select
                  density="compact" hide-details
                  v-model="search.params.limbelo_active"
                  :items="ACTIVE_OPTIONS"
                  label="Limbelo Active" placeholder="Any"
                  clearable
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-select
                  density="compact" hide-details
                  v-model="search.params.survey_phase"
                  :items="SURVEY_PHASE_OPTIONS"
                  label="Survey Phase" placeholder="Any"
                  clearable
                />
              </v-col>
            </v-row>
            <v-row class="mt-4">
              <v-col cols="12" class="d-flex flex-wrap align-center ga-4">
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.ica_signed"
                    label="ICA Signed" hide-details
                    :indeterminate="search.params.ica_signed === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.ica_signed = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.new_ica_required"
                    label="New ICA Required" hide-details
                    :indeterminate="search.params.new_ica_required === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.new_ica_required = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.has_multiple_icas"
                    label="Has Multiple ICAs" hide-details
                    :indeterminate="search.params.has_multiple_icas === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.has_multiple_icas = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.has_linked_household"
                    label="Has Linked Household" hide-details
                    :indeterminate="search.params.has_linked_household === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.has_linked_household = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.has_notes"
                    label="Has Notes" hide-details
                    :indeterminate="search.params.has_notes === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.has_notes = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.has_grievances"
                    label="Has Grievances" hide-details
                    :indeterminate="search.params.has_grievances === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.has_grievances = null"
                  />
                </div>
              </v-col>
              <v-col cols="12" class="d-flex flex-wrap align-center ga-4">
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.social_survey"
                    label="Social Survey" hide-details
                    :indeterminate="search.params.social_survey === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.social_survey = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.catch_survey"
                    label="Catch Survey" hide-details
                    :indeterminate="search.params.catch_survey === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.catch_survey = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded px-2">
                  <v-checkbox
                    v-model="search.params.followup_flag"
                    label="Flagged" hide-details
                    :indeterminate="search.params.followup_flag === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle" color="grey" size="x-small"
                    variant="text" @click="search.params.followup_flag = null"
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
                  :key="item.raw.nhs"
                  cols="12"
                  class="pa-1"
                >
                  <fishers-search-result :nhs="item.raw.nhs" />
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
