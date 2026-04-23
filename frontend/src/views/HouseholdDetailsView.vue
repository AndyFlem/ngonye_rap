<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'



const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const pah = ref(null)
const parcels = ref([])
const structures = ref([])
const replacements = ref([])
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
  return 'No'
}

const isTrueValue = (value) => {
  if (value === true || value === 1) return true
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase()
    return normalized === 'true' || normalized === '1' || normalized === 'yes' || normalized === 'y'
  }
  return false
}

const getSafeExternalUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  if (/^https?:\/\//i.test(url)) return url
  return null
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

      const structuresResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/structures`)
      // Order structures by structure_class and then structure_type for consistent display
      structures.value = structuresResponse.data.sort((a, b) => {
        if (a.structure_class === b.structure_class) {
          return a.structure_type.localeCompare(b.structure_type)
        }
        return a.structure_class.localeCompare(b.structure_class)
      })
      structures.value = structuresResponse.data

      const replacementsResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/replacements`)
      replacements.value = Array.isArray(replacementsResponse.data) ? replacementsResponse.data : []

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
            {{ pahno }}&nbsp;<span v-if="pah">{{ pah.lastname }}, {{ pah.firstname }}{{ pah.middlename }}</span>
            <v-spacer/>
            <v-chip v-if="pah?.vulnerable" color="red" text-color="white">Vulnerable</v-chip>
          </v-card-title>
          <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />
          <v-card-text v-if="pah">
            <v-row>
              <v-col cols="12" md="6">
                <div><strong>Village:</strong> <span class="table-value">{{ pah?.village || 'none' }}</span></div>
                <div><strong>Contact:</strong> <span class="table-value">{{ pah?.contact || 'none' }}</span></div>
                <div><strong>NRC:</strong> <span class="table-value">{{ pah?.nrc || 'none' }}</span></div>
              </v-col>
            <v-col v-if="pah.cosignatory" cols="12" md="6">
                <div><strong>Cosignatory:</strong> <span class="table-value">{{ pah.cosignatory }}</span></div>
                <div><strong>Contact:</strong> <span class="table-value">{{ pah?.cosignatory_contact || 'none' }}</span></div>
                <div><strong>NRC:</strong> <span class="table-value">{{ pah?.cosignatory_nrc || 'none' }}</span></div>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12">
                <div :style="{ color: pah?.date_signed ? 'inherit' : 'red' }">
                  <strong>ICA Signature Date:</strong> <span class="table-value">{{ pah?.date_signed || 'not signed' }}</span>
                  <v-btn
                    v-if="getSafeExternalUrl(pah?.ica_link)"
                    :href="getSafeExternalUrl(pah?.ica_link)"
                    icon="mdi-open-in-new"
                    variant="text"
                    size="x-small"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="ml-2"
                    title="Open ICA link"
                  ></v-btn> Open ICA Link
                </div>
              </v-col>
            </v-row>            
            <v-row>
              <v-col cols="12" md="6">
                <div><strong>Physically Displaced: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.physically_displaced) }">{{ formatYesNo(pah.physically_displaced) }}</span></div>
                <div><strong>Landholding only: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.landholding_only) }">{{ formatYesNo(pah.landholding_only) }}</span></div>
                <div><strong>No ICA Required: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.no_ica_required) }">{{ formatYesNo(pah.no_ica_required) }}</span></div>
                <div><strong>New ICA Required: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.new_ica_required) }">{{ formatYesNo(pah.new_ica_required) }}</span></div>
                <div><strong>Non-affected: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.nonaffected) }">{{ formatYesNo(pah.nonaffected) }}</span></div>
                <div><strong>Is Silumesii: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.is_silumesii) }">{{ formatYesNo(pah.is_silumesii) }}</span></div>
                <div><strong>Flagged: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.followup_flag) }">{{ formatYesNo(pah.followup_flag) }}</span></div>
              </v-col>              
              <v-col cols="12" md="6">
                <div><strong>Cash Compensation:</strong> <span class="table-value">K{{ formatCurrency(pah.compensation?.total_cash_compensation || 0) }}</span></div>
                <div v-if="pah.replacement_land_area>0"><strong>Replacement Land:</strong> <span class="table-value">{{ formatArea(pah.replacement_land_area) }} ({{ pah.icaoption_landholding }})</span></div>
                <div v-if="pah.replacement_structures_value>0"><strong>Replacement Structures:</strong> <span class="table-value">{{ replacements.length }} <span>(K{{ formatCurrency(pah.replacement_structures_value) }})</span></span></div>                
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
                    <tr v-if="pah.compensation.secondary_structures_compensation_value > 0">
                      <td class="table-label">Secondary Structures</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.secondary_structures_compensation_value) }}</td>
                    </tr>
                    <tr v-if="pah.compensation.land_compensation_value > 0">
                      <td class="table-label">Permanent Land</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.land_compensation_value) }}</td>
                    </tr>
                    <tr v-if="pah.compensation.lease_cost_total > 0">
                      <td class="table-label">Lease Cost</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.lease_cost_total) }}</td>
                    </tr>
                    <tr v-if="pah.compensation.crop_value > 0">
                      <td class="table-label">Crops</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.crop_value) }}</td>
                    </tr>
                    <tr v-if="pah.compensation.trees_compensation > 0">
                      <td class="table-label">Trees</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.trees_compensation) }}</td>
                    </tr>
                    <tr v-if="pah.compensation.allowance_total > 0">
                      <td class="table-label">Allowances</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.allowance_total) }}</td>
                    </tr>                    
                    <tr class="table-total" v-if="pah.compensation.total_cash_compensation > 0">
                      <td class="table-label">Total</td>
                      <td class="table-value">K{{ formatCurrency(pah.compensation.total_cash_compensation) }}</td>
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
                                <td class="">{{ formatArea(asset.area_sqm) }}</td>
                                <td colspan="3"></td>
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
            <v-row v-if="replacements.length > 0" >
              <v-col cols="12">
                <v-table>
                  <thead>
                    <tr>
                      <th colspan="6" class="table-heading">Replacement Structures (location: {{ pah.icaoption_structure_location }})</th>
                    </tr>
                    <tr>
                      <th>ID</th>
                      <th>Structure ID</th>
                      <th>Class</th>
                      <th>Option</th>
                      <th>Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="replacement in replacements" :key="replacement.replacement_structure_id">
                      <td class="table-value left">{{ replacement.replacement_structure_id }}</td>
                      <td class="table-value left">{{ replacement.structure_id }}</td>
                      <td class="table-value left">{{ replacement.replacement_class }}</td>
                      <td class="table-value left">{{ replacement.replacement_option }}</td>
                      <td class="table-value left">K{{ formatCurrency(replacement.replacement_value) }}</td>
                    </tr>
                    <tr class="table-total">
                      <td class="table-value" colspan="5">
                        K{{ formatCurrency(pah.replacement_structures_value) }}
                      </td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>
            <v-row v-if="structures.length > 0" class="mt-4">
              <v-col cols="12">
                <v-card>
                  <v-card-title class="table-heading card-heading">Structures ({{ structures.length }})</v-card-title>
                  <v-card-text>
                    <v-expansion-panels>
                      <v-expansion-panel
                        v-for="structure in structures"
                        :key="structure.structure_id"
                        class="mt-1 mb-0"
                      >
                        <v-expansion-panel-title class="">
                          <div class="structure-panel-title">
                            <span>{{ structure.structure_id }} </span>&nbsp;
                            <span>{{ structure.structure_class }}</span> - <span><strong>{{ structure.structure_type }}</strong></span>
                          </div>
                          <v-spacer/>
                          <span class="pr-5" v-if="structure.replacement_structure_id">
                            <span class="table-value highlight">{{ structure.replacement_structure_id }}</span>
                          </span>
                          <span class="pr-5 table-value" v-else>K{{ formatCurrency(structure.structure_value) }}</span>
                        </v-expansion-panel-title>
                        <v-expansion-panel-text>
                          <v-row no-gutters>
                            <v-col cols="12" md="6">
                              <div v-if="structure.secondary_description"><strong>Description:</strong> <span class="table-value">{{ structure.secondary_description }}</span></div>
                              <div v-if="structure.rooms && structure.rooms>0"><strong>Rooms:</strong> <span class="table-value">{{ structure.rooms }}</span></div>
                              <div><strong>Dimensions:</strong> <span class="table-value">{{ structure.dimensions }}sqm</span></div>
                              <div v-if="structure.secondary_rate"><strong>Rate:</strong> <span class="table-value">K{{ structure.secondary_rate }}/sqm</span></div>
                              <div><strong>Value:</strong> <span class="table-value">K{{ formatCurrency(structure.structure_value) }}</span></div>
                              <div><strong>Zone:</strong> <span class="table-value">{{ structure.land_zone }}</span></div>
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
                                  <tr v-if="structure.roof_value>0">
                                    <td>Roof</td>
                                    <td>{{ structure.roof_type }}</td>
                                    <td></td>
                                    <td>{{ structure.roof_rate }}</td>
                                    <td>K{{ formatCurrency(structure.roof_value) }}</td>
                                  </tr>
                                  <tr v-if="structure.wall_value>0">
                                    <td>Walls</td>
                                    <td>{{ structure.walls_type }}</td>
                                    <td></td>
                                    <td>{{ structure.walls_rate }}</td>
                                    <td>K{{ formatCurrency(structure.wall_value) }}</td>
                                  </tr>
                                  <tr v-if="structure.floor_value>0">
                                    <td>Floor</td>
                                    <td>{{ structure.floor_type }}</td>
                                    <td></td>
                                    <td>{{ structure.floor_rate }}</td>
                                    <td>K{{ formatCurrency(structure.floor_value) }}</td>
                                  </tr>
                                  <tr v-if="structure.door_value>0">
                                    <td>Doors</td>
                                    <td>{{ structure.door_type }}</td>
                                    <td>{{ structure.doors }}</td>
                                    <td>{{ structure.door_rate }}</td>
                                    <td>K{{ formatCurrency(structure.door_value) }}</td>
                                  </tr>
                                  <tr v-if="structure.window_value>0">
                                    <td>Windows</td>
                                    <td>{{ structure.window_type }}</td>
                                    <td>{{ structure.windows }}</td>
                                    <td>{{ structure.window_rate }}</td>
                                    <td>K{{ formatCurrency(structure.window_value) }}</td>
                                  </tr>
                                  <tr class="table-total">
                                    <td colspan="4">Total</td>
                                    <td class="table-value">K{{ formatCurrency(structure.structure_value)}}</td>
                                  </tr>
                                </tbody>
                              </v-table>
                            </v-col>
                          </v-row>
                        </v-expansion-panel-text>
                      </v-expansion-panel>
                    </v-expansion-panels>
                  </v-card-text>
                </v-card>
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
.left {
  text-align: left;
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

.structure-panel-title {
  width: 100%;
  gap: 6px;
}
.v-expansion-panel-title {
    padding: 0px 15px 0px 15px;
    min-height: 30px;
}
.card-heading {
  font-weight: 700;
  font-size: 0.92rem;
  padding: 3px 15px 3px 10px;
}

.highlight {
  background-color: rgba(255, 200, 200, 0.3);
  border-radius: 8px;
}

.highlight-true {
  background-color: rgba(255, 200, 200, 0.3);
  border-radius: 8px;
  padding: 0 6px;
}

</style>
