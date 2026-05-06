<script setup>
import { inject, ref, reactive, watch } from 'vue'

const axiosSecure = inject('axiosSecure')
const person = ref(null)
const loading = ref(false)
const error = ref('')
const reversing = ref(false)
const editingName = ref(false)
const editingContact = ref(false)
const editingNrc = ref(false)
const draft = reactive({})
const saving = reactive({})

const nameFields = [
  { key: 'firstname',  label: 'First' },
  { key: 'middlename', label: 'Middle' },
  { key: 'lastname',   label: 'Last' },
]

const props = defineProps({
  personId: {
    type: Number,
    required: true
  },
  title: {
    type: String,
    default: 'Person:'
  }
})

watch(() => props.personId, async (newPersonId) => {
  if (newPersonId) {
    loading.value = true
    error.value = ''
    person.value = null
    editingName.value = false
    editingContact.value = false
    editingNrc.value = false
    try {
      const response = await axiosSecure.get(`/person/${newPersonId}`)
      person.value = response.data
    } catch (err) {
      console.error('Failed to load person data:', err)
      error.value = 'An error occurred while loading the person data. Please try again.'
    } finally {
      loading.value = false
    }
  }
}, { immediate: true })

async function reverseName () {
  reversing.value = true
  try {
    await axiosSecure.put(`/person/${props.personId}/reverse-name`)
    const response = await axiosSecure.get(`/person/${props.personId}`)
    person.value = response.data
  } catch (err) {
    console.error('Failed to reverse name:', err)
    error.value = 'Failed to reverse name.'
  } finally {
    reversing.value = false
  }
}

function startEditName () {
  draft.firstname  = person.value.firstname  ?? ''
  draft.middlename = person.value.middlename ?? ''
  draft.lastname   = person.value.lastname   ?? ''
  editingName.value = true
}

function startEditContact () {
  draft.contact = person.value.contact ?? ''
  editingContact.value = true
}

function startEditNrc () {
  draft.nrc = person.value.nrc ?? ''
  editingNrc.value = true
}

async function saveField (field) {
  saving[field] = true
  try {
    await axiosSecure.patch(`/person/${props.personId}`, { [field]: draft[field] })
    const response = await axiosSecure.get(`/person/${props.personId}`)
    person.value = response.data
  } catch (err) {
    console.error(`Failed to save ${field}:`, err)
    error.value = `Failed to save ${field}.`
  } finally {
    saving[field] = false
  }
}

async function saveContact () {
  await saveField('contact')
  editingContact.value = false
}

async function saveNrc () {
  await saveField('nrc')
  editingNrc.value = false
}
</script>

<template>
  <v-row no-gutters v-if="person">

    <!-- Fullname -->
    <v-col cols="12">
      <b>{{ title }}</b>&nbsp;{{ person.fullname }}
      <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-swap-horizontal" :loading="reversing" @click="reverseName"
        style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
      <v-btn size="x-small" class="ml-1 text-grey" variant="text" :icon="editingName ? 'mdi-pencil-off' : 'mdi-pencil'"
        @click="editingName ? (editingName = false) : startEditName()"
        style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
    </v-col>

    <!-- Name edit fields -->
    <template v-if="editingName">
      <v-col cols="12" v-for="f in nameFields" :key="f.key" class="d-flex align-center py-1 pl-4">
        <span class="text-caption text-medium-emphasis mr-2" style="min-width: 52px">{{ f.label }}</span>
        <v-text-field v-model="draft[f.key]" density="compact" hide-details variant="underlined"
          style="max-width: 180px" />
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check" :loading="saving[f.key]"
          @click="saveField(f.key)"  />
      </v-col>
    </template>

    <!-- Contact -->
    <v-col cols="12" class="d-flex align-center">
      <template v-if="!editingContact">
        <b>Contact</b>&nbsp;{{ person.contact }}
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil" @click="startEditContact"
          style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
      </template>
      <template v-else>
        <b>Contact</b>&nbsp;
        <v-text-field v-model="draft.contact" density="compact" hide-details variant="underlined"
          style="max-width: 200px" />
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check" :loading="saving.contact"
          @click="saveContact" />
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close" @click="editingContact = false" />
      </template>
    </v-col>

    <!-- NRC -->
    <v-col cols="12" class="d-flex align-center">
      <template v-if="!editingNrc">
        <b>NRC</b>&nbsp;{{ person.nrc }}
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-pencil" @click="startEditNrc"
          style="height: 1em; width: 1em; min-height: unset; min-width: unset; vertical-align: middle;" />
      </template>
      <template v-else>
        <b>NRC</b>&nbsp;
        <v-text-field v-model="draft.nrc" density="compact" hide-details variant="underlined"
          style="max-width: 200px" />
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-check" :loading="saving.nrc"
          @click="saveNrc" />
        <v-btn size="x-small" class="ml-1 text-grey" variant="text" icon="mdi-close" @click="editingNrc = false" />
      </template>
    </v-col>

  </v-row>
</template>
