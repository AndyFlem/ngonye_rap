<script setup>
import { computed, inject, onMounted, ref } from 'vue'

const props = defineProps({
  pah: { type: String, default: null },
  nhs: { type: String, default: null },
  newIcaRequired: { type: Boolean, default: false }
})

const emit = defineEmits(['ica-added', 'update:newIcaRequired'])

const axiosSecure = inject('axiosSecure')

const icas = ref([])
const loading = ref(false)
const error = ref('')

const dialog = ref(false)
const newIcaLink = ref('')
const newIcaDateSigned = ref('')

const saving = ref(false)
const saveError = ref('')
const downloadingCert = ref(false)



const togglingFlag = ref(false)

const icasUrl = computed(() =>
  props.nhs
    ? `/fishers/${encodeURIComponent(props.nhs)}/icas`
    : `/households/${encodeURIComponent(props.pah)}/icas`
)

async function downloadCertificate () {
  downloadingCert.value = true
  try {
    const reqURL = props.nhs
      ? `/fishers/${encodeURIComponent(props.nhs)}/certificate`
      : `/households/${encodeURIComponent(props.pah)}/certificate`

    const pahno = props.nhs ? ref(props.nhs) : ref(props.pah)
    const response = await axiosSecure.get( reqURL, { responseType: 'blob' } )
    
    const url = URL.createObjectURL(response.data)
    const a = document.createElement('a')
    a.href = url
    const dateString = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    a.download = `${pahno.value} ${dateString}.docx`
    a.click()
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('Failed to download certificate:', err)
    error.value = 'Failed to generate certificate.'
  } finally {
    downloadingCert.value = false
  }
}

async function toggleNewIcaRequired () {
  togglingFlag.value = true
  try {
    const newVal = !props.newIcaRequired
    const url = props.nhs
      ? `/fishers/${encodeURIComponent(props.nhs)}`
      : `/households/${encodeURIComponent(props.pah)}`
    await axiosSecure.patch(url, { new_ica_required: newVal })
    emit('update:newIcaRequired', newVal)
    emit('ica-added')
  } catch (err) {
    console.error('Failed to toggle new ICA required:', err)
  } finally {
    togglingFlag.value = false
  }
}

const editingIcaId = ref(null)
const draftEditIcaLink = ref('')
const savingEdit = ref(false)

const currentIca = computed(() => icas.value.find(i => i.is_current) ?? null)

async function loadIcas () {
  loading.value = true
  error.value = ''
  try {
    const r = await axiosSecure.get(icasUrl.value)
    icas.value = Array.isArray(r.data) ? r.data : []
  } catch (err) {
    error.value = 'Failed to load ICAs.'
  } finally {
    loading.value = false
  }
}

function openDialog () {
  newIcaLink.value = ''
  newIcaDateSigned.value = ''

  saveError.value = ''
  dialog.value = true
}

async function submitIca () {
  if (!newIcaLink.value.trim() && !newIcaDateSigned.value) {
    saveError.value = 'Please enter an ICA link or date signed.'
    return
  }
  saving.value = true
  saveError.value = ''
  try {
    await axiosSecure.post(icasUrl.value, {
      ica_link: newIcaLink.value.trim() || null,
      date_signed: newIcaDateSigned.value || null,

    })
    dialog.value = false
    await loadIcas()
    emit('ica-added')
  } catch (err) {
    saveError.value = 'Failed to save ICA.'
  } finally {
    saving.value = false
  }
}

function startEdit (ica) {
  editingIcaId.value = ica.ica_id
  draftEditIcaLink.value = ica.ica_link ?? ''
}

async function saveEdit (ica) {
  savingEdit.value = true
  try {
    await axiosSecure.patch(`/icas/${ica.ica_id}`, {
      ica_link: draftEditIcaLink.value.trim() || null
    })
    editingIcaId.value = null
    await loadIcas()
  } catch (err) {
    console.error('Failed to update ICA link:', err)
  } finally {
    savingEdit.value = false
  }
}

const getSafeUrl = (value) => {
  if (!value) return null
  const url = String(value).trim()
  return /^https?:\/\//i.test(url) ? url : null
}

onMounted(loadIcas)
defineExpose({ loadIcas, currentIca })
</script>

<template>
  <v-card elevation="1" class="mt-4">
    <v-card-title class="d-flex align-center table-heading">
      <span class="text-title-small">Signed ICAs</span>
      <v-spacer />
      <div>
        <v-btn
          @click="downloadCertificate"
          prepend-icon="mdi-file-word-outline"
          variant="tonal"
          size="small"
          class="mr-2"
          color="green"
          title="Generate new ICA"
          :loading="downloadingCert"
        >Generate</v-btn>        
      </div>
      <v-btn
        :color="newIcaRequired ? 'orange' : 'grey'"
        :variant="newIcaRequired ? 'tonal' : 'outlined'"
        size="small"
        class="mr-2"
        :loading="togglingFlag"
        @click="toggleNewIcaRequired"
      >
        {{ newIcaRequired ? 'New ICA Required' : 'New ICA Req.' }}
      </v-btn>
      <v-btn size="small" color="primary" variant="tonal" prepend-icon="mdi-plus" @click="openDialog">
        Add ICA
      </v-btn>
    </v-card-title>

    <v-progress-linear v-if="loading" indeterminate color="primary" />

    <v-alert v-if="error" type="error" variant="tonal" class="mx-4 my-2">{{ error }}</v-alert>

    <v-card-text v-if="icas.length > 0" class="pa-0">
      <v-table density="compact">
        <thead>
          <tr>
            <th>Date Signed</th>
            <th>ICA Link</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="ica in icas" :key="ica.ica_id">
            <td class="table-value left" style="white-space: nowrap;">{{ ica.date_signed || '—' }}</td>
            <td class="table-value left">
              <template v-if="editingIcaId !== ica.ica_id">
                <span>{{ ica.ica_link ? decodeURIComponent(ica.ica_link.split('/').pop().split('?')[0]) : '—' }}</span>
                <v-btn size="x-small" variant="text" icon="mdi-pencil" class="ml-1 text-grey"
                  style="height:1em;width:1em;min-height:unset;min-width:unset"
                  @click="startEdit(ica)" />
                <v-btn v-if="getSafeUrl(ica.ica_link)"
                  :href="getSafeUrl(ica.ica_link)"
                  size="x-small" variant="text" icon="mdi-open-in-new"
                  target="_blank" rel="noopener noreferrer" class="ml-1" />
              </template>
              <template v-else>
                <v-text-field v-model="draftEditIcaLink" density="compact" hide-details
                  variant="underlined" style="max-width:320px" placeholder="https://..." />
                <v-btn size="x-small" variant="text" icon="mdi-check" class="ml-1 text-grey"
                  :loading="savingEdit" @click="saveEdit(ica)" />
                <v-btn size="x-small" variant="text" icon="mdi-close" class="ml-1 text-grey"
                  @click="editingIcaId = null" />
              </template>
            </td>
            <td style="white-space: nowrap;">
              <v-chip v-if="ica.is_current" size="x-small" color="green">Current</v-chip>
            </td>
            <td style="width: 40px;"></td>
          </tr>
        </tbody>
      </v-table>
    </v-card-text>
  </v-card>

  <v-dialog v-model="dialog" max-width="500">
    <v-card>
      <v-card-title>Add ICA</v-card-title>
      <v-card-text>
        <v-alert v-if="saveError" type="error" variant="tonal" class="mb-3">{{ saveError }}</v-alert>
        <v-text-field v-model="newIcaLink" label="ICA Link" placeholder="https://..."
          density="compact" variant="outlined" class="mb-3" />
        <v-text-field v-model="newIcaDateSigned" label="Date Signed" type="date"
          density="compact" variant="outlined" />
      </v-card-text>
      <v-card-actions>
        <v-spacer />
        <v-btn variant="text" :disabled="saving" @click="dialog = false">Cancel</v-btn>
        <v-btn color="primary" variant="tonal" :loading="saving" @click="submitIca">Save</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>
