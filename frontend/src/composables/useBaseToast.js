import { useToast } from 'openvue/usetoast'

// Thin wrapper so feature code never imports 'openvue/usetoast' directly — same
// return API (toast.add(...)) as the underlying composable, so this is a pure
// import-path swap at every call site, no behavior change.
export function useBaseToast() {
  return useToast()
}
