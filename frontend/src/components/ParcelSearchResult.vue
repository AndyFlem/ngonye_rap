<script setup>
import { inject, ref, watch } from 'vue'
import { formatArea } from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

const axiosSecure = inject('axiosSecure')
const parcel = ref(null)
const loading = ref(false)
const error = ref('')

const props = defineProps({
  parcelId: {
    type: String,
    required: true
  }
})

watch(() => props.parcelId, async (newId) => {
  if (newId) {
    loading.value = true
    error.value = ''
    parcel.value = null
    try {
      const response = await axiosSecure.get(`/parcels/${newId}`)
      parcel.value = response.data
    } catch (err) {
      console.error('Failed to load land parcel:', err)
      error.value = 'An error occurred while loading the land parcel.'
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
          <router-link :to="`/parcels/${props.parcelId}`">
            {{ props.parcelId }}{{ parcel ? ' — ' + parcel.land_class + (parcel.land_zone ? ' / ' + parcel.land_zone : '') : '' }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end">
          <v-chip color="green" class="mr-2" size="small" v-if="parcel && parcel.cultivated">
            Cultivated
          </v-chip>
          <v-chip color="red" class="mr-2" size="small" v-if="parcel && parcel.remaining_viable === false">
            Not Viable
          </v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="parcel">
      <v-row>
        <v-col cols="12" sm="6">
          <div>
            <strong>PAH:</strong>
            <router-link :to="`/households/${parcel.pah}`" class="ml-1">{{ parcel.pah }}</router-link>
          </div>
          <div>
            <person-view :readonly="true" :slim="true" :person-id="parcel.householdhead_id" title="Head of Household:" />
          </div>
          <div v-if="parcel.village"><strong>Village:</strong> <span class="table-value">{{ parcel.village }}</span></div>
        </v-col>
        <v-col cols="12" sm="6">
          <div><strong>Class:</strong> <span class="table-value">{{ parcel.land_class }}</span></div>
          <div v-if="parcel.land_zone"><strong>Zone:</strong> <span class="table-value">{{ parcel.land_zone }}</span></div>
          <div v-if="parcel.area_sqm"><strong>Area:</strong> <span class="table-value">{{ formatArea(parcel.area_sqm) }}</span></div>
          <div v-if="parcel.area_acquired"><strong>Area Acquired:</strong> <span class="table-value">{{ formatArea(parcel.area_acquired) }}</span></div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
