<script setup>
import { nextTick, onMounted, ref, watch } from 'vue'
import { inject } from 'vue'

import TopBar from '@/components/TopBar.vue'
import StructuresSearchResult from '@/components/StructuresSearchResult.vue'

const axiosSecure = inject('axiosSecure')

const search = ref({
  params: {
    structure_id: '',
    pah: '',
    structure_class: null,
    structure_type: null,
    land_zone: null,
    protected: null,
    followup_flag: null,
    has_replacement: null,
  }
})

const options = ref({})
const loading = ref(false)
const downloading = ref(false)
const error = ref('')
const page = ref(1)
const results = ref([])

const STORAGE_KEY = 'structure_search_state'

function saveSearchState () {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ params: search.value.params }))
}

function restoreSearchState () {
  const saved = localStorage.getItem(STORAGE_KEY)
  if (!saved) return
  try {
    const { params } = JSON.parse(saved)
    search.value.params = params
  } catch {
    localStorage.removeItem(STORAGE_KEY)
  }
}

watch(() => search.value.params, saveSearchState, { deep: true })

let autoSearchReady = false

const autoSearchFields = [
  () => search.value.params.structure_class,
  () => search.value.params.structure_type,
  () => search.value.params.land_zone,
  () => search.value.params.protected,
  () => search.value.params.followup_flag,
  () => search.value.params.has_replacement,
]

watch(autoSearchFields, () => {
  if (autoSearchReady) doSearch()
})

const loadOptions = async () => {
  try {
    const response = await axiosSecure.get('/structures/options')
    options.value = response.data
  } catch (err) {
    console.error('Failed to load structure options:', err)
  }
}

function sanitizePah () {
  const val = (search.value.params.pah || '').trim()
  if (!val) return
  const digits = val.replace(/^PAH0*/i, '').replace(/\D/g, '') || val.replace(/\D/g, '')
  if (digits) {
    search.value.params.pah = 'PAH' + digits.padStart(3, '0')
  }
}

function sanitizeStr () {
  const val = (search.value.params.structure_id || '').trim()
  if (!val) return
  const digits = val.replace(/^STR0*/i, '').replace(/\D/g, '') || val.replace(/\D/g, '')
  if (digits) {
    search.value.params.structure_id = 'STR' + digits.padStart(3, '0')
  }
}

function doSearch () {
  loading.value = true
  error.value = ''
  results.value = []

  axiosSecure.post('/structures_search', search.value.params)
    .then(response => {
      results.value = response.data
    })
    .catch(err => {
      console.error('Search failed:', err)
      error.value = 'An error occurred while searching. Please try again.'
    })
    .finally(() => {
      loading.value = false
    })
}

function clearSearch () {
  localStorage.removeItem(STORAGE_KEY)
  search.value.params = {
    structure_id: '',
    pah: '',
    structure_class: null,
    structure_type: null,
    land_zone: null,
    protected: null,
    followup_flag: null,
    has_replacement: null,
  }
}

function downloadCsv () {
  downloading.value = true
  axiosSecure.post('/structures_export', search.value.params, { responseType: 'blob' })
    .then(response => {
      const url = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }))
      const link = document.createElement('a')
      link.href = url
      const name = `${new Date().toISOString().slice(0, 10)}_structures_export.csv`
      link.setAttribute('download', name)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
    })
    .catch(err => {
      console.error('Export failed:', err)
    })
    .finally(() => {
      downloading.value = false
    })
}

onMounted(() => {
  restoreSearchState()
  loadOptions()
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
          <v-col cols="12" md="8">
            <h1 class="text-h4 mb-2">Structures</h1>
          </v-col>
        </v-row>
        <v-card class="mb-4" elevation="1">
          <v-card-text>
            <v-row>
              <v-col cols="12">
                <strong>Search:</strong>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="3">
                <v-text-field
                  density="compact"
                  hide-details
                  v-model="search.params.structure_id"
                  label="STR ID"
                  placeholder="Structure ID"
                  prepend-inner-icon="mdi-magnify"
                  clearable
                  @blur="sanitizeStr"
                  @keyup.enter="sanitizeStr(); doSearch()"
                />
              </v-col>

              <v-col cols="12" md="3">
                <v-text-field
                  density="compact"
                  hide-details
                  v-model="search.params.pah"
                  label="PAH"
                  placeholder="PAH No"
                  prepend-inner-icon="mdi-magnify"
                  clearable
                  @blur="sanitizePah"
                  @keyup.enter="sanitizePah(); doSearch()"
                />
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="3">
                <v-select
                  density="compact"
                  hide-details
                  v-model="search.params.structure_class"
                  :items="options.structure_class"
                  label="Class"
                  placeholder="Any"
                  clearable
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-select
                  density="compact"
                  hide-details
                  v-model="search.params.structure_type"
                  :items="options.structure_type"
                  label="Type"
                  placeholder="Any"
                  clearable
                />
              </v-col>
              <v-col cols="12" md="3">
                <v-select
                  density="compact"
                  hide-details
                  v-model="search.params.land_zone"
                  :items="options.land_zone"
                  label="Zone"
                  placeholder="Any"
                  clearable
                />
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12">
                <strong>Flags:</strong>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" class="d-flex flex-wrap align-center ga-4">
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.protected"
                    label="Protected"
                    hide-details
                    :indeterminate="search.params.protected === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="search.params.protected = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.followup_flag"
                    label="Follow-Up Flag"
                    hide-details
                    :indeterminate="search.params.followup_flag === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="search.params.followup_flag = null"
                  />
                </div>
                <div class="d-flex align-center ga-1 bg-grey-lighten-4 rounded">
                  <v-checkbox
                    v-model="search.params.has_replacement"
                    label="Has Replacement"
                    hide-details
                    :indeterminate="search.params.has_replacement === null"
                    density="comfortable"
                  />
                  <v-btn
                    icon="mdi-close-circle"
                    color="grey"
                    size="x-small"
                    variant="text"
                    @click="search.params.has_replacement = null"
                  />
                </div>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="6">
                {{ results.length }} result(s) found.
              </v-col>
              <v-col cols="6" class="d-flex align-center ga-2 justify-end">
                <v-btn color="primary" append-icon="mdi-close" @click="clearSearch">Clear</v-btn>
                <v-btn color="primary" :loading="loading" append-icon="mdi-magnify" @click="doSearch">Search</v-btn>
                <v-btn color="primary" :loading="downloading" append-icon="mdi-download" @click="downloadCsv">Download</v-btn>
              </v-col>
            </v-row>

            <v-alert v-if="error" type="error" variant="tonal" class="mt-2">
              {{ error }}
            </v-alert>
          </v-card-text>
        </v-card>

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
                  :key="item.raw.structure_id"
                  cols="12"
                  class="pl-1 pr-1 pt-1 pb-1"
                >
                  <structures-search-result :structure-id="item.raw.structure_id" />
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
