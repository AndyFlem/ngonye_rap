<script setup>
import { inject, ref, watch } from 'vue'
import { formatCurrency } from '@/utils/formatters'

const axiosSecure = inject('axiosSecure')
const structure = ref(null)
const loading = ref(false)
const error = ref('')

const props = defineProps({
  structureId: {
    type: String,
    required: true
  }
})

watch(() => props.structureId, async (newId) => {
  if (newId) {
    loading.value = true
    error.value = ''
    structure.value = null
    try {
      const response = await axiosSecure.get(`/structures/${newId}`)
      structure.value = response.data
    } catch (err) {
      console.error('Failed to load structure:', err)
      error.value = 'An error occurred while loading the structure.'
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
          <router-link :to="`/structures/${props.structureId}`">
            {{ props.structureId }}{{ structure ? ' — ' + structure.structure_type : '' }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end">
          <v-chip color="blue" class="mr-2" size="small" v-if="structure && structure.protected">
            Protected
          </v-chip>
          <v-chip color="purple" class="mr-2" size="small" v-if="structure && structure.followup_flag">
            Follow-Up
          </v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="structure">
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <strong>PAH:</strong>
            <router-link :to="`/households/${structure.pah}`" class="ml-1">{{ structure.pah }}</router-link>
          </div>
          <div><strong>Class:</strong> <span class="table-value">{{ structure.structure_class }}</span></div>
          <div><strong>Type:</strong> <span class="table-value">{{ structure.structure_type }}</span></div>
          <div v-if="structure.land_zone"><strong>Zone:</strong> <span class="table-value">{{ structure.land_zone }}</span></div>
        </v-col>
        <v-col cols="12" sm="6">
          <div v-if="structure.secondary_description"><strong>Description:</strong> <span class="table-value">{{ structure.secondary_description }}</span></div>
          <div v-if="structure.dimensions"><strong>Dimensions:</strong> <span class="table-value">{{ structure.dimensions }}sqm</span></div>
          <div><strong>Value:</strong> <span class="table-value">K{{ formatCurrency(structure.structure_value) }}</span></div>
          <div v-if="structure.replacement_structure_id">
            <strong>Replacement:</strong>
            <router-link :to="`/replacements/${structure.replacement_structure_id}`" class="ml-1">{{ structure.replacement_structure_id }}</router-link>
            <span class="table-value ml-1" v-if="structure.replacement_option">({{ structure.replacement_option }})</span>
          </div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
