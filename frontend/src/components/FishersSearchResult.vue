<script setup>
import { inject, ref, watch } from 'vue'
import { formatCurrency } from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

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
</script>

<template>
  <v-card elevation="1">
    <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
    <v-card-title class="d-flex text-body-1 pt-2 pb-2">
      <v-row no-gutters align="center">
        <v-col cols="8">
          <router-link :to="`/fishers/${props.nhs}`" class="text-decoration-none">
            {{ props.nhs }}{{ fisher && fisher.person ? ' — ' + fisher.person.fullname : '' }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end flex-wrap ga-1">
          <v-chip v-if="fisher && fisher.followup_flag" color="purple" size="small">Flagged</v-chip>
          <v-chip v-if="fisher && fisher.type" color="blue" size="small">{{ fisher.type }}</v-chip>
          <v-chip v-if="fisher && fisher.maungwe_active === 'Active'" color="green" size="small">Maungwe</v-chip>
          <v-chip v-if="fisher && fisher.limbelo_active === 'Active'" color="teal" size="small">Limbelo</v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="fisher" class="pt-1 pb-2">
      <PersonView v-if="fisher.person_id" :person-id="fisher.person_id" :slim="true" :readonly="true" class="mb-1" />
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <strong>Survey Phase:</strong>
            <span class="ml-1">{{ fisher.survey_phase ?? '—' }}</span>
          </div>
        </v-col>
        <v-col cols="12" sm="6">
          <div>
            <strong>Site Compensation:</strong>
            <span class="ml-1">K{{ formatCurrency(fisher.site_compensation || 0) }}</span>
          </div>
          <div>
            <strong>Transitional Allowance:</strong>
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
