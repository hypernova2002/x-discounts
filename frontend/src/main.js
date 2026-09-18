import './assets/main.css'
import 'primeicons/primeicons.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import OpenVue from 'openvue/config'
import Aura from '@openvue/themes/aura'
import ToastService from 'openvue/toastservice'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'
import { i18n } from './i18n'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
// Global default stays themed (Aura) so components not yet migrated to a
// components/base/ wrapper are unaffected — each Base* wrapper opts its own
// OpenVue primitive into unstyled mode individually via the `unstyled` prop,
// which always overrides this default (see @openvue/core/basecomponent's
// `isUnstyled` getter). The global default only flips to unstyled once every
// component in use has a Base wrapper and Aura is no longer needed at all.
app.use(OpenVue, { theme: { preset: Aura } })
app.use(ToastService)
app.use(i18n)

// Kick off auth restore as early as possible; the router guard awaits this same
// (memoized) call before evaluating auth state, so it's never seen mid-restore.
useAuthStore(pinia).restore()

app.mount('#app')
