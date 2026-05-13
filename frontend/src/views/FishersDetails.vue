<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import Notes from '@/components/Notes.vue'
import Grievances from '@/components/Grievances.vue'
import Icas from '@/components/Icas.vue'
import PersonView from '@/components/PersonView.vue'
import { formatCurrency, formatYesNo, formatDateTime } from '@/utils/formatters'

const axiosSecure = inject('axiosSecure')
const route = useRoute()

const fisher = ref(null)
const loading = ref(false)
const error = ref('')
const fisherNotes = ref(null)
const togglingFlag = ref(false)

const nhs = computed(() => String(route.params.nhs || '').trim())

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



const getSafeExternalUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  if (/^https?:\/\//i.test(url)) return url
  return null
}

onMounted(load)
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
                <PersonView v-if="fisher.person_id" :fisher="true" :person-id="fisher.person_id" title="Person:" />
                <div v-if="fisher.person" class="mt-1">
                  <div><strong>Gender:</strong> <span class="ml-1">{{ fisher.person.gender || '—' }}</span></div>
                  <div><strong>Village:</strong> <span class="ml-1">{{ fisher.person.village || '—' }}</span></div>
                </div>
              </v-col>
              <v-col cols="12" md="6">
                <div><strong>Survey Phase:</strong> <span class="ml-1">{{ fisher.survey_phase ?? '—' }}</span></div>
                <div><strong>Social Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.social_survey) }}</span></div>
                <div><strong>Catch Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.catch_survey) }}</span></div>
                <div><strong>Catch Data Survey:</strong> <span class="ml-1">{{ formatYesNo(fisher.catch_data_survey) }}</span></div>
              </v-col>
            </v-row>
            <v-row>
              <div :style="{ color: fisher.date_signed ? 'inherit' : 'red' }">
                <strong>ICA Signature Date:</strong> <span class="table-value">{{ fisher.date_signed ? formatDateTime(fisher.date_signed) : 'not signed' }}</span>
                <v-btn
                  v-if="getSafeExternalUrl(fisher.ica_link)"
                  :href="getSafeExternalUrl(fisher.ica_link)"
                  prepend-icon="mdi-open-in-new"
                  variant="text"
                  size="x-small"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="ml-2"
                  title="Open ICA link"
                >Open ICA Link</v-btn>
              </div>
            </v-row>
            <Notes ref="fisherNotes" :nhs="nhs" class="mb-4" />
            <Grievances :nhs="nhs" class="mb-4" @grievance-changed="fisherNotes?.loadNotes()" />
            <Icas
              :nhs="nhs"
              :new-ica-required="fisher?.new_ica_required ?? false"
              @update:new-ica-required="val => { if (fisher) fisher.new_ica_required = val }"
              @ica-added="fisherNotes?.loadNotes()"
              class="mb-4"
            />
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
