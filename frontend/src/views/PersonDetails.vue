<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'



const axiosSecure = inject('axiosSecure')
const baseUrlStatic = inject('baseUrlStatic')
const route = useRoute()
const router = useRouter()

const person = ref(null)
const loading = ref(false)
const error = ref('')

const personId = computed(() => String(route.params.person_id || '').trim())

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await axiosSecure.get(`/person/${personId.value}`)
    person.value = response.data
  } catch (err) {
    console.error('Failed to load person:', err)
    error.value = 'An error occurred while loading the person details.'
  } finally {
    loading.value = false
  }
}

const photoUrl = computed(() =>
  person.value?.photo_file ? `${baseUrlStatic}static/hhh_photos/${person.value.photo_file}` : null
)

const personRef = computed(() => {
  const id = route.params.person_id
  return id ? `PER${String(id).padStart(4, '0')}` : 'PER0000'
})

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>
        <v-card elevation="1">
          <v-card-title class="d-flex">
            <span v-if="person">{{ person.fullname }}</span>
            <span v-else>Person {{ personRef }}</span>
            <v-spacer />
            <template v-if="person">
              <v-chip v-if="person.fisher" color="teal" size="small" class="mr-1">Fisher</v-chip>
              <v-chip v-if="person.household_head" color="blue" size="small" class="mr-1">Head</v-chip>
              <v-chip v-if="person.cosignatory" color="orange" size="small" class="mr-1">Cosignatory</v-chip>
              <v-chip v-if="person.disabled" color="red" size="small" class="mr-1">Disabled</v-chip>
            </template>
          </v-card-title>

          <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />

          <v-card-text v-if="person">
            <v-row>
              <v-col cols="12" md="4" class="mt-2">
                <div><b>Id: </b>{{ personRef }}</div>
                <div><b>Name: </b>{{ person.fullname }}</div>
                <div><strong>Gender:</strong> <span class="ml-1">{{ person.gender || '—' }}</span></div>
                <div><strong>Contact:</strong> <span class="ml-1">{{ person.contact || '—' }}</span></div>
                <div><strong>Alternate Contact:</strong> <span class="ml-1">{{ person.contact2 || '—' }}</span></div>
                <div><strong>NRC:</strong> <span class="ml-1">{{ person.nrc || '—' }}</span></div>
              </v-col>

              <v-col cols="12" md="4" class="mt-2">
                

                <div><strong>Year of Birth:</strong> <span class="ml-1">{{ person.year_of_birth || '—' }}</span></div>
                <div><strong>Village:</strong> <span class="ml-1">{{ person.village || '—' }}</span></div>
                <div><strong>Relationship:</strong> <span class="ml-1">{{ person.relationship || '—' }}</span></div>
                <div><strong>Marital Status:</strong> <span class="ml-1">{{ person.marital_status || '—' }}</span></div>
                <div><strong>District:</strong> <span class="ml-1">{{ person.district || '—' }}</span></div>
                <div><strong>Origin:</strong> <span class="ml-1">{{ person.origin || '—' }}</span></div>
              </v-col>
              <v-col cols="12" md="4">
                <v-img v-if="photoUrl" :src="photoUrl" max-height="220" max-width="180" cover class="rounded mb-3" />
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="6">
                <v-table density="compact" class="mb-3">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Links</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="person.pah">
                      <td>Household (PAH)</td>
                      <td><router-link :to="`/households/${person.pah}`">{{ person.pah }}</router-link></td>
                    </tr>
                    <tr v-if="person.nhs && person.fisher">
                      <td>Fisher Record</td>
                      <td><router-link :to="`/fishers/${person.nhs}`">{{ person.nhs }}</router-link></td>
                    </tr>
                    <tr v-if="!person.pah && !(person.nhs && person.fisher)">
                      <td colspan="2" class="text-medium-emphasis">No linked records</td>
                    </tr>
                  </tbody>
                </v-table>

                <v-table density="compact" class="mb-3">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Occupation &amp; Skills</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Primary Occupation</td>
                      <td>{{ person.primary_occupation || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Secondary Occupation</td>
                      <td>{{ person.secondary_occupation || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Primary Skill</td>
                      <td>{{ person.primary_skill || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Secondary Skill</td>
                      <td>{{ person.secondary_skill || '—' }}</td>
                    </tr>
                  </tbody>
                </v-table>

                <v-table density="compact">
                  <thead>
                    <tr>
                      <th colspan="2" class="table-heading">Other Details</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Residential Status</td>
                      <td>{{ person.residential_status || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Education</td>
                      <td>{{ person.education || '—' }}</td>
                    </tr>
                    <tr>
                      <td>Disabilities</td>
                      <td>{{ person.disabilities || '—' }}</td>
                    </tr>
                  </tbody>
                </v-table>
              </v-col>
            </v-row>
          </v-card-text>

          <v-card-actions>
            <v-btn @click="router.push('/people')">Back to People</v-btn>
            <v-spacer />
            <v-btn color="primary" variant="tonal" :disabled="!person" @click="router.push(`/people/${personId}/edit`)">Edit</v-btn>
          </v-card-actions>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
