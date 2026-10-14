<script setup lang="ts">
import { computed, useAttrs, useTemplateRef } from 'vue'
import { useRoute } from 'vue-router'
import Menu from 'openvue/menu'

// Wraps OpenVue's Menu in unstyled mode. Same prop surface (model, popup,
// ariaLabel, ...) — import/tag swap only. Used here as an inline (non-popup)
// sidebar list: `model` entries render as a plain item, OR — when an entry has
// its own `items` array — as a `submenuLabel` header followed by that group's
// items (used for the "Admin" section); `{ separator: true }` renders a plain
// divider. See openvue/menu's real source for this structure.
//
// Menuitem (the per-row component Menu renders each item through) is a nested
// COMPONENT, but — like Menubar's MenubarSub and Toast's ToastMessage — it's
// handed Menu's *entire* `pt` object unchanged (`pt: _ctx.pt`), so its own
// section names (item/itemContent/itemLink/itemIcon/itemLabel) are just flat
// keys in this same pt object, not nested under their own key.
//
// Menu has no built-in "current route" active-item concept (its `data-p`
// state only tracks keyboard focus/disabled) — since this is used as a nav
// sidebar, active-route highlighting is done here via a `pt.itemLink`
// callback comparing the item's own `routeNames` field (a plain array field
// on each model entry, read back via the callback's `context.item`, ignored
// by Menu itself) against the current route, so a detail/edit sub-route (e.g.
// a campaign's own detail page) still highlights its parent section.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()
const route = useRoute()

// Popup mode has no built-in trigger — callers hold a template ref and call
// `.toggle(event)` from their own button's click handler; that's forwarded
// here via defineExpose since Menu's own toggle method lives on its component
// instance, not as a prop/emit (same pattern as BasePopover.vue).
const menuRef = useTemplateRef<InstanceType<typeof Menu>>('menuRef')

function toggle(event: Event) {
  menuRef.value?.toggle(event)
}

defineExpose({ toggle })

interface MenuItemModel {
  routeNames?: string[]
  nested?: boolean
}

function isActive(item?: MenuItemModel): boolean {
  return typeof route.name === 'string' && !!item?.routeNames?.includes(route.name)
}

// Popup mode has no card chrome of its own (unstyled) — the inline sidebar
// usage must stay bare (no border/shadow/background around the whole list),
// so this chrome only applies when `popup` is set.
const isPopup = computed(() => 'popup' in attrs && attrs.popup !== false)

const pt = computed(() => ({
  root: [
    'flex flex-col gap-0.5',
    isPopup.value && 'z-50 mt-2 min-w-[12rem] rounded-md border border-border bg-bg py-1 shadow-md',
  ],
  start: 'mb-2',
  list: 'flex flex-col gap-0.5',
  end: 'mt-2',
  item: '',
  itemContent: 'rounded-md',
  itemLink: ({ context }: { context: { item?: MenuItemModel } }) => ({
    class: [
      'flex items-center gap-3 rounded-md border-l-2 border-l-transparent pr-3 py-2 text-sm no-underline outline-none transition-colors',
      context.item?.nested ? 'pl-6' : 'pl-2.5',
      'focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1',
      isActive(context.item)
        ? 'border-l-primary bg-primary-subtle text-primary font-medium'
        // A faded primary-subtle (not plain bg-bg/bg-bg-subtle) — a light
        // blue tint that reads as weaker than the active item's full
        // bg-primary-subtle, but still stronger than the sidebar's own
        // bg-bg-subtle background (which a full-strength bg-bg-subtle hover
        // would be invisible against).
        : 'text-text hover:bg-primary-subtle/50',
    ],
  }),
  itemIcon: ({ context }: { context: { item?: MenuItemModel } }) => ({
    class: ['shrink-0', context.item?.nested ? 'text-sm' : 'text-base', isActive(context.item) ? 'text-primary' : 'text-text-muted'],
  }),
  itemLabel: 'truncate',
  submenuLabel: 'px-3 pt-4 pb-1 text-xs font-semibold uppercase tracking-wide text-text-muted',
  separator: 'my-2 border-t border-border',
}))
</script>

<template>
  <Menu ref="menuRef" unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.start" #start><slot name="start" /></template>
    <template v-if="$slots.end" #end><slot name="end" /></template>
  </Menu>
</template>
