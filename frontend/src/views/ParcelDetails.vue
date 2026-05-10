<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import { formatArea, formatCurrency, formatYesNo } from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()

const parcel = ref(null)
const assets = ref([])
const loading = ref(false)
const error = ref('')

const id = computed(() => String(route.params.id || '').trim())

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const [parcelRes, assetsRes] = await Promise.all([
      axiosSecure.get(`/parcels/${id.value}`),
      axiosSecure.get(`/parcels/${id.value}/assets`),
    ])
    parcel.value = parcelRes.data
    assets.value = Array.isArray(assetsRes.data) ? assetsRes.data : []
  } catch (err) {
    console.error('Failed to load land parcel:', err)
    error.value = 'An error occurred while loading the land parcel.'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row class="mb-4" align="center">
          <v-col>
            <h1 class="text-h4 mb-2">Land Parcel: {{ id }}</h1>
          </v-col>
        </v-row>

        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>

        <v-progress-circular v-if="loading" indeterminate class="d-block mx-auto my-6" />

        <v-card v-if="parcel" elevation="1">
          <v-card-title class="d-flex align-center">
            <span>{{ parcel.land_class }}{{ parcel.land_zone ? ' / ' + parcel.land_zone : '' }}</span>
            <v-spacer />
            <v-chip color="green" class="mr-2" v-if="parcel.cultivated">Cultivated</v-chip>
            <v-chip color="red" v-if="parcel.remaining_viable === false">Not Viable</v-chip>
          </v-card-title>
          <v-card-text>
            <v-row>
              <v-col cols="12" sm="6">
                <div class="mb-1">
                  <strong>PAH:</strong>
                  <router-link :to="`/households/${parcel.pah}`" class="ml-1">{{ parcel.pah }}</router-link>
                </div>
                <div class="mb-1">
                  <person-view :readonly="true" :person-id="parcel.householdhead_id" title="Head of Household:" />
                </div>
                <div class="mb-1" v-if="parcel.village"><strong>Village:</strong> <span class="table-value">{{ parcel.village }}</span></div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="mb-1"><strong>Land Class:</strong> <span class="table-value">{{ parcel.land_class || '—' }}</span></div>
                <div class="mb-1"><strong>Land Zone:</strong> <span class="table-value">{{ parcel.land_zone || '—' }}</span></div>
                <div class="mb-1"><strong>Cultivated:</strong> <span class="table-value">{{ formatYesNo(parcel.cultivated) }}</span></div>
                <div class="mb-1"><strong>Remaining Viable:</strong> <span class="table-value">{{ formatYesNo(parcel.remaining_viable) }}</span></div>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" sm="6">
                <div class="mb-1" v-if="parcel.area_sqm"><strong>Area:</strong> <span class="table-value">{{ formatArea(parcel.area_sqm) }}</span></div>
                <div class="mb-1" v-if="parcel.area_acquired"><strong>Area Acquired:</strong> <span class="table-value">{{ formatArea(parcel.area_acquired) }}</span></div>
                <div class="mb-1" v-if="parcel.replacement_land_area"><strong>Replacement Land Area:</strong> <span class="table-value">{{ formatArea(parcel.replacement_land_area) }}</span></div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="mb-1" v-if="parcel.cash_cost_total"><strong>Cash Cost Total:</strong> <span class="table-value">K{{ formatCurrency(parcel.cash_cost_total) }}</span></div>
              </v-col>
            </v-row>
            <v-row v-if="parcel.qaqc_note || parcel.qaqc_action">
              <v-col cols="12">
                <div v-if="parcel.qaqc_note" class="mb-1"><strong>QAQC Note:</strong> <span class="table-value">{{ parcel.qaqc_note }}</span></div>
                <div v-if="parcel.qaqc_action" class="mb-1"><strong>QAQC Action:</strong> <span class="table-value">{{ parcel.qaqc_action }}</span></div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <v-card v-if="assets.length > 0" elevation="1" class="mt-4">
          <v-card-title>Land Assets</v-card-title>
          <v-card-text>
            <v-table density="compact">
              <thead>
                <tr>
                  <th>Asset ID</th>
                  <th>Impact</th>
                  <th>Compensation Option</th>
                  <th>Area / Detail</th>
                  <th>Value</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="asset in assets" :key="asset.land_asset_id" class="asset-row">
                  <td>{{ asset.land_asset_id }}</td>
                  <td>{{ asset.acquisition_class }}</td>
                  <td>{{ asset.compensation_option }}</td>
                  <template v-if="asset.acquisition_class === 'Permanent'">
                    <td>{{ formatArea(asset.area_sqm) }}<span v-if="asset.compensation_option !== '2: Land Allocation'"> @ K{{ asset.rate_acquisition }}/sqm</span></td>
                    <td v-if="asset.compensation_option === '2: Land Allocation'">Replacement Land: {{ formatArea(asset.replacement_land_area) }}</td>
                    <td v-else-if="asset.compensation_value > 0">K{{ formatCurrency(asset.compensation_value) }}</td>
                    <td v-else></td>
                  </template>
                  <template v-else-if="asset.acquisition_class === 'Temporary'">
                    <td>{{ formatArea(asset.area_sqm) }} @ K{{ asset.rate_lease }}/sqm/year — {{ asset.lease_years }} yrs</td>
                    <td>Lease Total: K{{ formatCurrency(asset.lease_cost_total) }}</td>
                  </template>
                  <template v-else>
                    <td>{{ formatArea(asset.area_sqm) }}</td>
                    <td></td>
                  </template>
                </tr>
              </tbody>
            </v-table>
          </v-card-text>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>

<style scoped>
.asset-row {
  font-size: 0.8rem;
  font-family: monospace;
  background-color: rgba(0, 0, 0, 0.02);
}
</style>
