<script setup>
import { inject, onMounted, reactive, ref, watch } from 'vue'

const props = defineProps({
  modelValue: { type: Object, required: true },
  validationErrors: { type: Object, default: () => ({}) }
})

const emit = defineEmits(['update:modelValue'])

const axiosSecure = inject('axiosSecure')

const local = reactive({ ...props.modelValue })

watch(local, (v) => emit('update:modelValue', { ...v }), { deep: true })

watch(() => props.modelValue, (v) => Object.assign(local, v), { deep: true })

const villages = ref([])
const relationshipOptions = ref([])
const maritalStatusOptions = ref([])
const residentialStatusOptions = ref([])
const occupationOptions = ref([])
const skillOptions = ref([])
const educationOptions = ref([])

onMounted(async () => {
  const [villagesRes, relRes, maritalRes, resStatusRes, primOccRes, secOccRes, primSkillRes, secSkillRes, eduRes] = await Promise.all([
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
})
</script>

<template>
  <v-row>
    <!-- Identity -->
    <v-col cols="12" md="6">
      <div class="d-flex align-center mb-2">
        <span class="text-subtitle-2">Identity</span>
        <v-btn size="x-small" variant="text" class="ml-2 text-grey" icon="mdi-swap-horizontal"
          title="Swap first and last name"
          @click="[local.firstname, local.lastname] = [local.lastname, local.firstname]" />
      </div>
      <v-text-field v-model="local.firstname" label="First Name" density="compact" variant="outlined" class="mb-2" />
      <v-text-field v-model="local.middlename" label="Middle Name" density="compact" variant="outlined" class="mb-2" />
      <v-text-field v-model="local.lastname" label="Last Name" density="compact" variant="outlined" class="mb-2" />
      <v-select v-model="local.gender" label="Gender" :items="['Male', 'Female']" density="compact" variant="outlined" class="mb-2" clearable />
      <v-text-field v-model="local.nrc" label="NRC" density="compact" variant="outlined" class="mb-2" />
      <v-text-field v-model="local.year_of_birth" label="Year of Birth" density="compact" variant="outlined"
        :error-messages="validationErrors.year_of_birth"
        @input="delete validationErrors.year_of_birth" />
    </v-col>

    <!-- Location & Demographics -->
    <v-col cols="12" md="6">
      <div class="text-subtitle-2 mb-2">Location &amp; Demographics</div>
      <v-select v-model="local.village_id" label="Village" :items="villages" item-title="village" item-value="village_id" density="compact" variant="outlined" class="mb-2" clearable />
      <v-text-field v-model="local.district" label="District" density="compact" variant="outlined" class="mb-2" />
      <v-text-field v-model="local.origin" label="Origin" density="compact" variant="outlined" class="mb-2" />
      <v-combobox v-model="local.relationship" label="Relationship" :items="relationshipOptions" density="compact" variant="outlined" class="mb-2" :readonly="local.relationship === 'Household Head'" />
      <v-combobox v-model="local.marital_status" label="Marital Status" :items="maritalStatusOptions" density="compact" variant="outlined" class="mb-2" />
      <v-combobox v-model="local.residential_status" label="Residential Status" :items="residentialStatusOptions" density="compact" variant="outlined" />
    </v-col>

    <!-- Contact -->
    <v-col cols="12" md="6">
      <div class="text-subtitle-2 mb-2">Contact</div>
      <v-text-field v-model="local.contact" label="Contact" density="compact" variant="outlined" class="mb-2" />
      <v-text-field v-model="local.contact2" label="Alternate Contact" density="compact" variant="outlined" />
    </v-col>

    <!-- Occupation & Skills -->
    <v-col cols="12" md="6">
      <div class="text-subtitle-2 mb-2">Occupation &amp; Skills</div>
      <v-combobox v-model="local.primary_occupation" label="Primary Occupation" :items="occupationOptions" density="compact" variant="outlined" class="mb-2" />
      <v-combobox v-model="local.secondary_occupation" label="Secondary Occupation" :items="occupationOptions" density="compact" variant="outlined" class="mb-2" />
      <v-combobox v-model="local.primary_skill" label="Primary Skill" :items="skillOptions" density="compact" variant="outlined" class="mb-2" />
      <v-combobox v-model="local.secondary_skill" label="Secondary Skill" :items="skillOptions" density="compact" variant="outlined" />
    </v-col>

    <!-- Other -->
    <v-col cols="12" md="6">
      <div class="text-subtitle-2 mb-2">Other</div>
      <v-combobox v-model="local.education" label="Education" :items="educationOptions" density="compact" variant="outlined" class="mb-2" />
      <v-checkbox v-model="local.disabled" label="Disabled" density="compact" hide-details />
      <v-text-field v-model="local.disabilities" label="Disabilities" density="compact" variant="outlined" class="mb-2" :disabled="!local.disabled" />
      <v-text-field v-model="local.deceased_date" label="Deceased Date" type="date" density="compact" variant="outlined" class="mb-2" clearable />
    </v-col>
  </v-row>
</template>
