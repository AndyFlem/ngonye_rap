<script setup>
import { inject, ref, watch } from 'vue'
import { formatCurrency, formatDateTime } from '@/utils/formatters'

const props = defineProps({
  nhs: { type: String, required: true }
})

const axiosSecure = inject('axiosSecure')

const fisher = ref(null)
const loading = ref(false)
const error = ref('')

watch(() => props.nhs, async (newNhs) => {
  if (!newNhs) return
  loading.value = true
  error.value = ''
  fisher.value = null
  try {
    const response = await axiosSecure.get(`/fishers/${newNhs}`)
    fisher.value = response.data
  } catch (err) {
    console.error('Failed to load fisher:', err)
    error.value = 'Failed to load fisher data.'
  } finally {
    loading.value = false
  }
}, { immediate: true })


const getSafeExternalUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  if (/^https?:\/\//i.test(url)) return url
  return null
}

</script>

<template>
  <v-card>
    <v-alert v-if="error" type="error" variant="tonal" class="mt-2">
      {{ error }}
    </v-alert>
    <v-card-title class="d-flex text-title-medium pt-1 pb-1">
      <v-row no-gutters>
        <v-col cols="8">
          <router-link :to="`/fishers/${props.nhs}`">
            {{ props.nhs }}{{ fisher && fisher.person ? ' — ' + fisher.person.fullname : '' }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end flex-wrap ga-1">
          <v-chip v-if="fisher && fisher.followup_flag" color="purple" size="small">Flagged</v-chip>
          <v-chip v-if="fisher && fisher.type" :color="fisher.type === 'Limbelo' ? 'orange' : fisher.type === 'Maungwe' ? 'green' : fisher.type === 'Both' ? 'indigo' : 'blue'" size="small">{{ fisher.type }}</v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="fisher">
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <strong>Survey Phase:</strong>
            <span class="ml-1">{{ fisher.survey_phase ?? '—' }}</span>
          </div>
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
          <div v-if="fisher.linked_pah"><strong>Linked household:</strong><router-link :to="`/households/${fisher.linked_pah}`">{{ fisher.linked_pah }}</router-link></div>
        </v-col>
        <v-col cols="12" sm="6">
          <div>
            Site Compensation:
            <span class="ml-1">K{{ formatCurrency(fisher.site_compensation || 0) }}</span>
          </div>
          <div>
            Transitional Allowance:
            <span class="ml-1">K{{ formatCurrency(fisher.transitional_allowance || 0) }}</span>
          </div>
          <div>
            <strong>Total Compensation:</strong>
            <span class="ml-1">K{{ formatCurrency(fisher.total_compensation || 0) }}</span>
          </div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
