<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import { formatCurrency, formatArea, formatYesNo, formatDateTime } from '@/utils/formatters'
import TableCopyFooter from '@/components/TableCopyFooter.vue'
import PersonView from '@/components/PersonView.vue'
import Notes from '@/components/Notes.vue'
import Icas from '@/components/Icas.vue'
import Grievances from '@/components/Grievances.vue'
import MapLink from '@/components/MapLink.vue'
import Members from '@/components/HouseholdMembers.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const pah = ref(null)
const pah_survey = ref(null)
const parcels = ref([])
const structures = ref([])
const replacements = ref([])
const trees = ref([])
const crops = ref([])
const graves = ref([])
const loading = ref(false)
const error = ref('')
const tab = ref('ica')

const villages = ref([])
const editingVillage = ref(false)
const draftVillageId = ref(null)
const savingVillage = ref(false)
const editingDuplicatePah = ref(false)
const draftDuplicatePah = ref('')
const savingDuplicatePah = ref(false)

const icaOptionChoices = [
  { title: 'None', value: null },
  { title: '1: Self-Source', value: '1: Self-Source' },
  { title: '2: Land Allocation', value: '2: Land Allocation' },
  { title: '3: Cash Compensation', value: '3: Cash Compensation' }
]
const editingIcaOption = ref(null)
const draftIcaOption = ref(null)
const savingIcaOption = ref(false)
const togglingFlag = ref(false)
const downloadingCert = ref(false)
const householdNotes = ref(null)

async function downloadCertificate () {
  downloadingCert.value = true
  try {
    const response = await axiosSecure.get(
      `/households/${encodeURIComponent(pahno.value)}/certificate`,
      { responseType: 'blob' }
    )
    const url = URL.createObjectURL(response.data)
    const a = document.createElement('a')
    a.href = url
    const dateString = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    a.download = `${pahno.value} ${dateString} ${pah.value?.fullname}.docx`
    a.click()
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('Failed to download certificate:', err)
    error.value = 'Failed to generate certificate.'
  } finally {
    downloadingCert.value = false
  }
}

async function toggleFollowupFlag () {
  togglingFlag.value = true
  try {
    const newVal = !pah.value.household_followup_flag
    await axiosSecure.patch(`/households/${encodeURIComponent(pahno.value)}`, { household_followup_flag: newVal })
    pah.value = { ...pah.value, household_followup_flag: newVal }
    householdNotes.value?.loadNotes()
  } catch (err) {
    console.error('Failed to toggle followup flag:', err)
    error.value = 'Failed to update followup flag.'
  } finally {
    togglingFlag.value = false
  }
}

function startEditVillage () {
  draftVillageId.value = pah.value?.village_id ?? null
  editingVillage.value = true
}

async function saveVillage () {
  savingVillage.value = true
  try {
    await axiosSecure.patch(`/households/${encodeURIComponent(pahno.value)}`, { village_id: draftVillageId.value })
    const selected = villages.value.find(v => v.village_id === draftVillageId.value)
    pah.value = { ...pah.value, village_id: draftVillageId.value, village: selected?.village ?? null }
    editingVillage.value = false
  } catch (err) {
    console.error('Failed to save village:', err)
    error.value = 'Failed to save village.'
  } finally {
    savingVillage.value = false
  }
}

function startEditDuplicatePah () {
  draftDuplicatePah.value = pah.value?.duplicate_pah ?? ''
  editingDuplicatePah.value = true
}

async function saveDuplicatePah () {
  savingDuplicatePah.value = true
  try {
    const val = draftDuplicatePah.value.trim() || null
    await axiosSecure.patch(`/households/${encodeURIComponent(pahno.value)}`, { duplicate_pah: val })
    pah.value = { ...pah.value, duplicate_pah: val }
    editingDuplicatePah.value = false
  } catch (err) {
    console.error('Failed to save duplicate_pah:', err)
    error.value = 'Failed to save Duplicate PAH.'
  } finally {
    savingDuplicatePah.value = false
  }
}


function startEditIcaOption (field) {
  draftIcaOption.value = pah.value?.[field] ?? null
  editingIcaOption.value = field
}

async function saveIcaOption (field) {
  savingIcaOption.value = true
  try {
    await axiosSecure.patch(`/households/${encodeURIComponent(pahno.value)}`, { [field]: draftIcaOption.value })
    pah.value = { ...pah.value, [field]: draftIcaOption.value }
    editingIcaOption.value = null
  } catch (err) {
    console.error(`Failed to save ${field}:`, err)
    error.value = 'Failed to save ICA option.'
  } finally {
    savingIcaOption.value = false
  }
}

const surveyFields = [
  ['pah', 'PAH No'],
  ['survey_date', 'Date and Time of Survey'],
  ['surveyor1', 'Name of Surveyor 1'],
  ['surveyor2', 'Name of Surveyor 2'],
  ['witness_name', 'Full name of neighbour witness'],
  ['hh_present', 'Are the household head/s present for this survey?'],
  ['hh_count', 'How many household heads are there for this family?'],
  ['respondent_lastname', 'Respondent Last Name'],
  ['respondent_middlename', 'Respondent Middle Name'],
  ['respondent_firstname', 'Respondent First Name'],
  ['respondent_relation', 'Relationship of Respondent to Household Head'],
  ['respondent_contact1', 'Respondent Mobile Number 1'],
  ['respondent_contact2', 'Respondent Mobile Number 2'],
  ['headperson', 'Headperson or Community Leader'],
  ['language', 'Home Language'],
  ['land_access', 'How did you get access to your household plot'],
  ['rent_amount', 'How much is your monthly rent'],
  ['residence_time', 'Length of time in residence'],
  ['residence_reason', 'Please select the reasons for moving to this land'],
  ['no_hospital_reason', 'If you do not use the local hospital, please indicate why not'],
  ['families', 'How many other families (nuclear) in your community do you rely on for support in a year?'],
  ['community_support', 'What support is given to or received from neighbours and the community'],
  ['water_drinking_source', 'Where does your household obtain water for drinking purposes?'],
  ['water_washing_source', 'Where does your household obtain water for washing household items (clothes, dishes)?'],
  ['energy_cook_source', 'What is the main energy source that your household uses to cook?'],
  ['energy_light_source', 'What is the main energy source that your household uses for light?'],
  ['washing', 'What is the principle personal washing facility used by your household?'],
  ['toilet', 'What is the principle toilet system used by your household?'],
  ['waste', 'What is the principle waste disposal system used by your household?'],
  ['diseases_year', 'Which diseases or ailments has any person in your household had in the last 12 months?'],
  ['medicine_source', 'Where does the household buy or obtain medicine from?'],
  ['births_year', 'How many children were born in the last 12 months, including any that may have died'],
  ['infant_death_year', 'Of those born in the last 12 months, how many died in their first year?'],
  ['deaths_year', 'How many members of your household, including infant children, died in the last 12 months'],
  ['death_reason', "Please indicate the causes of death or select 'Don't Know/Can't Say'"],
  ['hunger_months', 'Please indicate the months in which your household typically goes hungry in a year'],
  ['nets', 'Who in your family sleeps under a mosquito net?'],
  ['nets_no_reason', 'If anyone does not sleep under a net, why not?'],
  ['hiv_education', 'Has your household been educated about the disease HIV/AIDs?'],
  ['hiv_education_source', 'How do you usually receive information about HIV/AIDS?'],
  ['hiv_prevention', 'How do you prevent HIV/AIDS?'],
  ['farms_gardens_count', 'How many separate agricultural farms & gardens do you have inside the project area?'],
  ['plantations_count', 'How many plantations of economic trees do you own within the Project Area?'],
  ['trees_non_plantation', 'Do you have any freestanding economic trees that are not part of a plantation'],
  ['trees_total', 'Please enter the total of all trees captured'],
  ['business_activities', 'Select all business activities that your household is involved in that generate a regular monthly income for the household?'],
  ['grazing', 'Does your household use land for grazing'],
  ['grazing_owner', 'Who owns this grazing land'],
  ['graves_visit', 'Does your family visit the graves periodically?'],
  ['graves_option', 'Would you prefer to exhume and relocate the grave if it is impacted?'],
  ['graves_ceremony', 'In the event of these graves are impacted, what ceremonial requirements would your religion, tradition and/or culture require?'],
  ['graves_compensation', 'What form of compensation would be acceptable to your household for these graves?'],
  ['household_assets', 'Do you have any of the following available in your household in a working condition?'],
  ['resettlement_option', 'If given the choice to be resettled or not, what would you choose'],
  ['loss_opinion', 'In your opinion, what are some of the non-material things you stand to lose'],
  ['relocation_option', 'If you were to be relocated, what would your preference be'],
  ['relocation_area', 'Which existing village / town did you have in mind'],
  ['relocation_reason', 'Why would you prefer to move to this existing village/town'],
  ['relocation_disadvantage', 'What are the disadvantages of moving to this village/town'],
  ['newvillage_location', 'If you chose a new town/village, where would you suggest this new town/village be located'],
  ['newvillage_location_reason', 'Why would you prefer to move to this new village/town'],
  ['newvillage_location_disadvantages', 'What would the disadvantages be of moving to this new village/town'],
  ['resettlement_comments', 'Do you have any questions, comments or concerns regarding the potential resettlement that could be forwarded to Western Power for their consideration'],
  ['other_assets_concern', 'Do you own or make use of anything else in the Cut-Off Zone that you are concerned about? Please describe what it is?'],
  ['development_priorities', 'What are the top 3 development priorities of the household? Rank in terms of importance.'],
  ['members_count', 'Members Count'],
  ['members_confirmed', 'Members Confirmed'],
  ['members_list', 'Members List']
]

const pahno = computed(() => String(route.params.pah || '').trim())

const landOptions = computed(() => {
  if (!pah.value) return ''
  const options = [
    pah.value.icaoption_dryland,
    pah.value.icaoption_garden,
    pah.value.icaoption_landholding
  ].filter(opt => opt !== null && opt !== undefined && opt !== '')
  return [...new Set(options)].join(', ')
})

const isTrueValue = (value) => {
  if (value === true || value === 1) return true
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase()
    return normalized === 'true' || normalized === '1' || normalized === 'yes' || normalized === 'y'
  }
  return false
}

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


    if (pah.value) {
      // load any survey data for this PAH
      const surveyResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/survey`)
      pah_survey.value = surveyResponse.data || null

      // load the land parcels for this PAH
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

      const treesResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/trees`)
      trees.value = Array.isArray(treesResponse.data) ? treesResponse.data : []
      const cropsResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/crops`)
      crops.value = Array.isArray(cropsResponse.data) ? cropsResponse.data : []

      const gravesResponse = await axiosSecure.get(`/households/${encodeURIComponent(pahno.value)}/graves`)
      graves.value = Array.isArray(gravesResponse.data) ? gravesResponse.data : []

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

onMounted(async () => {
  loadHousehold()
  try {
    const r = await axiosSecure.get('/villages')
    villages.value = r.data
  } catch (err) {
    console.error('Failed to load villages:', err)
  }
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
            {{ pahno }}&nbsp;<span v-if="pah"> - {{ pah.fullname }}</span>
            <v-spacer/>
            
            <v-chip color="red" class="mr-2" size="small" v-if="pah && pah.vulnerable">
              Vulnerable
            </v-chip>
            <v-chip color="orange" class="mr-2" size="small" v-if="pah && pah.new_ica_required">
              New ICA Required
            </v-chip>
            <v-chip color="" class="mr-2" size="small" v-if="pah && pah.no_ica_required">
              ICA Not Required
            </v-chip>
            <v-chip color="" class="mr-2" size="small" v-if="pah && pah.nonaffected">
              Disturbance only
            </v-chip>
            <v-btn
              v-if="pah"
              :color="pah.household_followup_flag ? 'purple' : 'grey'"
              :variant="pah.household_followup_flag ? 'tonal' : 'outlined'"
              size="small"
              class="mr-2"
              :loading="togglingFlag"
              @click="toggleFollowupFlag"
            >
              {{ pah.household_followup_flag ? 'Flagged' : 'Flag' }}
            </v-btn>
          </v-card-title>
          <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />
          <v-card-text v-if="pah">
            <v-row>
              <v-col cols="12" md="6">
                <person-view :person-id="pah.householdhead_id" title="Head of Household:" />
                <div class="d-flex align-center">
                  <template v-if="!editingVillage">
                    <strong>Village:</strong>&nbsp;<span class="table-value">{{ pah?.village || 'none' }}</span>
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil" @click="startEditVillage"
                      style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                  </template>
                  <template v-else>
                    <strong>Village:</strong>&nbsp;
                    <v-select
                      v-model="draftVillageId"
                      :items="villages"
                      item-title="village"
                      item-value="village_id"
                      density="compact"
                      hide-details
                      variant="underlined"
                      style="max-width: 220px"
                    />
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check" :loading="savingVillage"
                      @click="saveVillage" />
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close" @click="editingVillage = false" />
                  </template>                  
                </div>
                <div class="d-flex align-center">
                  <template v-if="!editingDuplicatePah">
                    <strong>Duplicate PAH:</strong>&nbsp;<span class="table-value">{{ pah.duplicate_pah }}</span>
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil"
                      @click="startEditDuplicatePah"
                      style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                  </template>
                  <template v-else>
                    <strong>Duplicate PAH:</strong>&nbsp;
                    <v-text-field v-model="draftDuplicatePah" density="compact" hide-details
                      variant="underlined" style="max-width: 180px" maxlength="20" />
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check"
                      :loading="savingDuplicatePah" @click="saveDuplicatePah" />
                    <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close"
                      @click="editingDuplicatePah = false" />
                  </template>
                </div>                

              </v-col>
              <v-col cols="12" md="6">
                <template v-if="pah.cosignatory_id">
                  <person-view :person-id="pah.cosignatory_id" title="Cosignatory:" />
                </template>
              </v-col>
              <v-col cols="12">
                <v-divider class="my-2" />
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12">
                <template v-if="!pah.no_ica_required">
                  <div :style="{ color: pah.date_signed ? 'inherit' : 'red' }">
                    <strong>ICA Signature Date:</strong> <span class="table-value">{{ pah.date_signed ? formatDateTime(pah.date_signed) : 'not signed' }}</span>
                  </div>
                  <div><strong>Signed ICA:</strong>
                    <v-btn
                      v-if="getSafeExternalUrl(pah.ica_link)"
                      :href="getSafeExternalUrl(pah.ica_link)"
                      prepend-icon="mdi-open-in-new"
                      variant="text"
                      size="small"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="ml-2"
                      title="Open ICA link"
                    >Open Signed ICA</v-btn>
                  </div>
                  <div v-if="!pah.nonaffected"><strong>Generate new ICA: </strong>
                    <v-btn
                      v-if="pah"
                      @click="downloadCertificate"
                      prepend-icon="mdi-file-word-outline"
                      variant="text"
                      size="small"
                      class="ml-2"
                      title="Generate new ICA"
                      :loading="downloadingCert"
                    >Generate</v-btn>                    
                  </div>
                </template>
                <template v-else>
                  <div><strong>ICA:</strong> <span class="table-value">Not Required</span></div>
                </template>
              </v-col>
            </v-row>
            <Icas
              ref="householdIcas"
              :pah="pahno"
              :new-ica-required="pah?.new_ica_required ?? false"
              @update:new-ica-required="val => { pah = { ...pah, new_ica_required: val } }"
              @ica-added="householdNotes?.loadNotes()"
            />            
            <Notes ref="householdNotes" :pah="pahno" />
            <Grievances :person-id="pah.householdhead_id" @grievance-changed="householdNotes?.loadNotes()" />

            <Members :pah="pahno" class="mt-5" />
            <v-tabs v-model="tab" class="rounded mt-5" bg-color="blue-lighten-4" selected-class="bg-primary">
              <v-tab value="ica">ICA</v-tab>
              <v-tab :disabled="!pah.survey_complete" value="survey">Survey</v-tab>
            </v-tabs>
            <v-window v-model="tab" class="border pl-5 pt-3">
              <v-window-item value="ica">
                <v-row>
                  <v-col cols="12" md="6">
                    <div><strong>Physically Displaced: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.physically_displaced) }">{{ formatYesNo(pah.physically_displaced) }}</span></div>
                    <div><strong>Landholding only: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.landholding_only) }">{{ formatYesNo(pah.landholding_only) }}</span></div>
                    <div><strong>No ICA Required: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.no_ica_required) }">{{ formatYesNo(pah.no_ica_required) }}</span></div>
                    <div><strong>New ICA Required: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.new_ica_required) }">{{ formatYesNo(pah.new_ica_required) }}</span></div>
                    <div><strong>Disturbance only: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.nonaffected) }">{{ formatYesNo(pah.nonaffected) }}</span></div>
                    <div><strong>Is Silumesii: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.silumesii) }">{{ formatYesNo(pah.silumesii) }}</span></div>
                    <div><strong>Flagged: </strong><span class="table-value" :class="{ 'highlight-true': isTrueValue(pah.household_followup_flag) }">{{ formatYesNo(pah.household_followup_flag) }}</span></div>
                  </v-col>
                  <v-col cols="12" md="6">
                    <div><strong>Cash Compensation:</strong> <span class="table-value">K{{ formatCurrency(pah.compensation?.total_cash_compensation || 0) }}</span></div>
                    <div v-if="pah.replacement_land_area>0"><strong>Replacement Land:</strong> <span class="table-value">{{ formatArea(pah.replacement_land_area) }} ({{ landOptions }})</span></div>
                    <div v-if="pah.replacement_structures_count>0"><strong>Replacement Structures:</strong> <span class="table-value">{{ pah.replacement_structures_count }} <span>({{ pah.icaoption_structure_location }})</span></span></div>
                  </v-col>
                </v-row>
                <v-row v-if="pah.notes">
                  <v-col cols="12">
                    <b>Note:</b> {{ pah.notes }}
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
                        <tr v-if="pah.compensation.primary_structures_compensation_value > 0">
                          <td class="table-label">Primary Structures</td>
                          <td class="table-value">K{{ formatCurrency(pah.compensation.primary_structures_compensation_value) }}</td>
                        </tr>
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
                      <TableCopyFooter :colspan="2" />
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
                      <TableCopyFooter :colspan="2" />
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
                        <tr v-if="pah.icaoption_primary_structure">
                          <td class="table-label">Primary Structure</td>
                          <td class="table-value">{{ pah.icaoption_primary_structure }}</td>
                        </tr>
                        <tr v-if="pah.icaoption_structure_location">
                          <td class="table-label">Structure Location</td>
                          <td class="table-value">{{ pah.icaoption_structure_location }}</td>
                        </tr>
                        <tr v-if="pah.icaoption_transport">
                          <td class="table-label">Transport</td>
                          <td class="table-value">{{ pah.icaoption_transport }}</td>
                        </tr>
                        <tr v-if="pah.icaoption_landholding || pah.land_compensation.filter(v=>v.acquisition_class == 'Permanent' && v.land_class == 'Landholding').length > 0 || editingIcaOption === 'icaoption_landholding'">
                          <td class="table-label">Landholding</td>
                          <td class="table-value">
                            <template v-if="editingIcaOption !== 'icaoption_landholding'">
                              {{ pah.icaoption_landholding || 'none' }}
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil"
                                @click="startEditIcaOption('icaoption_landholding')"
                                style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                            </template>
                            <template v-else>
                              <v-select v-model="draftIcaOption" :items="icaOptionChoices" item-title="title" item-value="value"
                                density="compact" hide-details variant="underlined" style="max-width: 220px; display: inline-block" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check"
                                :loading="savingIcaOption" @click="saveIcaOption('icaoption_landholding')" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close"
                                @click="editingIcaOption = null" />
                            </template>
                          </td>
                        </tr>
                        <tr v-if="pah.icaoption_dryland || pah.land_compensation.filter(v=>v.acquisition_class == 'Permanent' && v.land_class == 'Dryland').length > 0 || editingIcaOption === 'icaoption_dryland'">
                          <td class="table-label">Dryland</td>
                          <td class="table-value">
                            <template v-if="editingIcaOption !== 'icaoption_dryland'">
                              {{ pah.icaoption_dryland || 'none' }}
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil"
                                @click="startEditIcaOption('icaoption_dryland')"
                                style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                            </template>
                            <template v-else>
                              <v-select v-model="draftIcaOption" :items="icaOptionChoices" item-title="title" item-value="value"
                                density="compact" hide-details variant="underlined" style="max-width: 220px; display: inline-block" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check"
                                :loading="savingIcaOption" @click="saveIcaOption('icaoption_dryland')" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close"
                                @click="editingIcaOption = null" />
                            </template>
                          </td>
                        </tr>
                        <tr v-if="pah.icaoption_garden || pah.land_compensation.filter(v=>v.acquisition_class == 'Permanent' && v.land_class == 'Garden').length > 0 || editingIcaOption === 'icaoption_garden'">
                          <td class="table-label">Garden</td>
                          <td class="table-value">
                            <template v-if="editingIcaOption !== 'icaoption_garden'">
                              {{ pah.icaoption_garden || 'none' }}
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil"
                                @click="startEditIcaOption('icaoption_garden')"
                                style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                            </template>
                            <template v-else>
                              <v-select v-model="draftIcaOption" :items="icaOptionChoices" item-title="title" item-value="value"
                                density="compact" hide-details variant="underlined" style="max-width: 220px; display: inline-block" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check"
                                :loading="savingIcaOption" @click="saveIcaOption('icaoption_garden')" />
                              <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close"
                                @click="editingIcaOption = null" />
                            </template>
                          </td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="2" />
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
                        <tr v-if="pah.lr_agricultural">
                          <td class="table-label">Agricultural</td>
                          <td class="table-value">{{ pah.lr_agricultural }}</td>
                        </tr>
                        <tr v-if="pah.lr_livestock">
                          <td class="table-label">Livestock</td>
                          <td class="table-value">{{ pah.lr_livestock }}</td>
                        </tr>
                        <tr v-if="pah.lr_water">
                          <td class="table-label">Water</td>
                          <td class="table-value">{{ pah.lr_water }}</td>
                        </tr>
                        <tr v-if="pah.lr_fisheries">
                          <td class="table-label">Fisheries</td>
                          <td class="table-value">{{ pah.lr_fisheries }}</td>
                        </tr>
                        <tr v-if="pah.lr_reedbeds">
                          <td class="table-label">Reedbeds</td>
                          <td class="table-value">{{ pah.lr_reedbeds }}</td>
                        </tr>
                        <tr v-if="pah.lr_agricultureinputs">
                          <td class="table-label">Agriculture Inputs</td>
                          <td class="table-value">{{ pah.lr_agricultureinputs }}</td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="2" />
                    </v-table>
                  </v-col>
                </v-row>
                <v-row v-if="pah.land_compensation && pah.land_compensation.length > 0" class="mt-4">
                  <v-col cols="12">
                    <v-table density="compact">
                      <thead>
                        <tr>
                          <th colspan="9" class="table-heading">Land Compensation Summary</th>
                        </tr>
                        <tr>
                          <th>Land Class</th>
                          <th>Acquisition Class</th>
                          <th class="center">Parcels</th>
                          <th class="right">Acquisition Area</th>
                          <th class="right">Acquisition Rate</th>
                          <th class="right">Acquisition Cost</th>
                          <th class="right">Lease Rate</th>
                          <th class="right">Lease Cost</th>
                          <th class="right">Lease Total</th>

                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(item, index) in pah.land_compensation" :key="index">
                          <td class="table-value left">{{ item.rate_acquisition_class }}</td>
                          <td class="table-value left">{{ item.acquisition_class }}</td>
                          <td class="table-value center">{{ item.asset_count }}</td>
                          <td class="table-value right">{{ formatArea(item.area_sqm) }}</td>
                          <td class="table-value right">{{ item.rate_acquisition != null ? `K${item.rate_acquisition}/sqm` : '-' }}</td>
                          <td class="table-value right">{{ item.land_value != null ? `K${formatCurrency(item.land_value)}` : '-' }}</td>
                          <td class="table-value right">{{ item.rate_lease != null ? `K${item.rate_lease}/sqm/year` : '-' }}</td>
                          <td class="table-value right">{{ item.lease_cost != null ? `K${formatCurrency(item.lease_cost)}/year` : '-' }}</td>
                          <td class="table-value right">{{ item.lease_cost_total != null ? `K${formatCurrency(item.lease_cost_total)}` : '-' }}</td>
                        </tr>
                        <tr class="table-total">
                          <td class="table-value" colspan="2">Total</td>
                          <td class="table-value center">{{ pah.land_compensation.reduce((sum, i) => sum + (i.asset_count || 0), 0) }}</td>
                          <td class="table-value right">{{ formatArea(pah.land_compensation.reduce((sum, i) => sum + (i.area_sqm || 0), 0)) }}</td>
                          <td class="table-value right"></td>
                          <td class="table-value">K{{ formatCurrency(pah.land_compensation.reduce((sum, i) => sum + (i.land_value || 0), 0)) }}</td>
                          <td class="table-value"></td>
                          <td class="table-value right"></td>
                          <td class="table-value">K{{ formatCurrency(pah.land_compensation.reduce((sum, i) => sum + (i.lease_cost_total || 0), 0)) }}</td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="9" />
                    </v-table>
                  </v-col>
                </v-row>
                <v-row v-if="parcels.length > 0" class="mt-4">
                  <v-col cols="12">
                    <v-table density="compact">
                      <thead>
                        <tr>
                          <th colspan="9" class="table-heading">Land Details</th>
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
                            <td>{{ parcel.land_parcel_id }}<MapLink :lat="parseLatLon(parcel).lat" :lon="parseLatLon(parcel).lon" /></td>
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
                      <TableCopyFooter :colspan="9" />
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
                          <th>Est Cost</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="replacement in replacements" :key="replacement.replacement_structure_id">
                          <td class="table-value left"><router-link :to="{ name: 'ReplacementDetails', params: { id: replacement.replacement_structure_id } }">{{ replacement.replacement_structure_id }}</router-link></td>
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
                      <TableCopyFooter :colspan="5" />
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
                            <v-expansion-panel-title :class="structure.protected ? 'bg-green-lighten-4' : ''">

                              <div class="structure-panel-title">
                                <span><span v-if="structure.protected"><b>[PROTECTED]</b>&nbsp;</span>{{ structure.structure_id }} </span>&nbsp;
                                <span>{{ structure.structure_class }}</span> - <span><strong>{{ structure.structure_type }}</strong></span>
                                <MapLink :lat="parseLatLon(structure).lat" :lon="parseLatLon(structure).lon" />
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
                                    <TableCopyFooter :colspan="5" />
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
                <v-row v-if="trees.length > 0" >
                  <v-col cols="12">
                    <v-table>
                      <thead>
                        <tr>
                          <th colspan="5" class="table-heading">Trees</th>
                        </tr>
                        <tr>
                          <th>Tree Type</th>
                          <th class="center">Juvenile</th>
                          <th class="center">Productive</th>
                          <th class="center">Replacement<br/>Saplings</th>
                          <th class="right">Compensation</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="tree in trees" :key="tree.tree_type">
                          <td class="table-value left">{{ tree.tree_type }}</td>
                          <td class="table-value center">{{ tree.juvenile_count }}</td>
                          <td class="table-value center">{{ tree.productive_count }}</td>
                          <td class="table-value center">{{ tree.replacement_saplings }}</td>
                          <td class="table-value right">K{{ formatCurrency(tree.compensation) }}</td>
                        </tr>
                        <tr class="table-total">
                          <td class="table-value" colspan="4">Total</td>
                          <td class="table-value">K{{ formatCurrency(trees.reduce((sum, t) => sum + (t.compensation || 0), 0)) }}</td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="5" />
                    </v-table>
                  </v-col>
                </v-row>
                <v-row v-if="crops.length > 0" >
                  <v-col cols="12">
                    <v-table>
                      <thead>
                        <tr>
                          <th colspan="6" class="table-heading">Crops</th>
                        </tr>
                        <tr>
                          <th>Crop Type</th>
                          <th class="right">Field Size (sqm)</th>
                          <th class="center">Coverage</th>
                          <th class="right">Rate (K/sqm)</th>
                          <th class="right">Crop Size (sqm)</th>
                          <th class="right">Value</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(crop, index) in crops" :key="index">
                          <td class="table-value left">{{ crop.crop_type }}</td>
                          <td class="table-value right">{{ formatArea(crop.field_size) }}</td>
                          <td class="table-value center">{{ (crop.coverage * 100).toFixed(0) }}%</td>
                          <td class="table-value right">K{{ formatCurrency(crop.rate) }}</td>
                          <td class="table-value right">{{ formatArea(crop.crop_size) }}</td>
                          <td class="table-value right">K{{ formatCurrency(crop.crop_value) }}</td>
                        </tr>
                        <tr class="table-total">
                          <td class="table-value" colspan="5">Total</td>
                          <td class="table-value right">K{{ formatCurrency(crops.reduce((sum, c) => sum + (c.crop_value || 0), 0)) }}</td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="6" />
                    </v-table>
                  </v-col>
                </v-row>
                <v-row v-if="graves.length > 0" >
                  <v-col cols="12">
                    <v-table>
                      <thead>
                        <tr>
                          <th colspan="8" class="table-heading">Graves</th>
                        </tr>
                        <tr>
                          <th>Deceased</th>
                          <th>Year of Death</th>
                          <th>Age</th>
                          <th>Relation</th>
                          <th class="center">Coffin</th>
                          <th>Marker</th>
                          <th>Location</th>
                          <th>ICA Option</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(grave, index) in graves" :key="index">
                          <td class="table-value left">{{ grave.deceased }}</td>
                          <td class="table-value left">{{ grave.year_of_death }}</td>
                          <td class="table-value left">{{ grave.age }}</td>
                          <td class="table-value left">{{ grave.relation }}</td>
                          <td class="table-value center">{{ formatYesNo(grave.coffin) }}</td>
                          <td class="table-value left">{{ grave.marker }}</td>
                          <td class="table-value left">{{ grave.location }}</td>
                          <td class="table-value left">{{ grave.ica_option }}</td>
                        </tr>
                      </tbody>
                      <TableCopyFooter :colspan="8" />
                    </v-table>
                  </v-col>
                </v-row>
              </v-window-item>
              <v-window-item value="survey">
                <v-row>
                  <v-col cols="12">
                    <div>
                      <v-btn
                        v-if="getSafeExternalUrl(pah_survey.survey_link)"
                        :href="getSafeExternalUrl(pah_survey.survey_link)"
                        prepend-icon="mdi-file-document-outline"
                        variant="text"
                        size="small"
                        target="_blank"
                        rel="noopener noreferrer"
                        class=""
                      >Open Survey Form</v-btn>
                    </div>
                    <div>
                      <strong>Survey location:</strong> <MapLink :lat="pah_survey.lat" :lon="pah_survey.lon" />
                    </div>
                    <div>
                      <strong>Survey completed:&nbsp;</strong>
                      <span class="table-value" :class="!pah?.survey_complete ? 'highlight' : ''">{{ pah?.survey_complete ? formatDateTime(pah_survey.survey_date) : 'No' }}</span>
                    </div>                    
                  </v-col>
                </v-row>
                <v-table density="compact" class="survey-table pt-5" v-if="pah_survey">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">PAH Survey Responses</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="([key, label]) in surveyFields" :key="key">
                      <td class="survey-label">{{ label }}</td>
                      <td class="table-value left">{{ pah_survey[key] ?? '' }}</td>
                    </tr>
                  </tbody>
                  <TableCopyFooter :colspan="2" />
                </v-table>
              </v-window-item>
            </v-window>
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
  background-color: rgba(224, 140, 140, 0.527);
  border-radius: 8px;
  padding: 0 6px;
}

.highlight-true {
  background-color: rgba(224, 140, 140, 0.527);
  border-radius: 8px;
  padding: 0 6px;
}

.survey-table .survey-label {
  font-size: 0.8rem;
  color: rgba(0,0,0,0.55);
  width: 45%;
  vertical-align: top;
  padding: 4px 12px 4px 8px;
}

.survey-table .survey-value {
  font-size: 0.85rem;
  vertical-align: top;
  white-space: pre-wrap;
  padding: 4px 8px;
}

</style>
