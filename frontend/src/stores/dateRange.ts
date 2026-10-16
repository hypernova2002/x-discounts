import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import type { DateRange } from '@/components/DateRangePicker.vue'

const STORAGE_KEY = 'x-discounts.date-range'

function readStored(): DateRange | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<DateRange>
    return typeof parsed.from === 'string' && typeof parsed.to === 'string' ? { from: parsed.from, to: parsed.to } : null
  } catch {
    return null
  }
}

// One date range shared by every analytics view's DateRangePicker — picking
// "90 days" on Coupons and opening Promotions shows "90 days" there too.
// localStorage (not just in-memory state) means it also survives a reload.
export const useDateRangeStore = defineStore('dateRange', () => {
  const range = ref<DateRange | null>(readStored())

  watch(range, (value) => {
    if (value) localStorage.setItem(STORAGE_KEY, JSON.stringify(value))
  })

  return { range }
})
