<script setup>
import { inject } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const user = inject('user')
const signout = inject('signout')

defineProps({
  modelValue: Boolean
})

const emit = defineEmits(['update:modelValue', 'close-drawer'])

const handleDrawerUpdate = (val) => {
  emit('update:modelValue', val)
}

const handleHomeClick = () => {
  router.push('/home')
  emit('close-drawer')
}

const handleHouseholdsClick = () => {
  router.push('/households')
  emit('close-drawer')
}

const handleReplacementsClick = () => {
  router.push('/replacements')
  emit('close-drawer')
}

const handleParcelsClick = () => {
  router.push('/parcels')
  emit('close-drawer')
}

const handleFishersClick = () => {
  router.push('/fishers')
  emit('close-drawer')
}

const handleLivelihoodRestorationClick = () => {
  router.push('/livelihood-restoration')
  emit('close-drawer')
}

const handleUsersClick = () => {
  router.push('/users')
  emit('close-drawer')
}

const handleLogout = () => {
  signout()
  router.push('/login')
  emit('close-drawer')
}
</script>

<template>
  <v-navigation-drawer
    :model-value="modelValue"
    @update:model-value="handleDrawerUpdate"
    temporary
    width="280"
  >
    <v-list>
      <v-list-item
        prepend-icon="mdi-home"
        title="Home"
        @click="handleHomeClick"
      ></v-list-item>
      <v-list-item
        prepend-icon="mdi-account-group"
        title="Households"
        @click="handleHouseholdsClick"
      ></v-list-item>
      <v-list-item
        prepend-icon="mdi-home-city"
        title="Replacement Structures"
        @click="handleReplacementsClick"
      ></v-list-item>
      <v-list-item
        prepend-icon="mdi-map"
        title="Land Parcels"
        @click="handleParcelsClick"
      ></v-list-item>
      <v-list-item
        prepend-icon="mdi-fish"
        title="Fishers"
        @click="handleFishersClick"
      ></v-list-item>
      <v-list-item
        prepend-icon="mdi-sprout"
        title="Livelihood Restoration"
        @click="handleLivelihoodRestorationClick"
      ></v-list-item>
      <v-list-item
        v-if="user.isAdmin"
        prepend-icon="mdi-account-multiple"
        title="Users"
        @click="handleUsersClick"
      ></v-list-item>
    </v-list>

    <v-spacer></v-spacer>

    <v-divider class="my-2"></v-divider>

    <v-list>
      <v-list-item class="mb-2">
        <div class="d-flex flex-column">
          <span class="text-caption font-weight-bold">Logged in as:</span>
          <span class="text-body2 text-truncate">{{ user.email }}</span>
        </div>
      </v-list-item>

      <v-list-item
        prepend-icon="mdi-logout"
        title="Logout"
        @click="handleLogout"
      ></v-list-item>
    </v-list>
  </v-navigation-drawer>
</template>

<style scoped>
</style>
