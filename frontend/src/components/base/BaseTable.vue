<script setup>
import { computed, reactive, ref, useTemplateRef } from 'vue'
import { useI18n } from 'vue-i18n'
import Column from 'openvue/column'
import BaseDataTable from './BaseDataTable.vue'
import BaseInputText from './BaseInputText.vue'
import BaseInputNumber from './BaseInputNumber.vue'
import BaseMultiSelect from './BaseMultiSelect.vue'
import BaseSelect from './BaseSelect.vue'
import BaseButton from './BaseButton.vue'
import BasePopover from './BasePopover.vue'

// The single reusable, columns-driven table: every list view generates its
// table from this instead of hand-rolling search/pagination/column-chooser/
// sort/filter UI per view. Give it `data` + `columns` (each `{ field,
// header, sortable?, hideable?, filter? }` — `hideable: false` keeps a
// column always shown and out of the column-chooser, e.g. a primary
// identifier or an actions column; `filter` adds that field to the Filter
// panel's column picker, as one of:
//   { type: 'enum', options: [{ label, value }] }   value dropdown
//   { type: 'number' }                               predicate (equals/gt/
//                                                      gte/lt/lte/notEquals)
//                                                      + number box
//   { type: 'string' }                               predicate (contains/
//                                                      startsWith/...) + text
//                                                      box
//   { type: 'date' }                                  predicate (on/not on/
//                                                      before/after) + a
//                                                      native date input
// Any type also takes an optional `accessor: (row) => value` when the field
// to filter by isn't a literal property on the row data (e.g. filtering
// Orders by item *count* — `line_items` is an array, not a number). When
// present, BaseTable computes that value per row itself and filters on a
// synthetic key instead of `field` directly — see `tableData`/`filterKeyFor`
// below — so `field` only ever has to be correct for rendering/sorting.
// BaseTable renders the whole toolbar + table + pagination.
//
// Per-column custom rendering (an EntityLink, a BaseTag, formatNumber/
// formatDateTime, an action button, ...) goes through a named slot keyed by
// field: `#cell-<field>="{ data }"`. A column with no matching slot just
// shows `data[field]` as plain text.
//
// Built on BaseDataTable + raw `Column` — never a wrapped Column component,
// see BaseDataTable.vue's own comment for why (DataTable finds columns by
// scanning its default slot for `vnode.type.name === 'Column'` and reads
// their props/slots without mounting them; a wrapper breaks that match).
defineOptions({ name: 'BaseTable' })

const props = defineProps({
  data: { type: Array, required: true },
  columns: { type: Array, required: true },
  loading: { type: Boolean, default: false },
  rowKey: { type: String, default: 'id' },
  searchPlaceholder: { type: String, default: '' },
  // Tooltip text for the optional create/export icon buttons in the
  // toolbar — the button itself only renders when its label is given, so a
  // view that has neither (e.g. a read-only sub-table) just omits both.
  createLabel: { type: String, default: '' },
  exportLabel: { type: String, default: '' },
  exporting: { type: Boolean, default: false },
})

defineEmits(['row-click', 'refresh', 'create', 'export'])

const { t } = useI18n()

const pageSizeOptions = [10, 25, 50, 100].map((n) => ({ label: String(n), value: n }))

const filterableColumns = computed(() => props.columns.filter((c) => c.filter))
const filterableColumnOptions = computed(() => filterableColumns.value.map((c) => ({ label: c.header, value: c.field })))

function columnByField(field) {
  return props.columns.find((c) => c.field === field)
}

// The DataTable-facing filter key for a column: its own `field` normally, or
// a synthetic key (materialized in `tableData` below) when the column's
// filter reads from an `accessor` instead of the raw field value.
function filterKeyFor(col) {
  return col.filter?.accessor ? `__filter_${col.field}` : col.field
}

// Only computed (and only touches `data`) when at least one filterable
// column actually has an accessor — the common case (no accessors) returns
// `data` unchanged, no per-row copying.
const tableData = computed(() => {
  const accessorColumns = filterableColumns.value.filter((c) => c.filter.accessor)
  if (!accessorColumns.length) return props.data
  return props.data.map((row) => {
    const extra = {}
    for (const col of accessorColumns) extra[filterKeyFor(col)] = col.filter.accessor(row)
    return { ...row, ...extra }
  })
})

const numberPredicateOptions = computed(() => [
  { label: t('baseTable.predicateEquals'), value: 'equals' },
  { label: t('baseTable.predicateNotEquals'), value: 'notEquals' },
  { label: t('baseTable.predicateGreaterThan'), value: 'gt' },
  { label: t('baseTable.predicateGreaterThanOrEqual'), value: 'gte' },
  { label: t('baseTable.predicateLessThan'), value: 'lt' },
  { label: t('baseTable.predicateLessThanOrEqual'), value: 'lte' },
])

const stringPredicateOptions = computed(() => [
  { label: t('baseTable.predicateContains'), value: 'contains' },
  { label: t('baseTable.predicateNotContains'), value: 'notContains' },
  { label: t('baseTable.predicateEquals'), value: 'equals' },
  { label: t('baseTable.predicateNotEquals'), value: 'notEquals' },
  { label: t('baseTable.predicateStartsWith'), value: 'startsWith' },
  { label: t('baseTable.predicateEndsWith'), value: 'endsWith' },
])

const datePredicateOptions = computed(() => [
  { label: t('baseTable.predicateDateAfter'), value: 'dateAfter' },
  { label: t('baseTable.predicateDateBefore'), value: 'dateBefore' },
  { label: t('baseTable.predicateDateIs'), value: 'dateIs' },
  { label: t('baseTable.predicateDateIsNot'), value: 'dateIsNot' },
])

const DEFAULT_MATCH_MODE = { enum: 'equals', number: 'equals', string: 'contains', date: 'dateAfter' }

const globalFilter = reactive({ value: null, matchMode: 'contains' })

// One row per active filter: { id, field, matchMode, value }. A field can
// appear in more than one row (e.g. two "amount" rows for a gte/lte range) —
// see the `filters` computed below for how that's reconciled into what
// DataTable expects.
let nextFilterRowId = 0
const filterRows = ref([])

function defaultRowFor(field) {
  const type = columnByField(field)?.filter?.type
  return { id: nextFilterRowId++, field, matchMode: DEFAULT_MATCH_MODE[type] ?? 'equals', value: null }
}

function addFilterRow() {
  if (!filterableColumns.value.length) return
  filterRows.value.push(defaultRowFor(filterableColumns.value[0].field))
}

function removeFilterRow(id) {
  filterRows.value = filterRows.value.filter((row) => row.id !== id)
}

function onFieldChange(row) {
  const fresh = defaultRowFor(row.field)
  row.matchMode = fresh.matchMode
  row.value = null
}

const hasActiveFilters = computed(() => filterRows.value.some((row) => row.value !== null && row.value !== ''))

function clearFilters() {
  filterRows.value = []
}

// DataTable ANDs every non-'global' key in `filters` together, and — via its
// own `{ operator, constraints }` shape — ANDs/ORs multiple predicates on the
// SAME field too (its built-in advanced-filter mechanism). Grouping
// `filterRows` by field and handing DataTable that shape gets "multiple
// filters combine as AND" (both across fields and stacked on one field, e.g.
// a gte/lte range) for free, with no custom filtering logic needed here.
const filters = computed(() => {
  const byField = {}
  for (const row of filterRows.value) {
    if (row.value === null || row.value === '') continue
    const key = filterKeyFor(columnByField(row.field))
    ;(byField[key] ??= []).push({ value: row.value, matchMode: row.matchMode })
  }
  const result = { global: globalFilter }
  for (const [field, constraints] of Object.entries(byField)) {
    result[field] = constraints.length === 1 ? constraints[0] : { operator: 'and', constraints }
  }
  return result
})

const filterPopover = useTemplateRef('filterPopover')

const hideableColumns = computed(() => props.columns.filter((c) => c.hideable !== false))
const visibleFields = ref(hideableColumns.value.map((c) => c.field))

const renderedColumns = computed(() =>
  props.columns.filter((c) => c.hideable === false || visibleFields.value.includes(c.field)),
)

const globalFilterFields = computed(() => props.columns.filter((c) => c.field).map((c) => c.field))
</script>

<template>
  <BaseDataTable
    :value="tableData"
    :loading="loading"
    :data-key="rowKey"
    paginator
    paginator-position="top"
    :rows="25"
    :filters="filters"
    :global-filter-fields="globalFilterFields"
    @row-click="$emit('row-click', $event)"
  >
    <template #paginatorcontainer="{ page, pageCount, rows, prevPageCallback, nextPageCallback, rowChangeCallback }">
      <div class="base-table__toolbar">
        <div class="base-table__search">
          <i class="pi pi-search" aria-hidden="true" />
          <BaseInputText v-model="globalFilter.value" :placeholder="searchPlaceholder" class="base-table__search-input" />
        </div>
        <div class="base-table__actions">
          <button
            v-if="createLabel"
            type="button"
            class="base-table__icon-btn"
            v-tooltip.bottom="createLabel"
            :aria-label="createLabel"
            @click="$emit('create')"
          >
            <i class="pi pi-plus" aria-hidden="true" />
          </button>
          <button
            v-if="exportLabel"
            type="button"
            class="base-table__icon-btn"
            :disabled="exporting"
            v-tooltip.bottom="exportLabel"
            :aria-label="exportLabel"
            @click="$emit('export')"
          >
            <i :class="exporting ? 'pi pi-spin pi-spinner' : 'pi pi-download'" aria-hidden="true" />
          </button>
          <button
            v-if="filterableColumns.length"
            type="button"
            class="base-table__icon-btn"
            :class="{ 'base-table__icon-btn--active': hasActiveFilters }"
            v-tooltip.bottom="t('baseTable.filterLabel')"
            :aria-label="t('baseTable.filterLabel')"
            @click="filterPopover.toggle($event)"
          >
            <i class="pi pi-filter" aria-hidden="true" />
          </button>
          <BasePopover v-if="filterableColumns.length" ref="filterPopover">
            <div class="base-table__filter-panel">
              <p v-if="!filterRows.length" class="base-table__filter-empty">{{ t('baseTable.noFiltersYet') }}</p>
              <div v-for="row in filterRows" :key="row.id" class="base-table__filter-row">
                <BaseSelect
                  v-model="row.field"
                  :options="filterableColumnOptions"
                  option-label="label"
                  option-value="value"
                  class="base-table__filter-column"
                  @update:model-value="onFieldChange(row)"
                />
                <template v-if="columnByField(row.field)?.filter.type === 'enum'">
                  <BaseSelect
                    v-model="row.value"
                    :options="columnByField(row.field).filter.options"
                    option-label="label"
                    option-value="value"
                    show-clear
                    :placeholder="t('baseTable.anyOption')"
                    class="base-table__filter-value"
                  />
                </template>
                <template v-else-if="columnByField(row.field)?.filter.type === 'number'">
                  <BaseSelect
                    v-model="row.matchMode"
                    :options="numberPredicateOptions"
                    option-label="label"
                    option-value="value"
                    class="base-table__filter-predicate"
                  />
                  <BaseInputNumber v-model="row.value" :placeholder="t('baseTable.enterValue')" class="base-table__filter-value" />
                </template>
                <template v-else-if="columnByField(row.field)?.filter.type === 'string'">
                  <BaseSelect
                    v-model="row.matchMode"
                    :options="stringPredicateOptions"
                    option-label="label"
                    option-value="value"
                    class="base-table__filter-predicate"
                  />
                  <BaseInputText v-model="row.value" :placeholder="t('baseTable.enterValue')" class="base-table__filter-value" />
                </template>
                <template v-else-if="columnByField(row.field)?.filter.type === 'date'">
                  <BaseSelect
                    v-model="row.matchMode"
                    :options="datePredicateOptions"
                    option-label="label"
                    option-value="value"
                    class="base-table__filter-predicate"
                  />
                  <BaseInputText v-model="row.value" type="date" class="base-table__filter-value" />
                </template>
                <button
                  type="button"
                  class="base-table__filter-remove"
                  v-tooltip.bottom="t('baseTable.removeFilter')"
                  :aria-label="t('baseTable.removeFilter')"
                  @click="removeFilterRow(row.id)"
                >
                  <i class="pi pi-times" aria-hidden="true" />
                </button>
              </div>
              <div class="base-table__filter-actions">
                <BaseButton text size="small" icon="pi pi-plus" :label="t('baseTable.addFilter')" @click="addFilterRow" />
                <BaseButton v-if="filterRows.length" text size="small" :label="t('baseTable.clearFilters')" @click="clearFilters" />
              </div>
            </div>
          </BasePopover>
          <BaseMultiSelect
            v-if="hideableColumns.length > 1"
            v-model="visibleFields"
            :options="hideableColumns"
            option-label="header"
            option-value="field"
            v-tooltip.bottom="t('baseTable.columnsPlaceholder')"
            :aria-label="t('baseTable.columnsPlaceholder')"
            class="base-table__columns"
          >
            <template #value>
              <i class="pi pi-table" aria-hidden="true" />
            </template>
          </BaseMultiSelect>
          <span class="base-table__divider" aria-hidden="true" />
          <button
            type="button"
            class="base-table__icon-btn base-table__icon-btn--plain"
            v-tooltip.bottom="t('baseTable.refreshLabel')"
            :aria-label="t('baseTable.refreshLabel')"
            @click="$emit('refresh')"
          >
            <i class="pi pi-refresh" aria-hidden="true" />
          </button>
          <BaseSelect
            class="base-table__page-size"
            :model-value="rows"
            :options="pageSizeOptions"
            option-label="label"
            option-value="value"
            v-tooltip.bottom="t('baseTable.tableSizeLabel')"
            :aria-label="t('baseTable.tableSizeLabel')"
            @update:model-value="rowChangeCallback"
          />
          <span class="base-table__page-count">{{ pageCount > 0 ? page + 1 : 0 }} {{ t('baseTable.of') }} {{ pageCount }}</span>
          <button
            type="button"
            class="base-table__page-nav"
            :disabled="page <= 0"
            v-tooltip.bottom="t('baseTable.prevPageLabel')"
            :aria-label="t('baseTable.prevPageLabel')"
            @click="prevPageCallback"
          >
            <i class="pi pi-chevron-left" aria-hidden="true" />
          </button>
          <button
            type="button"
            class="base-table__page-nav"
            :disabled="page >= pageCount - 1"
            v-tooltip.bottom="t('baseTable.nextPageLabel')"
            :aria-label="t('baseTable.nextPageLabel')"
            @click="nextPageCallback"
          >
            <i class="pi pi-chevron-right" aria-hidden="true" />
          </button>
        </div>
      </div>
    </template>
    <Column
      v-for="col in renderedColumns"
      :key="col.field"
      unstyled
      :field="col.field"
      :header="col.header"
      :sortable="col.sortable"
    >
      <template #body="scope">
        <slot :name="`cell-${col.field}`" v-bind="scope">{{ scope.data[col.field] }}</slot>
      </template>
    </Column>
    <template #empty>
      <slot name="empty">{{ t('baseTable.noResults') }}</slot>
    </template>
  </BaseDataTable>
</template>

<style scoped>
.base-table__toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  flex-wrap: wrap;
  width: 100%;
}

.base-table__search {
  position: relative;
  width: 100%;
  max-width: 20rem;
  flex-shrink: 1;
}

.base-table__search .pi-search {
  position: absolute;
  top: 50%;
  left: 0.625rem;
  transform: translateY(-50%);
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  pointer-events: none;
}

.base-table__search-input {
  width: 100%;
  padding-left: 2rem;
}

.base-table__actions {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  flex-wrap: wrap;
  flex-shrink: 0;
}

/* The filter/columns triggers are bordered icon buttons (matching the
   screenshot's funnel button); refresh is the plain, borderless variant
   right after the divider. */
.base-table__icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  height: 2rem;
  width: 2rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: background-color 0.15s, color 0.15s, border-color 0.15s;
}

.base-table__icon-btn:hover {
  background: var(--color-bg-subtle);
}

.base-table__icon-btn:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 1px;
}

.base-table__icon-btn .pi-filter {
  font-size: 0.9375rem;
}

.base-table__icon-btn--active {
  color: var(--color-primary);
  border-color: var(--color-primary);
}

.base-table__icon-btn--plain {
  border-color: transparent;
}

.base-table__icon-btn:disabled {
  color: var(--color-text-disabled);
  cursor: not-allowed;
  pointer-events: none;
}

.base-table__filter-panel {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
  padding: 0.875rem;
  min-width: 27rem;
}

.base-table__filter-empty {
  margin: 0;
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.base-table__filter-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.base-table__filter-column {
  width: 9rem;
  flex-shrink: 0;
}

.base-table__filter-predicate {
  width: 9rem;
  flex-shrink: 0;
}

.base-table__filter-value {
  flex: 1 1 auto;
  min-width: 0;
}

.base-table__filter-remove {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 1.75rem;
  height: 1.75rem;
  border-radius: var(--radius-sm);
  color: var(--color-text-muted);
  cursor: pointer;
  transition: background-color 0.15s, color 0.15s;
}

.base-table__filter-remove:hover {
  background: var(--color-bg-subtle);
  color: var(--color-danger);
}

.base-table__filter-remove:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 1px;
}

.base-table__filter-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding-top: 0.125rem;
}

/* Reduces BaseMultiSelect's normal form-field box down to a plain icon
   button — width/padding/gap/background beat its own Tailwind utility
   classes the same way every other scoped-CSS override in this app does
   (unlayered component CSS always wins over @layer utilities). The #value
   slot above already replaced the label text with just the icon; this also
   drops the dropdown chevron so only that one icon shows, per request. */
.base-table__columns {
  width: 2rem;
  height: 2rem;
  flex-shrink: 0;
  justify-content: center;
  gap: 0;
  padding: 0;
  border: 1px solid var(--color-border);
  background: transparent;
}

.base-table__columns :deep([data-pc-section='dropdown']) {
  display: none;
}

/* labelcontainer/label are themselves left-aligned flex rows (built for a
   normal text label, not a lone centered icon) — without this the icon sits
   flush against the box's left edge instead of centered. */
.base-table__columns :deep([data-pc-section='labelcontainer']) {
  flex: none;
}

.base-table__columns :deep([data-pc-section='label']) {
  justify-content: center;
}

.base-table__columns .pi-table {
  font-size: 0.9375rem;
  color: var(--color-text-muted);
}

.base-table__divider {
  width: 1px;
  height: 1.25rem;
  background: var(--color-border);
  flex-shrink: 0;
}

/* Same override pattern as .base-table__columns above, shrinking BaseSelect's
   normal full-width form-field box down to a compact, borderless inline
   picker that reads as part of the plain icon-button cluster rather than a
   form field. */
.base-table__page-size {
  width: auto;
  flex-shrink: 0;
  gap: 0.25rem;
  padding: 0.375rem 0.5rem;
  background: transparent;
}

.base-table__page-size :deep([data-pc-section='label']) {
  flex: none;
  font-size: var(--font-size-sm);
}

.base-table__page-count {
  flex-shrink: 0;
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
  white-space: nowrap;
}

.base-table__page-nav {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  height: 2rem;
  width: 2rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-full);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: background-color 0.15s, color 0.15s;
}

.base-table__page-nav:hover:not(:disabled) {
  background: var(--color-bg-subtle);
  color: var(--color-text);
}

.base-table__page-nav:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 1px;
}

.base-table__page-nav:disabled {
  color: var(--color-text-disabled);
  cursor: not-allowed;
}

.base-table__page-nav .pi {
  font-size: 0.8125rem;
}
</style>
