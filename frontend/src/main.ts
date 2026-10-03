import './assets/main.css'
import 'primeicons/primeicons.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import OpenVue from 'openvue/config'
import Aura from '@openvue/themes/aura'
import ToastService from 'openvue/toastservice'
import Tooltip from 'openvue/tooltip'

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
// Directive (not a component with its own tag), so there's no per-usage
// `unstyled` prop to opt into a Base wrapper's Tailwind styling the way
// components do — it just renders with the same global Aura theme every
// other not-yet-migrated element still falls back to (see the note above).
app.directive('tooltip', Tooltip)

// Kick off auth restore as early as possible; the router guard awaits this same
// (memoized) call before evaluating auth state, so it's never seen mid-restore.
useAuthStore(pinia).restore()

app.mount('#app')
