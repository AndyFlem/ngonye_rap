<script setup>
import { inject, ref, watch } from 'vue'
import { formatCurrency, formatArea, formatYesNo } from '@/utils/formatters'

const axiosSecure = inject('axiosSecure')

const pah = ref(null)

const loading = ref(false)
const error = ref('')

const props = defineProps({
  pahNo: {
    type: String,
    required: true
  }
})

const getSafeExternalUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  if (/^https?:\/\//i.test(url)) return url
  return null
}

// When pah is updated, load the pah data
watch(() => props.pahNo, async (newPah) => {
  if (newPah) {
    console.log('Loading pah data for PAH:', newPah)
    loading.value = true
    error.value = ''
    pah.value = null
    try {
      const response = await axiosSecure.get(`/households/${newPah}`)
      pah.value = response.data
    } catch (err) {
      console.error('Failed to load pah:', err)
      error.value = 'An error occurred while loading the pah data. Please try again.'
    } finally {
      loading.value = false
    }
  }
}, { immediate: true })

</script>

<template>
  <v-card>
    <v-alert v-if="error" type="error" variant="tonal" class="mt-2">
      {{ error }}
    </v-alert>
    <v-card-title class="d-flex text-title-medium pt-1 pb-1">
      <v-row no-gutters>
        <v-col cols="8">
          <router-link :to="`/households/${props.pahNo}`">{{ props.pahNo }} - {{ pah ? pah.household_head_fullname : 'Loading...' }}</router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end">
          <v-chip color="red" class="mr-2" size="small" v-if="pah && pah.vulnerable">
            Vulnerable
          </v-chip>
          <v-chip color="purple" class="mr-2" size="small" v-if="pah && pah.household_followup_flag">
            Flagged
          </v-chip>
          <v-chip color="orange" class="mr-2" size="small" v-if="pah && pah.new_ica_required">
            New ICA Required
          </v-chip>
          <v-chip color="" class="mr-2" size="small" v-if="pah && pah.no_ica_required">
            ICA Not Required
          </v-chip>
          <v-chip color="" class="mr-2" size="small" v-if="pah && pah.nonaffected">
            Non-affected
          </v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="pah">
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <span v-if="!pah.no_ica_required" :style="{ color: pah?.date_signed ? 'inherit' : 'red' }">
              <strong>ICA Signature Date:</strong> <span class="table-value">{{ pah?.date_signed || 'not signed' }}</span>
            </span>
            <span v-else>
              <strong>ICA:</strong> <span class="table-value">Not Required</span>
            </span>

            <v-btn
              v-if="getSafeExternalUrl(pah?.ica_link)"
              :href="getSafeExternalUrl(pah?.ica_link)"
              prepend-icon="mdi-open-in-new"
              variant="text"
              size="x-small"
              target="_blank"
              rel="noopener noreferrer"
              class="ml-2"
              title="Open ICA link"
            >Open ICA Link</v-btn>
          </div>
          <div>
            <b>Village:</b> <span class="table-value">{{ pah?.village }}</span>
          </div>
          <div>
            <b>Physically Displaced:</b> <span class="table-value">{{ formatYesNo(pah?.physically_displaced) }}</span>
          </div>
        </v-col>
        <v-col cols="12" sm="6">
          <div><strong>Cash Compensation:</strong> <span class="table-value">K{{ formatCurrency(pah.compensation?.total_cash_compensation || 0) }}</span></div>
          <div v-if="pah.replacement_land_area>0"><strong>Replacement Land:</strong> <span class="table-value">{{ formatArea(pah.replacement_land_area) }} ({{ pah.icaoption_landholding }})</span></div>
          <div v-if="pah.replacement_structures_count>0"><strong>Replacement Structures:</strong> <span class="table-value">{{ pah.replacement_structures_count }} <span>({{ pah.icaoption_structure_location }})</span></span></div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

