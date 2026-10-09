import { ref } from 'vue'
import { createExport, getExport, exportDownloadPath, type CreateExportInput } from '@/api/exports'
import { apiDownload } from '@/lib/api'
import { useAuthStore } from '@/stores/auth'

const POLL_INTERVAL_MS = 1500

// Shared by every view's export button (campaigns/customers/orders/project
// settings): creates the export, polls until the background job finishes,
// then auto-downloads it — same blob-download helper a direct synchronous
// download used to call, just fired once polling says the file is ready.
// Errors (including a failed export) are thrown, not toasted, so each call
// site keeps its own existing toast wording.
export function useExportDownload() {
  const auth = useAuthStore()
  const exporting = ref(false)

  function authParams() {
    return { token: auth.token ?? undefined, projectId: auth.project?.id }
  }

  async function runExport(exportType: CreateExportInput['export_type'], params: Record<string, unknown> = {}): Promise<void> {
    exporting.value = true
    try {
      let result = await createExport({ export_type: exportType, params }, authParams())
      while (result.status === 'pending' || result.status === 'processing') {
        await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS))
        result = await getExport(result.id, authParams())
      }

      if (result.status === 'failed') {
        throw new Error(result.error_message || 'Export failed')
      }

      await apiDownload(exportDownloadPath(result.id), { ...authParams(), filename: result.filename ?? `${exportType}.csv` })
    } finally {
      exporting.value = false
    }
  }

  return { exporting, runExport }
}
