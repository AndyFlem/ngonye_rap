<script setup>
import { inject } from 'vue'
import { onMounted, ref, computed } from 'vue'
import TopBar from '@/components/TopBar.vue'
import TableCopyFooter from '@/components/TableCopyFooter.vue'
import { formatCurrency, formatArea } from '@/utils/formatters'

const households = ref(null)
const replacementStructs = ref(null)
const replacementLand = ref(null)
const landAquisition = ref(null)
const loading = ref(false)
const error = ref('')


const landClassRows = computed(() => {
  const classes = landAquisition.value?.landClasses ?? []
  const groups = new Map()
  for (const item of classes) {
    if (!groups.has(item.land_class)) groups.set(item.land_class, [])
    groups.get(item.land_class).push(item)
  }
  const rows = []
  let grandTotal = 0
  let grandPermTotal = 0
  let grandTempTotal = 0
  for (const [landClass, items] of groups) {
    const groupTotal = items.reduce((sum, i) => sum + i.total, 0)
    const groupPermTotal = items.reduce((sum, i) => sum + i.permanent_total, 0)
    const groupTempTotal = items.reduce((sum, i) => sum + i.temporary_total, 0)
    grandTotal += groupTotal
    grandPermTotal += groupPermTotal
    grandTempTotal += groupTempTotal
    rows.push({ type: 'group', label: landClass })
    for (const item of [...items].sort((a, b) => b.total - a.total)) {
      rows.push({ type: 'item', land_zone: item.land_zone, total: item.total, permanent_total: item.permanent_total, temporary_total: item.temporary_total })
    }
    rows.push({ type: 'subtotal', label: landClass, total: groupTotal, permanent_total: groupPermTotal, temporary_total: groupTempTotal })
  }
  rows.push({ type: 'grand-total', total: grandTotal, permanent_total: grandPermTotal, temporary_total: grandTempTotal })
  return rows
})

const replacementLandRows = computed(() => {
  const classes = replacementLand.value?.classes ?? []
  const groups = new Map()
  for (const item of classes) {
    if (!groups.has(item.land_class)) groups.set(item.land_class, [])
    groups.get(item.land_class).push(item)
  }
  const rows = []
  let grandTotal = 0
  for (const [landClass, items] of groups) {
    const groupTotal = items.reduce((sum, i) => sum + (i.total ?? 0), 0)
    grandTotal += groupTotal
    rows.push({ type: 'group', label: landClass })
    for (const item of [...items].sort((a, b) => (b.total ?? 0) - (a.total ?? 0))) {
      rows.push({ type: 'item', land_zone: item.land_zone, total: item.total })
    }
    rows.push({ type: 'subtotal', label: landClass, total: groupTotal })
  }
  rows.push({ type: 'grand-total', total: grandTotal })
  return rows
})

//const user = inject('user')
const axiosSecure = inject('axiosSecure')

const load = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await axiosSecure.get(`/households_summary`)
    households.value = response.data || null

    const replacementsResponse = await axiosSecure.get(`/replacements/summary`)
    replacementStructs.value = replacementsResponse.data.structures || null
    replacementLand.value = replacementsResponse.data.land || null

    const landAquisitionResponse = await axiosSecure.get(`/land/summary`)
    landAquisition.value = landAquisitionResponse.data || null

  } catch (err) {
    error.value = 'Failed to load.'
    console.error('Failed to load:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  load()
})


</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <h3 class="text-h3 mb-4">
              Households (PAH)
            </h3>
            <v-table density="compact" v-if="households">
              <thead>
                <tr>
                <th class="table-heading">Affected households</th>
                <th class="table-heading right">{{ households.ICARequiredHouseholds }}</th>
                </tr>
              </thead>
              <tbody>
              <tr>
                <td>Vulnerable</td>
                <td class="table-value">{{ households.vulnerableHouseholds }}</td>
              </tr>
              <tr>
                <td>Physically Displaced</td>
                <td class="table-value">{{ households.physicallyDisplacedHouseholds }}</td>
              </tr>
              <tr>
                <td>Replacement Structure Households</td>
                <td class="table-value">{{ households.replacementHouseholds }}</td>
              </tr>
              <tr>
                <td>Replacement Land Households</td>
                <td class="table-value">{{ households.replacementLandHouseholds }}</td>
              </tr>
              <tr>
                <td>Flagged Households</td>
                <td class="table-value">{{ households.followUpFlagHouseholds }}</td>
              </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <h3 class="text-h3 mb-4">
              Compensation Agreements (ICAs)
            </h3>
            <v-table density="compact" v-if="households">
              <thead>
                <tr>
                <th class="table-heading">Affected households</th>
                <th class="table-heading right">{{ households.ICARequiredHouseholds }}</th>
                </tr>
              </thead>
              <tbody>
              <tr>
                <td>Signed</td>
                <td class="table-value">{{ households.signedHouseholds }}</td>
              </tr>
              <tr>
                <td>Unsigned</td>
                <td class="table-value">{{ households.unsignedHouseholds }}</td>
              </tr>
              <tr>
                <td>Revised ICA Required</td>
                <td class="table-value">{{ households.newICARequiredHouseholds }}</td>
              </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <h3 class="text-h3 mb-4">
              Compensation
            </h3>
            <v-table density="compact" v-if="households">
              <thead>
                <tr>
                  <th class="table-heading"></th>
                  <th class="table-heading right">K000s</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Primary Structures</td>
                  <td class="table-value">{{ formatCurrency(households.totalPrimaryStructuresCompensation/1000) }}</td>
                </tr>
                <tr>
                  <td>Secondary Structures</td>
                  <td class="table-value">{{ formatCurrency(households.totalSecondaryStructuresCompensation/1000) }}</td>
                </tr>
                <tr>
                  <td>Land Purchase</td>
                  <td class="table-value">{{ formatCurrency(households.totalLandCompensation/1000) }}</td>
                </tr>
                <tr>
                  <td>Land Lease</td>
                  <td class="table-value">{{ formatCurrency(households.totalLeaseCosts/1000) }}</td>
                </tr>
                <tr>
                  <td>Trees</td>
                  <td class="table-value">{{ formatCurrency(households.totalTreesCompensation/1000) }}</td>
                </tr>
                <tr>
                  <td>Crops</td>
                  <td class="table-value">{{ formatCurrency(households.totalCropCompensation/1000) }}</td>
                </tr>
                <tr>
                  <td>Allowances</td>
                  <td class="table-value">{{ formatCurrency(households.totalAllowances/1000) }}</td>
                </tr>
                <tr>
                  <td class="table-total">Total Compensation</td>
                  <td class="table-total table-value">{{ formatCurrency(households.totalCompensation/1000) }}</td>
                </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="12" sm="8" md="6">
            <h3 class="text-h3 mb-4">
              Land Aquisition
            </h3>
            <v-table v-if="landAquisition" density="compact">
              <thead>
                <tr>
                  <th class="table-heading">Zone</th>
                  <th class="table-heading right">Permanent</th>
                  <th class="table-heading right">Temporary</th>
                  <th class="table-heading right">Total</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="(row, i) in landClassRows" :key="i">
                  <tr v-if="row.type === 'group'" class="bg-grey-lighten-3">
                    <td colspan="4"><strong>{{ row.label }}</strong></td>
                  </tr>
                  <tr v-else-if="row.type === 'item'">
                    <td>{{ row.land_zone }}</td>
                    <td class="table-value">{{ formatArea(row.permanent_total) }}</td>
                    <td class="table-value">{{ formatArea(row.temporary_total) }}</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                  <tr v-else-if="row.type === 'subtotal'" class="table-total">
                    <td>{{ row.label }} Total</td>
                    <td class="table-value">{{ formatArea(row.permanent_total) }}</td>
                    <td class="table-value">{{ formatArea(row.temporary_total) }}</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                  <tr v-else-if="row.type === 'grand-total'" class="table-total">
                    <td>Total</td>
                    <td class="table-value">{{ formatArea(row.permanent_total) }}</td>
                    <td class="table-value">{{ formatArea(row.temporary_total) }}</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                </template>
              </tbody>
              <TableCopyFooter :colspan="4" />
            </v-table>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="12" sm="8" md="6">
            <h3 class="text-h3 mb-4">
              Replacement Land
            </h3>
            <v-table v-if="replacementLand" density="compact">
              <thead>
                <tr>
                  <th class="table-heading">Zone</th>
                  <th class="table-heading right">Area</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="(row, i) in replacementLandRows" :key="i">
                  <tr v-if="row.type === 'group'" class="bg-grey-lighten-3">
                    <td colspan="2"><strong>{{ row.label }}</strong></td>
                  </tr>
                  <tr v-else-if="row.type === 'item'">
                    <td>{{ row.land_zone }}</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                  <tr v-else-if="row.type === 'subtotal'" class="table-total">
                    <td>{{ row.label }} Total</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                  <tr v-else-if="row.type === 'grand-total'" class="table-total">
                    <td>Total</td>
                    <td class="table-value">{{ formatArea(row.total) }}</td>
                  </tr>
                </template>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="12" sm="8" md="6">
            <h3 class="text-h3 mb-4">
              Replacement Structures
            </h3>
            <v-table v-if="replacementStructs" density="compact">
              <thead class="">
                <tr>
                  <th class="table-heading">Replacement Option</th>
                  <th class="table-heading center">Count</th>
                  <th class="table-heading center">Protected</th>
                  <th class="table-heading center">Est Cost K000s</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in replacementStructs.options" :key="item.id">
                  <td>
                    {{ item.replacement_option }}
                  </td>
                  <td class="table-value center">
                    {{ item.count }}
                  </td>
                  <td class="table-value center">
                    {{ item.protected_count }}
                  </td>
                  <td class="table-value center">
                    <span v-if="item.value && item.value>0">{{ formatCurrency(item.value/1000)  }}</span>
                    <span v-else>unknown</span>
                  </td>
                </tr>
                <tr class="table-total">
                  <td>Total:</td>
                  <td class="center">{{ replacementStructs.total }}</td>
                  <td class="center">{{ replacementStructs.totalProtected }}</td>
                  <td class="center">{{ formatCurrency(replacementStructs.totalValue/1000) }}</td>
                </tr>
              </tbody>
              <TableCopyFooter :colspan="4" />
            </v-table>
            <v-table class="mt-5" v-if="replacementStructs" density="compact">
              <thead class="table-header">
                <tr>
                  <th class="table-heading">Replacement Location Option</th>
                  <th class="table-heading center">Count</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in replacementStructs.icaOptionStructureLocation" :key="item.id">
                  <td>
                    <span v-if="item.icaoption_structure_location">{{ item.icaoption_structure_location }}</span>
                    <span v-else>Not specified</span>
                  </td>
                  <td class="table-value center">
                    {{ item.count }}
                  </td>
                </tr>
                <tr class="table-total">
                  <td>Total:</td>
                  <td class="center">{{ replacementStructs.total }}</td>
                </tr>
              </tbody>
              <TableCopyFooter :colspan="2" />
            </v-table>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </div>
</template>

<style scoped>

</style>
