<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import { formatCurrency, formatYesNo } from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()

const replacement = ref(null)
const loading = ref(false)
const error = ref('')

const id = computed(() => String(route.params.id || '').trim())

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get(`/replacements/${id.value}`)
    replacement.value = response.data
  } catch (err) {
    console.error('Failed to load replacement structure:', err)
    error.value = 'An error occurred while loading the replacement structure.'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row class="mb-4" align="center">
          <v-col>
            <h1 class="text-h4 mb-2">Replacement Structure: {{ id }}</h1>
          </v-col>
        </v-row>

        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>

        <v-progress-circular v-if="loading" indeterminate class="d-block mx-auto my-6" />

        <v-card v-if="replacement" elevation="1">
          <v-card-title class="d-flex align-center">
            <span>{{ replacement.replacement_option }}</span>
            <v-spacer />
            <v-chip color="blue" class="mr-2" v-if="replacement.protected">Protected</v-chip>
            <v-chip color="purple" v-if="replacement.flag_followup">Follow-Up</v-chip>
          </v-card-title>
          <v-card-text>
            <v-row>
              <v-col cols="12" sm="6">
                <div class="mb-1">
                  <strong>PAH:</strong>
                  <router-link :to="`/households/${replacement.pah}`" class="ml-1">{{ replacement.pah }}</router-link>
                </div>
                <div>
                  <person-view :readonly="true" :person-id="replacement.householdhead_id" title="Head of Household:" />
                </div>
              </v-col>

            </v-row>
            <v-row>
              <v-col cols="12" sm="6">
                <div class="mb-1"><strong>Structure ID:</strong> <span class="table-value">{{ replacement.structure_id || '—' }}</span></div>
                <div class="mb-1"><strong>Class:</strong> <span class="table-value">{{ replacement.replacement_class || '—' }}</span></div>
                <div class="mb-1"><strong>Type Ref:</strong> <span class="table-value">{{ replacement.replacement_type_ref || '—' }}</span></div>
                <div class="mb-1"><strong>Phase:</strong> <span class="table-value">{{ replacement.phase || '—' }}</span></div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="mb-1"><strong>Replacement Option:</strong> <span class="table-value">{{ replacement.replacement_option || '—' }}</span></div>
                <div class="mb-1"><strong>Replacement Value:</strong> <span class="table-value">{{ replacement.replacement_value ? 'K' + formatCurrency(replacement.replacement_value) : '—' }}</span></div>
                <div class="mb-1"><strong>ICA Option: Primary Structure:</strong> <span class="table-value">{{ replacement.icaoption_primary_structure || '—' }}</span></div>
                <div class="mb-1"><strong>ICA Option: Structure Location:</strong> <span class="table-value">{{ replacement.icaoption_structure_location || '—' }}</span></div>
                <div class="mb-1"><strong>Protected:</strong> <span class="table-value">{{ formatYesNo(replacement.protected) }}</span></div>
                <div class="mb-1"><strong>Follow-Up Flag:</strong> <span class="table-value">{{ formatYesNo(replacement.flag_followup) }}</span></div>
              </v-col>
            </v-row>
            <v-row v-if="replacement.data_notes">
              <v-col cols="12">
                <strong>Notes:</strong>
                <p class="mt-1">{{ replacement.data_notes }}</p>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
