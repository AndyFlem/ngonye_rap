<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '@/components/TopBar.vue'
import { formatCurrency, formatYesNo, formatDateTime } from '@/utils/formatters'
import PersonView from '@/components/PersonView.vue'

const axiosSecure = inject('axiosSecure')
const route = useRoute()

const replacement = ref(null)
const loading = ref(false)
const error = ref('')
const togglingFlag = ref(false)

async function toggleFollowupFlag () {
  togglingFlag.value = true
  try {
    const newVal = !replacement.value.flag_followup
    await axiosSecure.patch(`/replacements/${id.value}`, { flag_followup: newVal })
    replacement.value = { ...replacement.value, flag_followup: newVal }
  } catch (err) {
    console.error('Failed to toggle followup flag:', err)
    error.value = 'Failed to update followup flag.'
  } finally {
    togglingFlag.value = false
  }
}

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

const notes = ref([])
const notesLoading = ref(false)
const notesError = ref('')
const noteDialog = ref(false)
const noteText = ref('')
const noteSaving = ref(false)
const noteSaveError = ref('')

async function loadNotes () {
  notesLoading.value = true
  notesError.value = ''
  try {
    const res = await axiosSecure.get(`/replacements/${id.value}/notes`)
    notes.value = Array.isArray(res.data) ? res.data : []
  } catch (err) {
    notesError.value = 'Failed to load notes.'
  } finally {
    notesLoading.value = false
  }
}

function openNoteDialog () {
  noteText.value = ''
  noteSaveError.value = ''
  noteDialog.value = true
}

async function submitNote () {
  const text = noteText.value.trim()
  if (!text) { noteSaveError.value = 'Note text is required.'; return }
  noteSaving.value = true
  noteSaveError.value = ''
  try {
    const res = await axiosSecure.post(`/replacements/${id.value}/notes`, { note: text })
    notes.value.unshift(res.data)
    noteDialog.value = false
  } catch (err) {
    noteSaveError.value = 'Failed to save note.'
  } finally {
    noteSaving.value = false
  }
}

async function deleteNote (note) {
  try {
    await axiosSecure.delete(`/replacement_notes/${note.note_id}`)
    notes.value = notes.value.filter(n => n.note_id !== note.note_id)
  } catch (err) {
    notesError.value = 'Failed to delete note.'
  }
}

onMounted(() => { load(); loadNotes() })
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
            <v-chip color="green" class="mr-2" v-if="replacement.silumesii">Silumesii</v-chip>
            <v-btn
              :color="replacement.flag_followup ? 'purple' : 'grey'"
              :variant="replacement.flag_followup ? 'tonal' : 'outlined'"
              size="small"
              :loading="togglingFlag"
              @click="toggleFollowupFlag"
            >
              {{ replacement.flag_followup ? 'Flagged' : 'Flag' }}
            </v-btn>
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
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <v-card elevation="1" class="mt-4">
          <v-card-title class="d-flex align-center table-heading">
            <span class="text-title-small">Notes</span>
            <v-spacer />
            <v-btn size="small" color="primary" variant="tonal" prepend-icon="mdi-plus" @click="openNoteDialog">
              Add Note
            </v-btn>
          </v-card-title>

          <v-progress-linear v-if="notesLoading" indeterminate color="primary" />
          <v-alert v-if="notesError" type="error" variant="tonal" class="mx-4 my-2">{{ notesError }}</v-alert>

          <v-card-text v-if="notes.length > 0" class="pa-0">
            <v-table density="compact">
              <thead>
                <tr>
                  <th>Created By</th>
                  <th>Date</th>
                  <th>Note</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="note in notes" :key="note.note_id">
                  <td class="table-value left" style="white-space: nowrap;">{{ note.created_by }}</td>
                  <td class="table-value left" style="white-space: nowrap;">{{ formatDateTime(note.created_at) }}</td>
                  <td class="table-value left" style="white-space: pre-wrap;">{{ note.note }}</td>
                  <td style="width: 40px;">
                    <v-btn size="x-small" icon="mdi-delete" variant="text" color="red" @click="deleteNote(note)" />
                  </td>
                </tr>
              </tbody>
            </v-table>
          </v-card-text>
        </v-card>

        <v-dialog v-model="noteDialog" max-width="560">
          <v-card>
            <v-card-title>Add Note</v-card-title>
            <v-card-text>
              <v-alert v-if="noteSaveError" type="error" variant="tonal" class="mb-3">{{ noteSaveError }}</v-alert>
              <v-textarea v-model="noteText" label="Note" rows="4" auto-grow variant="outlined" :disabled="noteSaving" />
            </v-card-text>
            <v-card-actions>
              <v-spacer />
              <v-btn variant="text" :disabled="noteSaving" @click="noteDialog = false">Cancel</v-btn>
              <v-btn color="primary" variant="tonal" :loading="noteSaving" @click="submitNote">Save</v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </v-container>
    </v-main>
  </div>
</template>
