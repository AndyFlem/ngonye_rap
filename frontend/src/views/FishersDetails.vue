<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import Notes from '@/components/Notes.vue'
import Grievances from '@/components/Grievances.vue'
import Icas from '@/components/Icas.vue'
import PersonView from '@/components/PersonView.vue'
import { formatCurrency, formatYesNo, formatDateTime } from '@/utils/formatters'


const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const fisher = ref(null)
const loading = ref(false)
const error = ref('')
const fisherNotes = ref(null)
const togglingFlag = ref(false)
const downloadingCert = ref(false)

const villages = ref([])
const editingVillage = ref(false)
const draftVillage = ref(null)
const savingVillage = ref(false)

const nhs = computed(() => String(route.params.nhs || '').trim())

function startEditVillage () {
  draftVillage.value = fisher.value?.village_id ?? null
  editingVillage.value = true
}

async function saveVillage () {
  savingVillage.value = true
  try {
    const villageId = draftVillage.value ?? null
    await axiosSecure.patch(`/fishers/${encodeURIComponent(nhs.value)}`, { village_id: villageId })
    const village = villages.value.find(v => v.village_id === villageId)?.village ?? null
    fisher.value = { ...fisher.value, village_id: villageId, village }
    editingVillage.value = false
  } catch (err) {
    console.error('Failed to save village:', err)
    error.value = 'Failed to save Village.'
  } finally {
    savingVillage.value = false
  }
}

async function toggleFollowupFlag () {
  togglingFlag.value = true
  try {
    const newVal = !fisher.value.followup_flag
    await axiosSecure.patch(`/fishers/${encodeURIComponent(nhs.value)}`, { followup_flag: newVal })
    fisher.value = { ...fisher.value, followup_flag: newVal }
    fisherNotes.value?.loadNotes()
  } catch (err) {
    console.error('Failed to toggle followup flag:', err)
    error.value = 'Failed to update followup flag.'
  } finally {
    togglingFlag.value = false
  }
}

async function downloadCertificate () {
  downloadingCert.value = true
  try {
    const response = await axiosSecure.get(
      `/fishers/${encodeURIComponent(nhs.value)}/certificate`,
      { responseType: 'blob' }
    )
    const url = URL.createObjectURL(response.data)
    const a = document.createElement('a')
    a.href = url
    const dateString = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    a.download = `${nhs.value} ${dateString} ${fisher.value?.fullname}.docx`
    a.click()
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('Failed to download certificate:', err)
    error.value = 'Failed to generate certificate.'
  } finally {
    downloadingCert.value = false
  }
}

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get(`/fishers/${nhs.value}`)
    fisher.value = response.data
  } catch (err) {
    console.error('Failed to load fisher:', err)
    error.value = 'An error occurred while loading the fisher details.'
  } finally {
    loading.value = false
  }
}

const loadVillages = async () => {
  try {
    const response = await axiosSecure.get('/villages')
    villages.value = Array.isArray(response.data) ? response.data : []
  } catch (err) {
    console.error('Failed to load villages:', err)
  }
}

const goBack = () => {
  router.back()
}

const getSafeExternalUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  if (/^https?:\/\//i.test(url)) return url
  return null
}

onMounted(() => {
  load()
  loadVillages()
})
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>
        <v-card elevation="1">
          <v-card-title class="d-flex">
            {{ nhs }}&nbsp;<span v-if="fisher"> - {{ fisher.fullname }}</span>
            <span>{{  }}</span>
            <v-spacer />
            <v-chip class="mr-3" v-if="fisher && fisher.type" :color="fisher.type === 'Limbelo' ? 'orange' : fisher.type === 'Maungwe' ? 'green' : fisher.type === 'Both' ? 'indigo' : 'blue'" size="small">{{ fisher.type }}</v-chip>
            <v-btn
              v-if="fisher"
              :color="fisher.followup_flag ? 'purple' : 'grey'"
              :variant="fisher.followup_flag ? 'tonal' : 'outlined'"
              size="small"
              class="mr-2"
              :loading="togglingFlag"
              @click="toggleFollowupFlag"
            >
              {{ fisher.followup_flag ? 'Flagged' : 'Flag' }}
            </v-btn>
          </v-card-title>
          <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />
          <v-card-text v-if="fisher">
            <v-row>
              <v-col cols="12" md="6">
                <PersonView v-if="fisher.person_id" :fisher="true" :person-id="fisher.person_id" title="Fisher:" />
                <div class="mt-1">
                  <div v-if="fisher.person"><strong>Gender:</strong> <span class="ml-1">{{ fisher.person.gender || '—' }}</span></div>
                  <div class="d-flex align-center">
                    <template v-if="!editingVillage">
                      <strong>Village:</strong> <span class="ml-1">{{ fisher.village || '—' }}</span>
                      <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil"
                        @click="startEditVillage"
                        style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
                    </template>
                    <template v-else>
                      <strong>Village:</strong>&nbsp;
                      <v-autocomplete v-model="draftVillage" :items="villages" item-title="village"
                        item-value="village_id" density="compact" hide-details variant="underlined"
                        style="max-width: 220px" clearable no-data-text="No villages found" />
                      <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check"
                        :loading="savingVillage" @click="saveVillage" />
                      <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close"
                        @click="editingVillage = false" />
                    </template>
                  </div>
                </div>
              </v-col>
              <v-col cols="12" md="6">
                <div><strong>Survey Phase:</strong> <span class="ml-1">{{ fisher.survey_phase ?? '—' }}</span></div>
                <div><strong>Social Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.social_survey) }}</span></div>
                <div><strong>Catch Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.catch_survey) }}</span></div>
                <div><strong>Catch Data Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.catch_data_survey) }}</span></div>
                <div v-if="fisher.lr_fishfarming"><strong>Fish Farming:</strong> <span class="ml-1">{{ formatYesNo(fisher.lr_fishfarming) }}</span></div>
                <div v-if="fisher.lr_goatrearing"><strong>Goat Rearing:</strong> <span class="ml-1">{{ formatYesNo(fisher.lr_goatrearing) }}</span></div>
              </v-col>
            </v-row>
            <Icas
              :nhs="nhs"
              :new-ica-required="fisher?.new_ica_required ?? false"
              @update:new-ica-required="val => { if (fisher) fisher.new_ica_required = val }"
              @ica-added="fisherNotes?.loadNotes()"
              class="mb-4"
            />
            <Notes ref="fisherNotes" :nhs="nhs" class="mb-4" />
            <Grievances :person-id="fisher.person_id" class="mb-4" @grievance-changed="fisherNotes?.loadNotes()" />

            <v-row class="pt-4">
              <v-col cols="12" md="6">
                <v-table density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Livlihood Restoration</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Fish Farming</td>
                      <td class="table-value">{{ formatYesNo(fisher.lr_fishfarming) }}</td>
                    </tr>
                    <tr>
                      <td>Goat Rearing</td>
                      <td class="table-value">{{ formatYesNo(fisher.lr_goatrearing) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>  
            </v-row>
            <v-row class="pt-4">
              <v-col cols="12" md="6">
                <v-table density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Compensation Summary</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Site Compensation (calc)</td>
                      <td class="table-value">K{{ formatCurrency(fisher.site_compensation_calc) }}</td>
                    </tr>
                    <tr>
                      <td>Site Compensation (min K500)</td>
                      <td class="table-value">K{{ formatCurrency(fisher.site_compensation) }}</td>
                    </tr>
                    <tr>
                      <td>Maungwe Annual Earnings</td>
                      <td class="table-value">K{{ formatCurrency(fisher.maungwe_annual_earn) }}</td>
                    </tr>
                    <tr>
                      <td>Limbelo Annual Earnings</td>
                      <td class="table-value">K{{ formatCurrency(fisher.limbelo_annual_earn) }}</td>
                    </tr>
                    <tr class="">
                      <td>Transitional Allowance</td>
                      <td class="table-value">K{{ formatCurrency(fisher.transitional_allowance) }}</td>
                    </tr>
                    <tr class="table-total">
                      <td>Total Compensation</td>
                      <td class="table-value">K{{ formatCurrency(fisher.total_compensation) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>

              <v-col cols="12" md="6">
                <v-table
                  density="compact" class="mb-3"
                  v-if="!fisher.type || fisher.type === 'Maungwe' || fisher.type === 'Both'"
                >
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Maungwe Fishing</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Status</td>
                      <td class="table-value">{{ fisher.maungwe_active || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Traps</td>
                      <td class="table-value">{{ fisher.maungwe_traps ?? '—' }}</td>
                    </tr>
                    <tr>
                      <td>Annual Earnings</td>
                      <td class="table-value">K{{ formatCurrency(fisher.maungwe_annual_earnings) }}</td>
                    </tr>
                  </tbody>
                </v-table>

                <v-table
                  density="compact"
                  v-if="!fisher.type || fisher.type === 'Limbelo' || fisher.type === 'Both'"
                >
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Limbelo Fishing</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Status</td>
                      <td class="table-value">{{ fisher.limbelo_active || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Traps</td>
                      <td class="table-value">{{ fisher.limbelo_traps ?? '—' }}</td>
                    </tr>
                    <tr>
                      <td>Annual Buckets</td>
                      <td class="table-value">{{ fisher.limbelo_annual_buckets ?? '—' }}</td>
                    </tr>
                    <tr>
                      <td>Days Fished</td>
                      <td class="table-value">{{ fisher.limbelo_days_fished ?? '—' }}</td>
                    </tr>
                    <tr>
                      <td>Annual Earnings</td>
                      <td class="table-value">K{{ formatCurrency(fisher.limbelo_annual_earnings) }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>
          </v-card-text>
          <v-card-actions>
            <v-btn color="primary" @click="goBack">Back to Fishers</v-btn>
          </v-card-actions>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
