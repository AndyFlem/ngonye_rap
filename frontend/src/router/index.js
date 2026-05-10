import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '@/views/LoginView.vue'
import HomeView from '@/views/HomeView.vue'
import HouseholdSearch from '@/views/HouseholdSearch.vue'
import HouseholdDetailsView from '@/views/HouseholdDetailsView.vue'
import ReplacementSearch from '@/views/ReplacementSearch.vue'
import ReplacementDetails from '@/views/ReplacementDetails.vue'
import ParcelSearch from '@/views/ParcelSearch.vue'
import ParcelDetails from '@/views/ParcelDetails.vue'

const routes = [
  {
    path: '/',
    redirect: (to) => {
      // If user is logged in, redirect to home, otherwise to login
      const user = localStorage.getItem('user')
      return user ? '/home' : '/login'
    }
  },
  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: { requiresAuth: false }
  },
  {
    path: '/home',
    name: 'Home',
    component: HomeView,
    meta: { requiresAuth: true }
  },
  {
    path: '/households',
    name: 'Households',
    component: HouseholdSearch,
    meta: { requiresAuth: true }
  },
  {
    path: '/households/:pah',
    name: 'HouseholdDetails',
    component: HouseholdDetailsView,
    meta: { requiresAuth: true }
  },
  {
    path: '/replacements',
    name: 'ReplacementStructures',
    component: ReplacementSearch,
    meta: { requiresAuth: true }
  },
  {
    path: '/replacements/:id',
    name: 'ReplacementDetails',
    component: ReplacementDetails,
    meta: { requiresAuth: true }
  },
  {
    path: '/parcels',
    name: 'Parcels',
    component: ParcelSearch,
    meta: { requiresAuth: true }
  },
  {
    path: '/parcels/:id',
    name: 'ParcelDetails',
    component: ParcelDetails,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

// Navigation guard to check authentication
router.beforeEach((to, from, next) => {
  const requiresAuth = to.meta.requiresAuth !== false && to.path !== '/login'
  const user = localStorage.getItem('user')

  if (requiresAuth && !user) {
    // Redirect to login if route requires auth and user is not logged in
    next('/login')
  } else if (to.path === '/login' && user) {
    // Redirect to home if already logged in and trying to access login
    next('/home')
  } else {
    next()
  }
})

export default router
