<script setup>
import { computed, reactive, ref, useTemplateRef } from 'vue'
import { useI18n } from 'vue-i18n'
import Column from 'openvue/column'
import BaseDataTable from './BaseDataTable.vue'
import BaseInputText from './BaseInputText.vue'
import BaseMultiSelect from './BaseMultiSelect.vue'
import BaseSelect from './BaseSelect.vue'
import BaseButton from './BaseButton.vue'
import BasePopover from './BasePopover.vue'

// The single reusable, columns-driven table: every list view generates its
// table from this instead of hand-rolling search/pagination/column-chooser/
// sort/filter UI per view. Give it `data` + `columns` (each `{ field,
// header, sortable?, hideable?, filterOptions? }` — `hideable: false` keeps
// a column always shown and out of the column-chooser, e.g. a primary
// identifier or an actions column; `filterOptions` — an array of `{ label,
// value }` — adds that field to the toolbar Filter panel as a dropdown) and
// it renders the whole toolbar + table + pagination.
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
})

defineEmits(['row-click', 'refresh'])

const { t } = useI18n()

const pageSizeOptions = [10, 25, 50, 100].map((n) => ({ label: String(n), value: n }))

const filterableColumns = computed(() => props.columns.filter((c) => c.filterOptions))

// DataTable applies any non-'global' key in `filters` as a per-field filter
// (via FilterService.filters[matchMode]) — 'equals' treats a null/undefined
// value as "matches everything", so an untouched filter field is inert
// without needing to be conditionally added/removed. Built once from the
// columns prop as given (column sets don't change shape after mount in this
// app, same assumption `visibleFields` below already makes).
const filters = reactive({
  global: { value: null, matchMode: 'contains' },
  ...Object.fromEntries(filterableColumns.value.map((c) => [c.field, { value: null, matchMode: 'equals' }])),
})

const hasActiveFilters = computed(() => filterableColumns.value.some((c) => filters[c.field]?.value != null))

function clearFilters() {
  filterableColumns.value.forEach((c) => {
    filters[c.field].value = null
  })
}

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
    :value="data"
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
          <BaseInputText v-model="filters.global.value" :placeholder="searchPlaceholder" class="base-table__search-input" />
        </div>
        <div class="base-table__actions">
          <button
            v-if="filterableColumns.length"
            type="button"
            class="base-table__icon-btn"
            :class="{ 'base-table__icon-btn--active': hasActiveFilters }"
            :aria-label="t('baseTable.filterLabel')"
            @click="filterPopover.toggle($event)"
          >
            <i class="pi pi-filter" aria-hidden="true" />
          </button>
          <BasePopover v-if="filterableColumns.length" ref="filterPopover">
            <div class="base-table__filter-panel">
              <div v-for="col in filterableColumns" :key="col.field" class="base-table__filter-field">
                <label :for="`base-table-filter-${col.field}`">{{ col.header }}</label>
                <BaseSelect
                  :id="`base-table-filter-${col.field}`"
                  v-model="filters[col.field].value"
                  :options="col.filterOptions"
                  option-label="label"
                  option-value="value"
                  show-clear
                  :placeholder="t('baseTable.anyOption')"
                />
              </div>
              <BaseButton text size="small" :label="t('baseTable.clearFilters')" :disabled="!hasActiveFilters" @click="clearFilters" />
            </div>
          </BasePopover>
          <BaseMultiSelect
            v-if="hideableColumns.length > 1"
            v-model="visibleFields"
            :options="hideableColumns"
            option-label="header"
            option-value="field"
            :aria-label="t('baseTable.columnsPlaceholder')"
            class="base-table__columns"
          >
            <template #value>
              <i class="pi pi-table" aria-hidden="true" />
            </template>
          </BaseMultiSelect>
          <span class="base-table__divider" aria-hidden="true" />
          <button type="button" class="base-table__icon-btn base-table__icon-btn--plain" :aria-label="t('baseTable.refreshLabel')" @click="$emit('refresh')">
            <i class="pi pi-refresh" aria-hidden="true" />
          </button>
          <BaseSelect
            class="base-table__page-size"
            :model-value="rows"
            :options="pageSizeOptions"
            option-label="label"
            option-value="value"
            :aria-label="t('baseTable.rowsPerPageLabel')"
            @update:model-value="rowChangeCallback"
          />
          <span class="base-table__page-count">{{ pageCount > 0 ? page + 1 : 0 }} {{ t('baseTable.of') }} {{ pageCount }}</span>
          <button type="button" class="base-table__page-nav" :disabled="page <= 0" :aria-label="t('baseTable.prevPageLabel')" @click="prevPageCallback">
            <i class="pi pi-chevron-left" aria-hidden="true" />
          </button>
          <button type="button" class="base-table__page-nav" :disabled="page >= pageCount - 1" :aria-label="t('baseTable.nextPageLabel')" @click="nextPageCallback">
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

.base-table__filter-panel {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 0.875rem;
  min-width: 14rem;
}

.base-table__filter-field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.base-table__filter-field label {
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-medium);
  color: var(--color-text-muted);
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
