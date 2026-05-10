<script setup>
import { inject, ref, watch } from 'vue'
import { formatCurrency} from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

const axiosSecure = inject('axiosSecure')
const replacement = ref(null)
const loading = ref(false)
const error = ref('')

const props = defineProps({
  replacementId: {
    type: String,
    required: true
  }
})

watch(() => props.replacementId, async (newId) => {
  if (newId) {
    loading.value = true
    error.value = ''
    replacement.value = null
    try {
      const response = await axiosSecure.get(`/replacements/${newId}`)
      replacement.value = response.data
    } catch (err) {
      console.error('Failed to load replacement structure:', err)
      error.value = 'An error occurred while loading the replacement structure.'
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
          <router-link :to="`/replacements/${props.replacementId}`">
            {{ props.replacementId }}{{ replacement ? ' — ' + replacement.replacement_option : '' }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end">
          <v-chip color="blue" class="mr-2" size="small" v-if="replacement && replacement.protected">
            Protected
          </v-chip>
          <v-chip color="purple" class="mr-2" size="small" v-if="replacement && replacement.flag_followup">
            Follow-Up
          </v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="replacement">
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <strong>PAH:</strong>
            <router-link :to="`/households/${replacement.pah}`" class="ml-1">{{ replacement.pah }}</router-link>
          </div>
          <div>
            <person-view :readonly="true" :slim="true" :person-id="replacement.householdhead_id" title="Head of Household:" />
          </div>
          <div><strong>Class:</strong> <span class="table-value">{{ replacement.replacement_class }}</span></div>
          <div v-if="replacement.phase"><strong>Phase:</strong> <span class="table-value">{{ replacement.phase }}</span></div>
        </v-col>
        <v-col cols="12" sm="6">
          <div><strong>Option:</strong> <span class="table-value">{{ replacement.replacement_option }}</span></div>
          <div v-if="replacement.replacement_value"><strong>Value:</strong> <span class="table-value">K{{ formatCurrency(replacement.replacement_value) }}</span></div>
          <div v-if="replacement.icaoption_structure_location"><strong>Location:</strong> <span class="table-value">{{ replacement.icaoption_structure_location }}</span></div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
