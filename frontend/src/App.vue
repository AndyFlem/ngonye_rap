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

.table-label {
  font-weight: 500;
  width: 40%;
}

.table-total {
  background-color: rgba(25, 118, 210, 0.1);
  font-weight: 600;
}

.table-total .table-value {
  color: rgb(25, 118, 210);
}

.left {
  text-align: left;
}
.right {
  text-align: right;
}
.center {
  text-align: center;
}
</style>
