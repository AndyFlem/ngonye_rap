<script setup>
import { computed } from 'vue'

const mask = 'F1F6FBFCFEF9F4F3282B242C2F32B63C36383AB87553D198969B8915C9E57B7358807613D210BCE67DEBE9018F07090A830387E317198D1B711F23BBEC92DDG0AGCHBHEGGFGCG4G6EEH07GHCHF0G1G3GH2DG4043474H5G6H5CG2C1BFC52HC3D4C73E494B4C4EAAADA2A60DA40E9CA9A19FCF05CDCA20911D57B4275BD6HGB28451555E606365D8DFE16E6C6A668ADAH5B0H6H8HA3078G868GA94AE9G7F'
const zoom = 19.35
const server = 'https://maps.westernpower.org'

const props = defineProps({
  lon: { type: Number, required: false },
  lat: { type: Number, required: false }
})

const url = computed(() => {
  if (!props.lon || !props.lat) return null
  const params = new URLSearchParams({
    lon: props.lon,
    lat: props.lat,
    zoom: zoom.toString(),
    mask: mask
  })
  return `${server}?${params.toString()}`
})

</script>
<template>
    <v-btn v-if="url"
      :href="url"
      size="x-small" variant="text" icon="mdi-map-marker"
      target="_blank" rel="noopener noreferrer" class="ml-1"></v-btn>
</template>
