<script setup>
import { inject, ref, watch } from 'vue'

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
    <v-card-title class="d-flex">
      <router-link :to="`/households/${props.pahNo}`">{{ props.pahNo }} - {{ pah ? pah.household_head_fullname : 'Loading...' }}</router-link>
    </v-card-title>
    <v-card-text v-if="pah">
      {{ pah }}
      <v-row>
        <v-col cols="12" sm="6">
          <div :style="{ color: pah?.date_signed ? 'inherit' : 'red' }">
            <strong>ICA Signature Date:</strong> <span class="table-value">{{ pah?.date_signed || 'not signed' }}</span>
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
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

