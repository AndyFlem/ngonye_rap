<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'



const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const pah = ref(null)
const parcels = ref([])
const loading = ref(false)
const error = ref('')

const pahno = computed(() => String(route.params.pah || '').trim())

const formatCurrency = (value) => {
  if (value == null || isNaN(value)) return '0'
  return Math.round(Number(value)).toLocaleString('en-US')
}
const formatArea = (value) => {
  if (value == null || isNaN(value)) return '0'
  return Math.round(Number(value)).toLocaleString('en-US') + ' sqm'
}


const hasIcaOption = (value) => {
  if (value === null || value === undefined) return false
  if (typeof value === 'boolean') return value
  if (typeof value === 'number') return value > 0
  const normalized = String(value).trim().toLowerCase()
  return normalized !== '' && normalized !== '0' && normalized !== 'false' && normalized !== 'no'
}

const formatIcaOption = (value) => {
  if (typeof value === 'boolean') return value ? 'Yes' : 'No'
  return String(value)
}

const formatYesNo = (value) => {
  if (value === true) return 'Yes'
  if (value === false) return 'No'
  return 'N/A'
}

const loadHousehold = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}`)
    pah.value = response.data || null

    // load the land parcels for this PAH
    if (pah.value) {
      const parcelsResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/parcels`)
      parcels.value = Array.isArray(parcelsResponse.data) ? parcelsResponse.data : []
    }

  } catch (err) {
    error.value = 'Failed to load pah details.'
    console.error('Failed to load pah details:', err)
  } finally {
    loading.value = false
  }
}

const goBack = () => {
  router.back()
}

onMounted(() => {
  loadHousehold()
})
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">


        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">
          {{ error }}
        </v-alert>

        <v-card elevation="1">
          <v-card-title class="d-flex">
            {{ pahno }} {{ pah?.household_head || '' }}
            <v-spacer/>
            <v-chip v-if="pah?.vulnerable" color="red" text-color="white">Vulnerable</v-chip>
          </v-card-title>
          <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />
          <v-card-text v-if="pah">
            <v-row>
              <v-col cols="12">
                <p :style="{ color: pah?.date_signed ? 'inherit' : 'red' }">
                  <strong>ICA Signature Date:</strong> <span class="table-value">{{ pah?.date_signed || 'not signed' }}</span>
                </p>
                <p v-if="pah.physically_displaced"><strong>Physically Displaced: </strong><span class="table-value">{{ pah.physically_displaced }}</span></p>
                <p v-if="pah.no_ica_required"><strong>No ICA Required: </strong><span class="table-value">{{ pah.no_ica_required }}</span></p>
                <p v-if="pah.nonaffected"><strong>Non-affected: </strong><span class="table-value">{{ pah.nonaffected }}</span></p>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="6">
                <p><strong>Village:</strong> <span class="table-value">{{ pah?.village || 'none' }}</span></p>
                <p><strong>Contact:</strong> <span class="table-value">{{ pah?.contact || 'none' }}</span></p>
                <p><strong>NRC:</strong> <span class="table-value">{{ pah?.nrc || 'none' }}</span></p>
              </v-col>
            <v-col v-if="pah.cosignatory" cols="12" md="6">
                <p><strong>Cosignatory:</strong> <span class="table-value">{{ pah.cosignatory }}</span></p>
                <p><strong>Contact:</strong> <span class="table-value">{{ pah?.cosignatory_contact || 'none' }}</span></p>
                <p><strong>NRC:</strong> <span class="table-value">{{ pah?.cosignatory_nrc || 'none' }}</span></p>
              </v-col>
            </v-row>
            <v-row class="pb-5">
              <v-col cols="12" md="6" lg="4">
                <v-table v-if="pah" density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Compensation</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="pah.secondary_structures_compensation_value > 0">
                      <td class="table-label">Secondary Structures</td>
                      <td class="table-value">K{{ formatCurrency(pah.secondary_structures_compensation_value) }}</td>
                    </tr>
                    <tr v-if="pah.permanent_land_value > 0">
                      <td class="table-label">Permanent Land</td>
                      <td class="table-value">K{{ formatCurrency(pah.permanent_land_value) }}</td>
                    </tr>
                    <tr v-if="pah.lease_cost_total > 0">
                      <td class="table-label">Lease Cost</td>
                      <td class="table-value">K{{ formatCurrency(pah.lease_cost_total) }}</td>
                    </tr>
                    <tr v-if="pah.crop_value > 0">
                      <td class="table-label">Crops</td>
                      <td class="table-value">K{{ formatCurrency(pah.crop_value) }}</td>
                    </tr>
                    <tr v-if="pah.trees_compensation > 0">
                      <td class="table-label">Trees</td>
                      <td class="table-value">K{{ formatCurrency(pah.trees_compensation) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_total">
                      <td class="table-label">Total</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_total) }}</td>
                    </tr>

                  </tbody>
                </v-table>
              </v-col>
              <v-col cols="12" md="6" lg="4">
                <v-table v-if="pah" density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Allowances</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="pah.allowance_disturbance > 0">
                      <td class="table-label">Disturbance</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_disturbance) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_transport > 0">
                      <td class="table-label">Transport</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_transport) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_transitional > 0">
                      <td class="table-label">Transitional</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_transitional) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_business > 0">
                      <td class="table-label">Business</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_business) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_rental > 0">
                      <td class="table-label">Rental</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_rental) }}</td>
                    </tr>
                    <tr v-if="pah.allowance_landprep > 0">
                      <td class="table-label">Land Prep</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_landprep) }}</td>
                    </tr>
                    <tr class="table-total">
                      <td class="table-label">Total</td>
                      <td class="table-value">K{{ formatCurrency(pah.allowance_total) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="6" lg="4">
                <v-table v-if="pah" density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">ICA Options</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="hasIcaOption(pah.icaoption_primary_structure)">
                      <td class="table-label">Primary Structure</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_primary_structure) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.icaoption_landholding)">
                      <td class="table-label">Landholding</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_landholding) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.icaoption_structure_location)">
                      <td class="table-label">Structure Location</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_structure_location) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.icaoption_dryland)">
                      <td class="table-label">Dryland</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_dryland) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.icaoption_garden)">
                      <td class="table-label">Garden</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_garden) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.icaoption_transport)">
                      <td class="table-label">Transport</td>
                      <td class="table-value">{{ formatIcaOption(pah.icaoption_transport) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
              <v-col cols="12" md="6" lg="4">
                <v-table v-if="pah" density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Livelihood Restoration Options</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="hasIcaOption(pah.lr_agricultural)">
                      <td class="table-label">Agricultural</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_agricultural) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.lr_livestock)">
                      <td class="table-label">Livestock</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_livestock) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.lr_water)">
                      <td class="table-label">Water</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_water) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.lr_fisheries)">
                      <td class="table-label">Fisheries</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_fisheries) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.lr_reedbeds)">
                      <td class="table-label">Reedbeds</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_reedbeds) }}</td>
                    </tr>
                    <tr v-if="hasIcaOption(pah.lr_agricultureinputs)">
                      <td class="table-label">Agriculture Inputs</td>
                      <td class="table-value">{{ formatIcaOption(pah.lr_agricultureinputs) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>

            <v-row v-if="parcels.length > 0" class="mt-4">
              <v-col cols="12">
                <v-table density="compact">
                  <thead>
                    <tr>
                      <th colspan="9" class="table-heading">Land</th>
                    </tr>
                    <tr>
                      <th>ID</th>
                      <th>Land Class</th>
                      <th>Zone</th>
                      <th>Cultivated</th>
                      <th>Area (sqm)</th>
                      <th>Acquired (sqm)</th>
                      <th>Compensation / Acquisition</th>
                      <th>Cost</th>
                      <th>Replacement Land</th>
                    </tr>
                  </thead>
                  <tbody>
                    <template v-for="parcel in parcels" :key="parcel.land_parcel_id">
                      <tr class="parcel-row">
                        <td>{{ parcel.land_parcel_id }}</td>
                        <td>{{ parcel.land_class || 'N/A' }}</td>
                        <td>{{ parcel.land_zone || 'N/A' }}</td>
                        <td>{{ formatYesNo(parcel.cultivated) }}</td>
                        <td class="">{{ formatArea(parcel.area_sqm) }}</td>
                        <td class="">{{ formatArea(parcel.area_acquired) }}</td>
                        <td>{{ parcel.remaining_viable === false ? 'Remaining not viable' : 'Remaining viable / N/A' }}</td>
                        <td class="">K{{ formatCurrency(parcel.cash_cost_total) }}</td>
                        <td class="">{{ formatArea(parcel.replacement_land_area) }}</td>
                      </tr>
                      <tr>
                        <td colspan="8">
                          <v-table density="compact">
                            <tr
                              v-for="asset in parcel.assets"
                              :key="asset.land_asset_id"
                              class="asset-row"
                            >
                              <td>{{  asset.land_asset_id }}</td>
                              <td>Impact: {{ asset.acquisition_class }}</td>
                              <td>{{ asset.compensation_option }}</td>

                              <template v-if="asset.acquisition_class=='Permanent'">
                                <td class="">{{ formatArea(asset.area_sqm) }} <span v-if="asset.compensation_option!='2: Land Allocation'">@ K{{ asset.rate_acquisition }}/sqm</span></td>
                                <td></td>
                                <td></td>
                                <td v-if="asset.compensation_option=='2: Land Allocation'">Replacement Land: {{ formatArea(asset.area_sqm) }}</td>
                                <td v-else-if="asset.compensation_value>0">Acquisition Cost: K{{ formatCurrency(asset.compensation_value) }}</td>
                              </template>
                              <template v-if="asset.acquisition_class=='Temporary'">
                                <td class="">{{ formatArea(asset.area_sqm) }} @ K{{ asset.rate_lease }}/sqm/year</td>
                                <td>K{{ asset.lease_cost }}/year</td>
                                <td>{{ asset.lease_years }} years</td>
                                <td class="">Lease Cost: K{{ formatCurrency(asset.lease_cost_total) }}</td>
                              </template>
                              <template v-if="asset.acquisition_class=='None'">
                                <td colspan="4"></td>
                              </template>
                            </tr>
                          </v-table>
                        </td>
                      </tr>
                    </template>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>
          </v-card-text>
          <v-card-actions>
            <v-btn color="primary" @click="goBack">Back to Households</v-btn>
          </v-card-actions>
        </v-card>

      </v-container>
    </v-main>
  </div>
</template>

<style scoped>


.table-label {
  font-weight: 500;
  width: 40%;
}

.table-value {
  text-align: right;
  font-family: monospace;
}

.table-total {
  background-color: rgba(25, 118, 210, 0.1);
  font-weight: 600;
}

.table-total .table-value {
  color: rgb(25, 118, 210);
}

.parcel-row {
  font-weight: 600;
  background-color: rgba(25, 210, 133, 0.06);
}
.asset-row {
  font-size: small;
  font-family: monospace;
}
.asset-row td:first-child {
  padding: 0 8px;
}
</style>
