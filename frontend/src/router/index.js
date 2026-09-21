import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', name: 'login', component: () => import('../views/LoginView.vue'), meta: { public: true } },
    { path: '/signup', name: 'signup', component: () => import('../views/SignupView.vue'), meta: { public: true } },
    { path: '/select-project', name: 'select-project', component: () => import('../views/SelectProjectView.vue') },
    { path: '/otp-setup', name: 'otp-setup', component: () => import('../views/OtpSetupView.vue') },
    { path: '/', name: 'dashboard', component: () => import('../views/DashboardView.vue') },
    { path: '/settings', name: 'user-settings', component: () => import('../views/UserSettingsView.vue') },
    { path: '/account', name: 'account', component: () => import('../views/AccountView.vue') },
    { path: '/project-settings', name: 'project-settings', component: () => import('../views/ProjectSettingsView.vue') },
    { path: '/campaigns', name: 'campaigns', component: () => import('../views/CampaignsView.vue') },
    { path: '/campaigns/coupons', name: 'campaigns-coupons', component: () => import('../views/CouponsView.vue') },
    { path: '/campaigns/promotions', name: 'campaigns-promotions', component: () => import('../views/PromotionsView.vue') },
    { path: '/campaigns/loyalty', name: 'campaigns-loyalty', component: () => import('../views/LoyaltyPointsView.vue') },
    { path: '/campaigns/new', name: 'campaign-new', component: () => import('../views/CampaignFormView.vue') },
    { path: '/campaigns/:id/edit', name: 'campaign-edit', component: () => import('../views/CampaignFormView.vue') },
    { path: '/campaigns/:id', name: 'campaign-show', component: () => import('../views/CampaignDetailView.vue') },
    { path: '/discounts/new', name: 'discount-new', component: () => import('../views/DiscountFormView.vue') },
    { path: '/discounts/:id/edit', name: 'discount-edit', component: () => import('../views/DiscountFormView.vue') },
    { path: '/discounts/:id', name: 'discount-show', component: () => import('../views/DiscountDetailView.vue') },
    { path: '/custom-attributes', name: 'custom-attributes', component: () => import('../views/CustomAttributesView.vue') },
    { path: '/orders', name: 'orders', component: () => import('../views/OrdersView.vue') },
    { path: '/orders/new', name: 'order-new', component: () => import('../views/OrderFormView.vue') },
    { path: '/orders/:id', name: 'order-show', component: () => import('../views/OrderDetailView.vue') },
    { path: '/customers', name: 'customers', component: () => import('../views/CustomersView.vue') },
    { path: '/customers/:id', name: 'customer-show', component: () => import('../views/CustomerDetailView.vue') },
    { path: '/membership-schemes', name: 'membership-schemes', component: () => import('../views/MembershipSchemesView.vue') },
    { path: '/membership-schemes/new', name: 'membership-scheme-new', component: () => import('../views/MembershipSchemeFormView.vue') },
    { path: '/membership-schemes/:id/edit', name: 'membership-scheme-edit', component: () => import('../views/MembershipSchemeFormView.vue') },
    { path: '/membership-schemes/:id', name: 'membership-scheme-show', component: () => import('../views/MembershipSchemeDetailView.vue') },
    { path: '/gift-shop', name: 'gift-shop', component: () => import('../views/GiftShopView.vue') },
    { path: '/gift-shop/new', name: 'gift-shop-item-new', component: () => import('../views/GiftShopItemFormView.vue') },
    { path: '/gift-shop/:id/edit', name: 'gift-shop-item-edit', component: () => import('../views/GiftShopItemFormView.vue') },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.restore()

  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if ((to.name === 'login' || to.name === 'signup') && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }

  if (auth.isAuthenticated && !auth.hasProject && to.name !== 'select-project' && !to.meta.public) {
    return { name: 'select-project', query: { redirect: to.fullPath } }
  }

  if (auth.isAuthenticated && auth.hasProject && auth.needsOtpSetup && to.name !== 'otp-setup') {
    return { name: 'otp-setup', query: { redirect: to.fullPath } }
  }
})

export default router
