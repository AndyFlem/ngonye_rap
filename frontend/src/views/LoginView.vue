<script setup>
import { ref, inject } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const signin = inject('signin')

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const showPassword = ref(false)

const handleLogin = async () => {
  error.value = ''
  loading.value = true

  try {
    const user = await signin(email.value, password.value)
    // Signin successful, navigate to home
    router.push('/home')
  } catch (err) {
    error.value = 'Invalid email or password'
    console.error('Login error:', err)
  } finally {
    loading.value = false
  }
}

const handleKeydown = (event) => {
  if (event.key === 'Enter') {
    handleLogin()
  }
}
</script>

<template>
  <v-container class="fill-height d-flex justify-center align-center">
    <v-card class="mx-auto" width="400">
      <v-card-title class="text-h5 font-weight-bold mb-4">
        Ngonye RAP Login
      </v-card-title>

      <v-card-text>
        <v-form @submit.prevent="handleLogin">
          <v-text-field
            v-model="email"
            label="Email Address"
            type="email"
            outlined
            required
            class="mb-4"
            @keydown="handleKeydown"
          ></v-text-field>

          <v-text-field
            v-model="password"
            :label="showPassword ? 'Password' : 'Password'"
            :type="showPassword ? 'text' : 'password'"
            outlined
            required
            class="mb-4"
            @keydown="handleKeydown"
            :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
            @click:append-inner="showPassword = !showPassword"
          ></v-text-field>

          <v-alert
            v-if="error"
            type="error"
            class="mb-4"
            closable
            @input="error = ''"
          >
            {{ error }}
          </v-alert>

          <v-btn
            block
            color="primary"
            size="large"
            :loading="loading"
            @click="handleLogin"
          >
            Login
          </v-btn>
        </v-form>
      </v-card-text>

      <v-card-subtitle class="text-center mt-4 text-grey">
        <small>Use your registered email address and password to login.</small>
      </v-card-subtitle>
    </v-card>
  </v-container>
</template>

<style scoped>
</style>
