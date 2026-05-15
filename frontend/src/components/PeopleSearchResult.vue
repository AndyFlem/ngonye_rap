<script setup>
import { inject, ref, watch, computed } from 'vue'

const baseUrlStatic = inject('baseUrlStatic')

const props = defineProps({
  personId: { type: [String, Number], required: true }
})

const axiosSecure = inject('axiosSecure')

const person = ref(null)
const loading = ref(false)
const error = ref('')

const photoUrl = computed(() =>
  person.value?.photo_file ? `${baseUrlStatic}static/hhh_photos/${person.value.photo_file}` : null
)

watch(() => props.personId, async (id) => {
  if (!id) return
  loading.value = true
  error.value = ''
  person.value = null
  try {
    const response = await axiosSecure.get(`/person/${id}`)
    person.value = response.data
  } catch (err) {
    console.error('Failed to load person:', err)
    error.value = 'Failed to load person data.'
  } finally {
    loading.value = false
  }
}, { immediate: true })
</script>

<template>
  <v-card>
    <v-alert v-if="error" type="error" variant="tonal" class="mt-2">{{ error }}</v-alert>
    <v-card-title class="d-flex text-title-medium pt-1 pb-1">
      <v-row no-gutters>
        <v-col cols="8">
          <router-link :to="`/people/${props.personId}`">
            {{ person ? person.fullname : props.personId }}
          </router-link>
        </v-col>
        <v-col cols="4" class="d-flex justify-end flex-wrap ga-1">
          <v-chip v-if="person && person.fisher" color="teal" size="small">Fisher</v-chip>
          <v-chip v-if="person && person.household_head" color="blue" size="small">Head</v-chip>
          <v-chip v-if="person && person.cosignatory" color="orange" size="small">Cosignatory</v-chip>
          <v-chip v-if="person && person.disabled" color="red" size="small">Disabled</v-chip>
        </v-col>
      </v-row>
    </v-card-title>
    <v-card-text v-if="person">
      <v-row>
        <v-col cols="10">
          <v-row no-gutters>
            <v-col cols="12" sm="6">
              <div v-if="person.contact"><strong>Contact:</strong> <span class="ml-1">{{ person.contact }}</span></div>
              <div v-if="person.nrc"><strong>NRC:</strong> <span class="ml-1">{{ person.nrc }}</span></div>
              <div v-if="person.nhs">
                <strong>NHS:</strong>
                <router-link v-if="person.fisher" :to="`/fishers/${person.nhs}`" class="ml-1">{{ person.nhs }}</router-link>
                <span v-else class="ml-1">{{ person.nhs }}</span>
              </div>
              <div v-if="person.pah">
                <strong>PAH:</strong>
                <router-link :to="`/households/${person.pah}`" class="ml-1">{{ person.pah }}</router-link>
              </div>
            </v-col>
            <v-col cols="12" sm="6">
              <div v-if="person.gender"><strong>Gender:</strong> <span class="ml-1">{{ person.gender }}</span></div>
              <div v-if="person.village"><strong>Village:</strong> <span class="ml-1">{{ person.village }}</span></div>
              <div v-if="person.relationship"><strong>Relationship:</strong> <span class="ml-1">{{ person.relationship }}</span></div>
            </v-col>
          </v-row>
        </v-col>
        <v-col cols="2">
          <v-img v-if="photoUrl" :src="photoUrl" max-height="120" max-width="80" cover class="rounded mb-3" />  
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
