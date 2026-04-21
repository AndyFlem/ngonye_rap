import { createApp } from 'vue'
import './styles/global.css'

// Vuetify
import 'vuetify/styles'
import '@mdi/font/css/materialdesignicons.css'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { aliases, mdi } from 'vuetify/iconsets/mdi'

import appConfig from '@/config/appConfig'
import { registerPlugins } from '@/plugins'

import App from './App.vue'
import router from './router'

// eslint-disable-next-line no-undef
console.log('Ngonye RAP in', __APP_ENV__ , 'mode.')

let config = null
// eslint-disable-next-line no-undef
config = appConfig[__APP_ENV__]

const vuetify = createVuetify({
  components,
  directives,
  icons: {
      defaultSet: 'mdi',
      aliases,
      sets: {
        mdi,
      },
    }
})

const app = createApp(App)

app.use(router)
app.use(vuetify)

registerPlugins(app, {router, config})

app.mount('#app')
