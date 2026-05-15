<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TopBar from '@/components/TopBar.vue'

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
  disabled: false
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

const villages = ref([])
const relationshipOptions = ref([])
const maritalStatusOptions = ref([])
const residentialStatusOptions = ref([])
const occupationOptions = ref([])
const skillOptions = ref([])
const educationOptions = ref([])
const loading = ref(false)
const saving = ref(false)
const error = ref('')

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const [personRes, villagesRes, relRes, maritalRes, resStatusRes, primOccRes, secOccRes, primSkillRes, secSkillRes, eduRes] = await Promise.all([
      axiosSecure.get(`/person/${personId.value}`),
      axiosSecure.get('/villages'),
      axiosSecure.get('/people/field-values?field=relationship'),
      axiosSecure.get('/people/field-values?field=marital_status'),
      axiosSecure.get('/people/field-values?field=residential_status'),
      axiosSecure.get('/people/field-values?field=primary_occupation'),
      axiosSecure.get('/people/field-values?field=secondary_occupation'),
      axiosSecure.get('/people/field-values?field=primary_skill'),
      axiosSecure.get('/people/field-values?field=secondary_skill'),
      axiosSecure.get('/people/field-values?field=education')
    ])
    villages.value = villagesRes.data
    relationshipOptions.value = relRes.data
    maritalStatusOptions.value = maritalRes.data
    residentialStatusOptions.value = resStatusRes.data
    occupationOptions.value = [...new Set([...primOccRes.data, ...secOccRes.data])].sort()
    skillOptions.value = [...new Set([...primSkillRes.data, ...secSkillRes.data])].sort()
    educationOptions.value = eduRes.data
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

              <v-row>
                <!-- Identity -->
                <v-col cols="12" md="6">
                  <div class="d-flex align-center mb-2">
                    <span class="text-subtitle-2">Identity</span>
                    <v-btn size="x-small" variant="text" class="ml-2 text-grey" icon="mdi-swap-horizontal"
                      title="Swap first and last name"
                      @click="[form.firstname, form.lastname] = [form.lastname, form.firstname]" />
                  </div>
                  <v-text-field v-model="form.firstname" label="First Name" density="compact" variant="outlined" class="mb-2" />
                  <v-text-field v-model="form.middlename" label="Middle Name" density="compact" variant="outlined" class="mb-2" />
                  <v-text-field v-model="form.lastname" label="Last Name" density="compact" variant="outlined" class="mb-2" />
                  <v-select v-model="form.gender" label="Gender" :items="['Male', 'Female']" density="compact" variant="outlined" class="mb-2" clearable />
                  <v-text-field v-model="form.nrc" label="NRC" density="compact" variant="outlined" class="mb-2" />
                  <v-text-field v-model="form.year_of_birth" label="Year of Birth" density="compact" variant="outlined" :error-messages="validationErrors.year_of_birth" @input="delete validationErrors.year_of_birth" />
                </v-col>

                <!-- Location & Demographics -->
                <v-col cols="12" md="6">
                  <div class="text-subtitle-2 mb-2">Location &amp; Demographics</div>
                  <v-select v-model="form.village_id" label="Village" :items="villages" item-title="village" item-value="village_id" density="compact" variant="outlined" class="mb-2" clearable />
                  <v-text-field v-model="form.district" label="District" density="compact" variant="outlined" class="mb-2" />
                  <v-text-field v-model="form.origin" label="Origin" density="compact" variant="outlined" class="mb-2" />
                  <v-combobox v-model="form.relationship" label="Relationship" :items="relationshipOptions" density="compact" variant="outlined" class="mb-2" :readonly="form.relationship === 'Household Head'" />
                  <v-combobox v-model="form.marital_status" label="Marital Status" :items="maritalStatusOptions" density="compact" variant="outlined" class="mb-2" />
                  <v-combobox v-model="form.residential_status" label="Residential Status" :items="residentialStatusOptions" density="compact" variant="outlined" />
                </v-col>

                <!-- Contact -->
                <v-col cols="12" md="6">
                  <div class="text-subtitle-2 mb-2">Contact</div>
                  <v-text-field v-model="form.contact" label="Contact" density="compact" variant="outlined" class="mb-2" />
                  <v-text-field v-model="form.contact2" label="Alternate Contact" density="compact" variant="outlined" />
                </v-col>

                <!-- Occupation & Skills -->
                <v-col cols="12" md="6">
                  <div class="text-subtitle-2 mb-2">Occupation &amp; Skills</div>
                  <v-combobox v-model="form.primary_occupation" label="Primary Occupation" :items="occupationOptions" density="compact" variant="outlined" class="mb-2" />
                  <v-combobox v-model="form.secondary_occupation" label="Secondary Occupation" :items="occupationOptions" density="compact" variant="outlined" class="mb-2" />
                  <v-combobox v-model="form.primary_skill" label="Primary Skill" :items="skillOptions" density="compact" variant="outlined" class="mb-2" />
                  <v-combobox v-model="form.secondary_skill" label="Secondary Skill" :items="skillOptions" density="compact" variant="outlined" />
                </v-col>

                <!-- Other -->
                <v-col cols="12" md="6">
                  <div class="text-subtitle-2 mb-2">Other</div>
                  <v-combobox v-model="form.education" label="Education" :items="educationOptions" density="compact" variant="outlined" class="mb-2" />
                  <v-checkbox v-model="form.disabled" label="Disabled" density="compact" hide-details />
                  <v-text-field v-model="form.disabilities" label="Disabilities" density="compact" variant="outlined" class="mb-2" :disabled="!form.disabled" />
                </v-col>
              </v-row>
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
