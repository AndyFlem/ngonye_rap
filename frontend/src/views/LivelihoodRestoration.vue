<script setup>
import { inject, onMounted, ref } from 'vue'
import TopBar from '@/components/TopBar.vue'
import TableCopyFooter from '@/components/TableCopyFooter.vue'

const axiosSecure = inject('axiosSecure')
const householdsLR = ref([])
const fishersLR    = ref([])
const loading      = ref(false)
const error        = ref('')

onMounted(async () => {
  loading.value = true
  try {
    const [hRes, fRes] = await Promise.all([
      axiosSecure.get('/livelihood-restoration/households'),
      axiosSecure.get('/livelihood-restoration/fishers'),
    ])
    householdsLR.value = hRes.data
    fishersLR.value    = fRes.data
  } catch (err) {
    console.error('Failed to load LR data:', err)
    error.value = 'Failed to load Livelihood Restoration data.'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-alert v-if="error" type="error" class="mb-4">{{ error }}</v-alert>
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <h3 class="text-h3 mb-4">Households LR</h3>
            <v-table density="compact" v-if="!loading">
              <thead>
                <tr>
                  <th class="table-heading">Option</th>
                  <th class="table-heading right">Count</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in householdsLR" :key="row.label">
                  <td>{{ row.label }}</td>
                  <td class="table-value">{{ row.count }}</td>
                </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
          <v-col cols="12" sm="6" md="4">
            <h3 class="text-h3 mb-4">Fishers LR</h3>
            <v-table density="compact" v-if="!loading">
              <thead>
                <tr>
                  <th class="table-heading">Option</th>
                  <th class="table-heading right">Count</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in fishersLR" :key="row.label">
                  <td>{{ row.label }}</td>
                  <td class="table-value">{{ row.count }}</td>
                </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </div>
</template>
