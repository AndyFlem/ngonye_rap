<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import PersonFormFields from '@/components/PersonFormFields.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()
const router = useRouter()

const personId = computed(() => route.params.person_id)

const form = ref({
  firstname: '',
  middlename: '',
  lastname: '',
  gender: '',
  nrc: '',
  year_of_birth: '',
  village_id: null,
  district: '',
  origin: '',
  relationship: '',
  marital_status: '',
  residential_status: '',
  contact: '',
  contact2: '',
  primary_occupation: '',
  secondary_occupation: '',
  primary_skill: '',
  secondary_skill: '',
  education: '',
  disabilities: '',
  disabled: false,
  deceased_date: ''
})

const validationErrors = ref({})

const validate = () => {
  const errs = {}
  const yob = form.value.year_of_birth
  if (yob !== '' && yob !== null) {
    const n = Number(yob)
    const currentYear = new Date().getFullYear()
    if (!Number.isInteger(n) || n <= 1900 || n >= currentYear) {
      errs.year_of_birth = `Must be a whole number between 1901 and ${currentYear - 1}.`
    }
  }
  validationErrors.value = errs
  return Object.keys(errs).length === 0
}

const loading = ref(false)
const saving = ref(false)
const error = ref('')

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const personRes = await axiosSecure.get(`/person/${personId.value}`)
    const p = personRes.data
    form.value.firstname = p.firstname ?? ''
    form.value.middlename = p.middlename ?? ''
    form.value.lastname = p.lastname ?? ''
    form.value.gender = p.gender ?? ''
    form.value.nrc = p.nrc ?? ''
    form.value.year_of_birth = p.year_of_birth ?? ''
    form.value.village_id = p.village_id ?? null
    form.value.district = p.district ?? ''
    form.value.origin = p.origin ?? ''
    form.value.relationship = p.relationship ?? ''
    form.value.marital_status = p.marital_status ?? ''
    form.value.residential_status = p.residential_status ?? ''
    form.value.contact = p.contact ?? ''
    form.value.contact2 = p.contact2 ?? ''
    form.value.primary_occupation = p.primary_occupation ?? ''
    form.value.secondary_occupation = p.secondary_occupation ?? ''
    form.value.primary_skill = p.primary_skill ?? ''
    form.value.secondary_skill = p.secondary_skill ?? ''
    form.value.education = p.education ?? ''
    form.value.disabilities = p.disabilities ?? ''
    form.value.disabled = p.disabled ?? false
    form.value.deceased_date = p.deceased_date ?? ''
  } catch (err) {
    error.value = 'Failed to load person.'
  } finally {
    loading.value = false
  }
}

const save = async () => {
  if (!validate()) return
  saving.value = true
  error.value = ''
  try {
    await axiosSecure.patch(`/person/${personId.value}`, form.value)
    router.push(`/people/${personId.value}`)
  } catch (err) {
    error.value = 'Failed to save person.'
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-card elevation="1">
          <v-card-title class="table-heading">Edit Person</v-card-title>

          <v-card-text>
            <div v-if="loading" class="d-flex justify-center pa-6">
              <v-progress-circular indeterminate color="primary" />
            </div>

            <template v-else>
              <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>
              <PersonFormFields v-model="form" :validation-errors="validationErrors" />
            </template>
          </v-card-text>

          <v-card-actions>
            <v-spacer />
            <v-btn variant="text" :disabled="saving" @click="router.push(`/people/${personId}`)">Cancel</v-btn>
            <v-btn color="primary" variant="tonal" :loading="saving" @click="save">Save</v-btn>
          </v-card-actions>
        </v-card>
      </v-container>
    </v-main>
  </div>
</template>
