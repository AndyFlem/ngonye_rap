<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import TableCopyFooter from '@/components/TableCopyFooter.vue'
import PersonFormFields from '@/components/PersonFormFields.vue'

const props = defineProps({
  pah: { type: String, default: null },
  nhs: { type: String, default: null },
})

const axiosSecure = inject('axiosSecure')
const members = ref([])
const loading = ref(false)

const sortedMembers = computed(() => {
  const rank = (m) => m.household_head ? 0 : m.cosignatory ? 1 : 2
  return [...members.value].sort((a, b) => rank(a) - rank(b))
})

const loadMembers = async () => {
  if (!props.pah && !props.nhs) return
  loading.value = true
  try {
    const url = props.pah
      ? `/households/${encodeURIComponent(props.pah)}/members`
      : `/fishers/${encodeURIComponent(props.nhs)}/members`
    const response = await axiosSecure.get(url)
    members.value = Array.isArray(response.data) ? response.data : []
  } finally {
    loading.value = false
  }
}

onMounted(loadMembers)

// Add Member dialog
const showAddDialog = ref(false)
const addSaving = ref(false)
const addError = ref('')
const addValidationErrors = ref({})

const emptyForm = () => ({
  firstname: '', middlename: '', lastname: '', gender: '', nrc: '',
  year_of_birth: '', village_id: null, district: '', origin: '',
  relationship: '', marital_status: '', residential_status: '',
  contact: '', contact2: '', primary_occupation: '', secondary_occupation: '',
  primary_skill: '', secondary_skill: '', education: '',
  disabilities: '', disabled: false, deceased_date: ''
})

const addForm = ref(emptyForm())

const openAdd = () => {
  addForm.value = emptyForm()
  addError.value = ''
  addValidationErrors.value = {}
  showAddDialog.value = true
}

const submitAdd = async () => {
  const errs = {}
  const yob = addForm.value.year_of_birth
  if (yob !== '' && yob !== null) {
    const n = Number(yob)
    const currentYear = new Date().getFullYear()
    if (!Number.isInteger(n) || n <= 1900 || n >= currentYear) {
      errs.year_of_birth = `Must be a whole number between 1901 and ${currentYear - 1}.`
    }
  }
  addValidationErrors.value = errs
  if (Object.keys(errs).length) return

  addSaving.value = true
  addError.value = ''
  try {
    const payload = { ...addForm.value, ...(props.pah ? { pah: props.pah } : { nhs: props.nhs }) }
    await axiosSecure.post('/person', payload)
    showAddDialog.value = false
    await loadMembers()
  } catch {
    addError.value = 'Failed to add member.'
  } finally {
    addSaving.value = false
  }
}
</script>

<template>
  <div v-if="pah || nhs">
    <div class="d-flex justify-end mb-1">
      <v-btn size="small" variant="outlined" prepend-icon="mdi-plus" @click="openAdd">Add Member</v-btn>
    </div>

    <v-table v-if="members.length" density="compact">
      <thead>
        <tr>
          <th colspan="8" class="table-heading">Members ({{ members.length }})</th>
        </tr>
        <tr>
          <th class="left">Role</th>
          <th>Name</th>
          <th class="left">Gender</th>
          <th class="left">Birth Year</th>
          <th>Relationship</th>
          <th>Marital Status</th>
          <th>Education</th>
          <th>Primary Occupation</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="m in sortedMembers" :key="m.person_id" :class="{ 'member-disabled': m.disabled }">
          <td class="table-value left">
            <span v-if="m.household_head" class="member-badge hh-badge">HH</span>
            <span v-if="m.cosignatory" class="member-badge co-badge">CO</span>
            <span v-if="m.disabled" class="member-badge disabled-badge">Disabled</span>
          </td>
          <td class="table-value left">
            <router-link :to="{ name: 'PersonDetails', params: { person_id: m.person_id } }">{{ m.fullname }}</router-link>
            <span v-if="m.deceased_date">&nbsp;(deceased: {{ m.deceased_date }})</span>
          </td>
          <td class="table-value left">{{ m.gender }}</td>
          <td class="table-value left"><span v-if="m.year_of_birth">{{ m.year_of_birth }} ({{ new Date().getFullYear() - m.year_of_birth }})</span></td>
          <td class="table-value left">{{ m.relationship }}</td>
          <td class="table-value left">{{ m.marital_status }}</td>
          <td class="table-value left">{{ m.education }}</td>
          <td class="table-value left">{{ m.primary_occupation || '—' }}</td>
        </tr>
      </tbody>
      <TableCopyFooter :colspan="8" />
    </v-table>

    <v-dialog v-model="showAddDialog" max-width="800">
      <v-card>
        <v-card-title class="table-heading">Add Member</v-card-title>
        <v-card-text>
          <v-alert v-if="addError" type="error" variant="tonal" class="mb-4">{{ addError }}</v-alert>
          <PersonFormFields v-model="addForm" :validation-errors="addValidationErrors" />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" :disabled="addSaving" @click="showAddDialog = false">Cancel</v-btn>
          <v-btn color="primary" variant="tonal" :loading="addSaving" @click="submitAdd">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<style scoped>
.member-badge {
  display: inline-block;
  font-size: 0.7rem;
  font-weight: 700;
  border-radius: 3px;
  padding: 1px 5px;
  margin: 0 2px;
}
.member-disabled {
  background-color: rgba(255, 193, 7, 0.18);
}
.hh-badge {
  background-color: rgba(25, 118, 210, 0.15);
  color: #1565c0;
}
.co-badge {
  background-color: rgba(25, 210, 133, 0.2);
  color: #1b7a4e;
}
.disabled-badge {
  background-color: rgba(226, 139, 98, 0.2);
  color: #442008;
}
th {
  font-size: 0.78rem;
  white-space: nowrap;
}
</style>
