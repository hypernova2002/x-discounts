// Single source of truth for "which top-level section is the current route
// part of" — used by AppShell's sidebar (which route names highlight/live
// under each item) AND by PageHeader's breadcrumb + top-bar section title
// (which route names belong to that top-bar label). Route names come from
// router/index.js.
export const NAV_SECTIONS = [
  { id: 'dashboard', labelKey: 'nav.dashboard', icon: 'pi pi-home', to: { name: 'dashboard' }, routeNames: ['dashboard'] },
  {
    id: 'campaigns',
    labelKey: 'nav.campaigns',
    icon: 'pi pi-megaphone',
    to: { name: 'campaigns' },
    routeNames: ['campaigns', 'campaign-new', 'campaign-edit', 'campaign-show', 'discount-new', 'discount-edit', 'discount-show'],
  },
  { id: 'orders', labelKey: 'nav.orders', icon: 'pi pi-shopping-cart', to: { name: 'orders' }, routeNames: ['orders', 'order-new', 'order-show'] },
  { id: 'customers', labelKey: 'nav.customers', icon: 'pi pi-users', to: { name: 'customers' }, routeNames: ['customers', 'customer-show'] },
  {
    id: 'memberships',
    labelKey: 'nav.memberships',
    icon: 'pi pi-id-card',
    to: { name: 'membership-schemes' },
    routeNames: ['membership-schemes', 'membership-scheme-new', 'membership-scheme-edit', 'membership-scheme-show'],
  },
  {
    id: 'giftShop',
    labelKey: 'nav.giftShop',
    icon: 'pi pi-gift',
    to: { name: 'gift-shop' },
    routeNames: ['gift-shop', 'gift-shop-item-new', 'gift-shop-item-edit'],
  },
  { id: 'projects', labelKey: 'nav.projects', icon: 'pi pi-folder', to: { name: 'projects' }, routeNames: ['projects'], admin: true },
  { id: 'users', labelKey: 'nav.users', icon: 'pi pi-shield', to: { name: 'users' }, routeNames: ['users'], admin: true },
  {
    id: 'customAttributes',
    labelKey: 'nav.customAttributes',
    icon: 'pi pi-sliders-h',
    to: { name: 'custom-attributes' },
    routeNames: ['custom-attributes'],
    admin: true,
  },
]

export function findSection(routeName) {
  return NAV_SECTIONS.find((s) => s.routeNames.includes(routeName))
}
