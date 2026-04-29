<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <v-app>
    <router-view />
  </v-app>
</template>

<style>
.table-value {
  text-align: right;
  font-family: monospace;
}
</style>
