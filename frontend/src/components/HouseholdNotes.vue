<script setup>
import { inject, onMounted, ref } from 'vue'
import { formatDateTime } from '@/utils/formatters'

const props = defineProps({
  pah: { type: String, required: true }
})

const axiosSecure = inject('axiosSecure')
const user = inject('user')

const notes = ref([])
const loading = ref(false)
const error = ref('')

const dialog = ref(false)
const noteText = ref('')
const saving = ref(false)
const saveError = ref('')

async function loadNotes () {
  loading.value = true
  error.value = ''
  try {
    const res = await axiosSecure.get(`/households/${encodeURIComponent(props.pah)}/notes`)
    notes.value = Array.isArray(res.data) ? res.data : []
  } catch (err) {
    error.value = 'Failed to load notes.'
  } finally {
    loading.value = false
  }
}

function openDialog () {
  noteText.value = ''
  saveError.value = ''
  dialog.value = true
}

async function submitNote () {
  const text = noteText.value.trim()
  if (!text) { saveError.value = 'Note text is required.'; return }
  saving.value = true
  saveError.value = ''
  try {
    const res = await axiosSecure.post(`/households/${encodeURIComponent(props.pah)}/notes`, { note: text })
    notes.value.unshift(res.data)
    dialog.value = false
  } catch (err) {
    saveError.value = 'Failed to save note.'
  } finally {
    saving.value = false
  }
}

async function deleteNote (note) {
  try {
    await axiosSecure.delete(`/notes/${note.note_id}`)
    notes.value = notes.value.filter(n => n.note_id !== note.note_id)
  } catch (err) {
    error.value = 'Failed to delete note.'
  }
}

onMounted(loadNotes)
defineExpose({ loadNotes })
</script>

<template>
  <v-card elevation="1" class="mt-4">
    <v-card-title class="d-flex align-center table-heading">
      <span class="text-title-small">Notes</span>
      <v-spacer />
      <v-btn size="small" color="primary" variant="tonal" prepend-icon="mdi-plus" @click="openDialog">
        Add Note
      </v-btn>
    </v-card-title>

    <v-progress-linear v-if="loading" indeterminate color="primary" />

    <v-alert v-if="error" type="error" variant="tonal" class="mx-4 my-2">{{ error }}</v-alert>

    <v-card-text v-if="notes.length > 0" class="pa-0">
      <v-table density="compact" >
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
              <v-btn
                v-if="note.user_id === user.user_id"
                size="x-small"
                icon="mdi-delete"
                variant="text"
                color="red"
                @click="deleteNote(note)"
              />
            </td>
          </tr>
        </tbody>
      </v-table>
    </v-card-text>
  </v-card>

  <v-dialog v-model="dialog" max-width="560">
    <v-card>
      <v-card-title>Add Note</v-card-title>
      <v-card-text>
        <v-alert v-if="saveError" type="error" variant="tonal" class="mb-3">{{ saveError }}</v-alert>
        <v-textarea v-model="noteText" label="Note" rows="4" auto-grow variant="outlined" :disabled="saving" />
      </v-card-text>
      <v-card-actions>
        <v-spacer />
        <v-btn variant="text" :disabled="saving" @click="dialog = false">Cancel</v-btn>
        <v-btn color="primary" variant="tonal" :loading="saving" @click="submitNote">Save</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>
