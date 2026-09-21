<script setup>
import { useAttrs } from 'vue'
import DataTable from 'openvue/datatable'

// Wraps OpenVue's DataTable in unstyled mode. Same prop surface (value, loading,
// dataKey, ...) — import/tag swap only. Pair with raw `Column` (openvue/column),
// not a Base wrapper — see the `pt.column` note below for why. Callers keep
// deciding *whether* an empty state renders — the `v-if="!loading && !data.length"`
// / `v-else` pattern already used throughout this codebase for that is unchanged
// by this migration — this just makes the DataTable's own loading/empty chrome
// look intentional when used.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

// Body rows are NOT styled through pt.row — the <tr>'s class comes only from
// `cx('row', ...)` (DataTable's own render source), which — like every other
// cx() call — is gated off entirely in unstyled mode, so a pt.row value here
// would be silently dead code. The real (documented) per-row styling hook is
// the `rowClass` prop, a function DataTable calls per row and merges into the
// <tr>'s class alongside (the disabled) cx() output — so that's set explicitly
// below instead, and callers wanting row click-through pass `@row-click`.
function rowClass() {
  return [
    'border-b border-border last:border-b-0 hover:bg-bg-subtle transition-colors',
    attrs.onRowClick ? 'cursor-pointer' : '',
  ].join(' ')
}

const pt = {
  root: 'relative w-full',
  table: 'w-full border-collapse text-left text-sm',
  thead: 'bg-bg-subtle',
  tbody: '',
  tfoot: 'bg-bg-subtle',
  header: 'border-b border-border p-3 text-sm font-medium text-text',
  footer: 'border-t border-border p-3 text-sm text-text',
  mask: 'absolute inset-0 z-10 flex items-center justify-center bg-bg/70',
  loadingIcon: 'h-6 w-6 animate-spin text-primary',
  emptyMessage: '',
  emptyMessageCell: 'p-6 text-center text-sm text-text-muted',
  // DataTable resolves each cell's styling through its own pt under a
  // 'column.<section>' key (merged with any pt set directly on the column
  // vnode's own props). It finds columns by matching `vnode.type.name ===
  // 'Column'` on this component's default slot and reads header/field/slots
  // straight off that vnode without ever mounting it — wrapping Column in a
  // component (even one named 'Column') breaks this: the wrapped instance
  // mounts and registers itself independently of the vnode DataTable already
  // matched, and the two fall out of sync, infinite-looping re-renders. So
  // Column must be used raw at call sites, and cell styling has to live here.
  column: {
    headerCell: [
      'group border-b border-border bg-bg-subtle px-3 py-2 text-left text-xs font-medium uppercase tracking-wide text-text-muted',
      'data-[p-sortable-column=true]:cursor-pointer data-[p-sortable-column=true]:select-none',
      'data-[p-sortable-column=true]:hover:text-text',
    ].join(' '),
    columnHeaderContent: 'inline-flex items-center gap-1',
    sorticon: 'h-3 w-3 text-text-disabled group-hover:text-text-muted group-data-[p-sorted=true]:text-primary',
    bodyCell: 'px-3 py-1.5 align-middle text-sm text-text',
    footerCell: 'border-t border-border px-3 py-2 text-sm font-medium text-text',
    columnTitle: 'inline-flex items-center gap-1',
  },
  // Paginator renders as a nested component (openvue/paginator), and BaseTable
  // always supplies its own `#paginatorcontainer` slot content (the full
  // search/filter/columns/refresh/pager toolbar) rather than using Paginator's
  // built-in template-token rendering — so `root` here is just the wrapping
  // div around that custom content (Paginator hands it `ptm('root')`
  // regardless of whether the container slot is used), and none of
  // Paginator's own sub-section names (first/prev/pages/...) are relevant.
  // `border-b` (not `-t`) assumes BaseTable's `paginator-position="top"` —
  // this is the only caller of `paginator`, so the paginator is always the
  // top instance, sitting where the table's old header row used to be.
  pcPaginator: {
    root: 'flex items-center justify-between gap-3 border-b border-border px-3 py-2.5',
  },
}
</script>

<template>
  <DataTable unstyled v-bind="attrs" :pt="pt" :row-class="rowClass">
    <slot />
    <template v-if="$slots.empty" #empty><slot name="empty" /></template>
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
    <template v-if="$slots.loading" #loading><slot name="loading" /></template>
    <template v-if="$slots.paginatorcontainer" #paginatorcontainer="scope"><slot name="paginatorcontainer" v-bind="scope" /></template>
  </DataTable>
</template>
