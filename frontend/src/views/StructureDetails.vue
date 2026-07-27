<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import MapLink from '@/components/MapLink.vue'
import TableCopyFooter from '@/components/TableCopyFooter.vue'
import { formatCurrency, formatYesNo } from '@/utils/formatters'

const axiosSecure = inject('axiosSecure')
const route = useRoute()

const structure = ref(null)
const loading = ref(false)
const error = ref('')
const togglingFlag = ref(false)

const id = computed(() => String(route.params.id || '').trim())

const parseLatLon = (obj) => {
  if (!obj?.centroid) return { lat: null, lon: null }
  try {
    const geojson = typeof obj.centroid === 'string' ? JSON.parse(obj.centroid) : obj.centroid
    const [lon, lat] = geojson.coordinates
    return { lat, lon }
  } catch {
    return { lat: null, lon: null }
  }
}

const latLon = computed(() => parseLatLon(structure.value))

async function toggleFollowupFlag () {
  togglingFlag.value = true
  try {
    const newVal = !structure.value.followup_flag
    await axiosSecure.patch(`/structures/${id.value}`, { followup_flag: newVal })
    structure.value = { ...structure.value, followup_flag: newVal }
  } catch (err) {
    console.error('Failed to toggle followup flag:', err)
    error.value = 'Failed to update followup flag.'
  } finally {
    togglingFlag.value = false
  }
}

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get(`/structures/${id.value}`)
    structure.value = response.data
  } catch (err) {
    console.error('Failed to load structure:', err)
    error.value = 'An error occurred while loading the structure.'
  } finally {
    loading.value = false
  }
}

onMounted(() => { load() })
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row class="mb-4" align="center">
          <v-col>
            <h1 class="text-h4 mb-2">Structure: {{ id }}</h1>
          </v-col>
        </v-row>

        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>

        <v-progress-circular v-if="loading" indeterminate class="d-block mx-auto my-6" />

        <v-card v-if="structure" elevation="1">
          <v-card-title class="d-flex align-center">
            <span>{{ structure.structure_class }} — <strong>{{ structure.structure_type }}</strong></span>
            <MapLink :lat="latLon.lat" :lon="latLon.lon" />
            <v-spacer />
            <v-chip color="blue" class="mr-2" v-if="structure.protected">Protected</v-chip>
            <v-btn
              :color="structure.followup_flag ? 'purple' : 'grey'"
              :variant="structure.followup_flag ? 'tonal' : 'outlined'"
              size="small"
              :loading="togglingFlag"
              @click="toggleFollowupFlag"
            >
              {{ structure.followup_flag ? 'Flagged' : 'Flag' }}
            </v-btn>
          </v-card-title>
          <v-card-text>
            <v-row>
              <v-col cols="12" sm="6">
                <div class="mb-1">
                  <strong>PAH:</strong>
                  <router-link :to="`/households/${structure.pah}`" class="ml-1">{{ structure.pah }}</router-link>
                </div>
                <div class="mb-1" v-if="structure.secondary_description"><strong>Description:</strong> <span class="table-value">{{ structure.secondary_description }}</span></div>
                <div class="mb-1" v-if="structure.rooms && structure.rooms > 0"><strong>Rooms:</strong> <span class="table-value">{{ structure.rooms }}</span></div>
                <div class="mb-1"><strong>Dimensions:</strong> <span class="table-value">{{ structure.dimensions }}sqm</span></div>
                <div class="mb-1" v-if="structure.secondary_rate"><strong>Rate:</strong> <span class="table-value">K{{ structure.secondary_rate }}/sqm</span></div>
                <div class="mb-1"><strong>Value:</strong> <span class="table-value">K{{ formatCurrency(structure.structure_value) }}</span></div>
                <div class="mb-1"><strong>Zone:</strong> <span class="table-value">{{ structure.land_zone || '—' }}</span></div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="mb-1">
                  <strong>Replacement Structure:</strong>
                  <router-link v-if="structure.replacement_structure_id" :to="`/replacements/${structure.replacement_structure_id}`" class="ml-1">{{ structure.replacement_structure_id }}</router-link>
                  <span v-else class="table-value ml-1">—</span>
                </div>
                <div class="mb-1" v-if="structure.replacement_class"><strong>Replacement Class:</strong> <span class="table-value">{{ structure.replacement_class }}</span></div>
                <div class="mb-1" v-if="structure.replacement_option"><strong>Replacement Option:</strong> <span class="table-value">{{ structure.replacement_option }}</span></div>
                <div class="mb-1" v-if="structure.owner_tenant"><strong>Owner/Tenant:</strong> <span class="table-value">{{ structure.owner_tenant }}</span></div>
                <div class="mb-1" v-if="structure.owner_name"><strong>Owner Name:</strong> <span class="table-value">{{ structure.owner_name }}</span></div>
                <div class="mb-1"><strong>Protected:</strong> <span class="table-value">{{ formatYesNo(structure.protected) }}</span></div>
              </v-col>
            </v-row>

            <v-row v-if="!structure.secondary_rate">
              <v-col cols="12" md="6">
                <v-table density="compact">
                  <thead>
                    <tr>
                      <th class="table-heading"></th>
                      <th class="table-heading">Type</th>
                      <th class="table-heading">No</th>
                      <th class="table-heading">Rate</th>
                      <th class="table-heading">Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="structure.roof_value > 0">
                      <td>Roof</td>
                      <td>{{ structure.roof_type }}</td>
                      <td></td>
                      <td>{{ structure.roof_rate }}</td>
                      <td>K{{ formatCurrency(structure.roof_value) }}</td>
                    </tr>
                    <tr v-if="structure.wall_value > 0">
                      <td>Walls</td>
                      <td>{{ structure.walls_type }}</td>
                      <td></td>
                      <td>{{ structure.walls_rate }}</td>
                      <td>K{{ formatCurrency(structure.wall_value) }}</td>
                    </tr>
                    <tr v-if="structure.floor_value > 0">
                      <td>Floor</td>
                      <td>{{ structure.floor_type }}</td>
                      <td></td>
                      <td>{{ structure.floor_rate }}</td>
                      <td>K{{ formatCurrency(structure.floor_value) }}</td>
                    </tr>
                    <tr v-if="structure.door_value > 0">
                      <td>Doors</td>
                      <td>{{ structure.doors_type }}</td>
                      <td>{{ structure.doors }}</td>
                      <td>{{ structure.doors_rate }}</td>
                      <td>K{{ formatCurrency(structure.door_value) }}</td>
                    </tr>
                    <tr v-if="structure.window_value > 0">
                      <td>Windows</td>
                      <td>{{ structure.windows_type }}</td>
                      <td>{{ structure.windows }}</td>
                      <td>{{ structure.windows_rate }}</td>
                      <td>K{{ formatCurrency(structure.window_value) }}</td>
                    </tr>
                    <tr class="table-total">
                      <td colspan="4">Total</td>
                      <td class="table-value">K{{ formatCurrency(structure.structure_value) }}</td>
                    </tr>
                  </tbody>
                  <TableCopyFooter :colspan="5" />
                </v-table>
              </v-col>
            </v-row>

            <v-row v-if="structure.data_notes">
              <v-col cols="12">
                <div class="d-flex align-start ga-2">
                  <v-icon icon="mdi-note-text" size="small" color="grey" class="mt-1" />
                  <span class="text-body-2" style="white-space: pre-wrap;">{{ structure.data_notes }}</span>
                </div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
