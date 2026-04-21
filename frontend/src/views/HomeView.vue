<script setup>
import { inject } from 'vue'
import { onMounted, ref } from 'vue'
import TopBar from '@/components/TopBar.vue'

const households = ref(null)
const loading = ref(false)
const error = ref('')

const user = inject('user')
const axiosSecure = inject('axiosSecure')

const load = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await axiosSecure.get(`/households_summary`)
    households.value = response.data || null
  } catch (err) {
    error.value = 'Failed to load household details.'
    console.error('Failed to load household details:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  load()
})

</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row>
          <v-col cols="12">
            <h1 class="text-h3 mb-4">
              Welcome, {{ user.first_name || user.email }}!
            </h1>
            <p class="text-body1">
              {{ households }}
            </p>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </div>
</template>

<style scoped>
</style>
