import { ref, onUnmounted } from 'vue'
import { onBeforeRouteLeave } from 'vue-router'

// Blocks navigation away from a form with unsaved changes until the user
// confirms. `getIsDirty` is called fresh on every navigation attempt (not
// captured once), so it should read whatever reactive dirty-check the caller
// already has (e.g. a deep-equal against the form's initial snapshot).
//
// The in-app route guard returns a Promise that resolves once the user picks
// an option in the dialog this composable drives — this app's router guards
// are already return-value style (see router/index.js's beforeEach), and
// vue-router supports awaiting an async guard, so there's no need for the
// older next()-callback API.
export function useUnsavedChangesGuard(getIsDirty) {
  const showDialog = ref(false)
  let pendingResolve = null
  let bypassNext = false

  onBeforeRouteLeave(() => {
    if (bypassNext) {
      bypassNext = false
      return true
    }
    if (!getIsDirty()) return true

    return new Promise((resolve) => {
      pendingResolve = resolve
      showDialog.value = true
    })
  })

  // For navigations this view already knows are intentional and not a real
  // "exit" — e.g. this app's campaign<->discount draft-preservation hand-off,
  // where leaving mid-edit is the expected flow, not an accidental exit.
  function bypassOnce() {
    bypassNext = true
  }

  function confirmLeave() {
    showDialog.value = false
    pendingResolve?.(true)
    pendingResolve = null
  }

  function cancelLeave() {
    showDialog.value = false
    pendingResolve?.(false)
    pendingResolve = null
  }

  // Tab close/refresh isn't a Vue Router navigation, so it needs its own listener.
  // Browsers ignore the custom message text and show their own generic prompt —
  // setting returnValue is what actually triggers that prompt.
  function onBeforeUnload(e) {
    if (getIsDirty()) {
      e.preventDefault()
      e.returnValue = ''
    }
  }

  window.addEventListener('beforeunload', onBeforeUnload)
  onUnmounted(() => window.removeEventListener('beforeunload', onBeforeUnload))

  return { showDialog, confirmLeave, cancelLeave, bypassOnce }
}
