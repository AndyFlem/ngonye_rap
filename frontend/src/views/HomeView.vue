<script setup>
import { inject } from 'vue'
import TopBar from '@/components/TopBar.vue'

const user = inject('user')
</script>

<template>
  <div>
    <TopBar />
    <v-main>
      <v-container class="pa-6">
        <v-row>
          <v-col cols="12">
            <h1 class="text-h3 mb-4">
              Welcome, {{ user.first_name || user.email }}!
            </h1>
            <p class="text-body1">
              You are now logged into the Ngonye Resettlement Action Plan (RAP) system.
            </p>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </div>
</template>

<style scoped>
</style>
