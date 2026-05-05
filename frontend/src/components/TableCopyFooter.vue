<script setup>
import { ref } from 'vue'
import { copyTableAsCsv } from '@/utils/formatters'

const props = defineProps({
  colspan: { type: Number, required: true }
})

const copied = ref(false)

const handleCopy = (event) => {
  const tableEl = event.target.closest('table')
  if (!tableEl) return
  copyTableAsCsv(tableEl).then(() => {
    copied.value = true
    setTimeout(() => { copied.value = false }, 1800)
  }).catch(() => {})
}
</script>

<template>
  <tfoot>
    <tr class="copy-footer-row">
      <td class="right pr-0" :colspan="props.colspan">
        <v-btn variant="flat" color="secondary" size="small" density="compact" @click="handleCopy">
          {{ copied ? 'Copied!' : 'Copy data' }}
        </v-btn>
      </td>
    </tr>
  </tfoot>
</template>

<style scoped>
.copy-footer-row {
  --v-table-row-height: auto;
}
.copy-footer-row td {
  padding-top: 3px;
  padding-bottom: 3px;
}
</style>
