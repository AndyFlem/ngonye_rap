<script setup>
import { ref } from 'vue'
import NavigationDrawer from './NavigationDrawer.vue'

const drawerOpen = ref(false)
</script>

<template>
  <div>
    <v-app-bar app color="primary" theme="dark">
      <v-app-bar-nav-icon
        icon="mdi-menu"
        @click="drawerOpen = !drawerOpen"
        class="ml-2"
      ></v-app-bar-nav-icon>

      <v-app-bar-title class="text-h6 font-weight-bold">
        Ngonye RAP
      </v-app-bar-title>

      <v-spacer></v-spacer>
    </v-app-bar>

    <NavigationDrawer
      v-model="drawerOpen"
      @close-drawer="drawerOpen = false"
    />
  </div>
</template>

<style scoped>
</style>
