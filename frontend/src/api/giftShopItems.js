import { apiFetch } from '@/lib/api'
import { GiftShopItemSchema, GiftShopItemListSchema, GiftShopRedemptionSchema } from '@/models/giftShopItem'

const BASE = '/api/v1/admin/gift_shop_items'

export function listGiftShopItems({ token, projectId }) {
  return apiFetch(BASE, { token, projectId }).then((data) => GiftShopItemListSchema.parse(data).gift_shop_items)
}

export function getGiftShopItem(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => GiftShopItemSchema.parse(data))
}

export function createGiftShopItem(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => GiftShopItemSchema.parse(data))
}

export function updateGiftShopItem(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => GiftShopItemSchema.parse(data))
}

export function redeemGiftShopItem(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}/redeem`, { method: 'POST', token, projectId, body: input }).then((data) => GiftShopRedemptionSchema.parse(data))
}
