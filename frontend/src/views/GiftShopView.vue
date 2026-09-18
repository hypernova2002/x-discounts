<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { apiFileUrl, ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listGiftShopItems, redeemGiftShopItem } from '@/api/giftShopItems'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { data: items, loading, error, reload: loadItems } = useAsync(() => listGiftShopItems({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('giftShop.loadError'), detail: e.message, life: 4000 })
})

function createItem() {
  router.push({ name: 'gift-shop-item-new' })
}

function editItem(item) {
  router.push({ name: 'gift-shop-item-edit', params: { id: item.id } })
}

// --- redeem dialog ---

const redeemingItem = ref(null)
const redeemExternalId = ref('')
const redeemQuantity = ref(1)
const redeeming = ref(false)
const redeemError = ref('')

function openRedeem(item) {
  redeemingItem.value = item
  redeemExternalId.value = ''
  redeemQuantity.value = 1
  redeemError.value = ''
}

async function submitRedeem() {
  redeeming.value = true
  redeemError.value = ''
  try {
    await redeemGiftShopItem(
      redeemingItem.value.id,
      { customer_external_id: redeemExternalId.value, quantity: redeemQuantity.value },
      { token: auth.token, projectId: auth.project?.id },
    )
    toast.add({ severity: 'success', summary: t('giftShop.redeemed'), life: 3000 })
    redeemingItem.value = null
    await loadItems()
  } catch (e) {
    redeemError.value = e instanceof ApiError ? e.message : t('giftShop.genericError')
  } finally {
    redeeming.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <BaseButton :label="$t('giftShop.newItemButton')" @click="createItem" />
      </template>
    </PageHeader>

    <div class="items-grid">
      <BaseCard v-for="item in items || []" :key="item.id" class="item-card">
        <template #header>
          <img v-if="item.photo_url" :src="apiFileUrl(item.photo_url)" :alt="item.name" class="item-photo" />
          <div v-else class="item-photo item-photo--placeholder">{{ $t('giftShop.noPhoto') }}</div>
        </template>
        <template #title>
          <div class="item-title">
            <span>{{ item.name }}</span>
            <BaseTag v-if="!item.enabled" severity="secondary" :value="$t('giftShop.disabledTag')" />
          </div>
        </template>
        <template #content>
          <p v-if="item.description" class="item-description">{{ item.description }}</p>
          <p class="item-points">{{ $t('giftShop.pointsCost', { points: formatNumber(item.points_cost) }) }}</p>
          <p class="item-stock">
            <BaseTag v-if="item.stock == null" severity="secondary" :value="$t('giftShop.unlimitedStock')" />
            <BaseTag v-else :severity="item.in_stock ? 'success' : 'danger'" :value="$t('giftShop.inStock', { stock: item.stock })" />
          </p>
          <div class="item-actions">
            <BaseButton text :label="$t('giftShop.editButton')" @click="editItem(item)" />
            <BaseButton :label="$t('giftShop.redeemButton')" :disabled="!item.enabled || !item.in_stock" @click="openRedeem(item)" />
          </div>
        </template>
      </BaseCard>
      <p v-if="!loading && !(items || []).length" class="empty-hint">{{ $t('giftShop.emptyHint') }}</p>
    </div>

    <BaseDialog :visible="!!redeemingItem" modal :header="$t('giftShop.redeemDialogTitle')" :style="{ width: '24rem' }" @update:visible="redeemingItem = null">
      <div v-if="redeemingItem" class="redeem-form">
        <p class="redeem-hint">{{ $t('giftShop.redeemHint', { name: redeemingItem.name, points: formatNumber(redeemingItem.points_cost) }) }}</p>
        <label>{{ $t('giftShop.customerExternalIdLabel') }}</label>
        <BaseInputText v-model="redeemExternalId" autofocus />
        <label>{{ $t('giftShop.quantityLabel') }}</label>
        <BaseInputNumber v-model="redeemQuantity" :min="1" />
        <BaseMessage v-if="redeemError" severity="error" :closable="false">{{ redeemError }}</BaseMessage>
        <BaseButton :label="$t('giftShop.redeemSubmitButton')" :loading="redeeming" @click="submitRedeem" />
      </div>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr));
  gap: 1rem;
}

.item-card {
  display: flex;
  flex-direction: column;
}

.item-photo {
  width: 100%;
  height: 10rem;
  object-fit: cover;
}

.item-photo--placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg-subtle);
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.item-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.item-description {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0 0 0.5rem;
}

.item-points {
  font-weight: 600;
  margin: 0 0 0.375rem;
}

.item-stock {
  margin: 0 0 0.75rem;
}

.item-actions {
  display: flex;
  justify-content: space-between;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.redeem-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.redeem-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0;
}
</style>
