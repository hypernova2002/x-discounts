import { apiFetch, type AuthParams } from '@/lib/api'
import { GiftShopItemSchema, GiftShopItemListSchema, GiftShopRedemptionSchema, type GiftShopItemInput } from '@/models/giftShopItem'

const BASE = '/api/v1/admin/gift_shop_items'

export function listGiftShopItems({ token, projectId }: AuthParams) {
  return apiFetch(BASE, { token, projectId }).then((data) => GiftShopItemListSchema.parse(data).gift_shop_items)
}

export function getGiftShopItem(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => GiftShopItemSchema.parse(data))
}

export function createGiftShopItem(input: GiftShopItemInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => GiftShopItemSchema.parse(data))
}

export function updateGiftShopItem(id: string, input: Partial<GiftShopItemInput>, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => GiftShopItemSchema.parse(data))
}

interface RedeemGiftShopItemInput {
  customer_external_id: string
  quantity: number
}

export function redeemGiftShopItem(id: string, input: RedeemGiftShopItemInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/redeem`, { method: 'POST', token, projectId, body: input }).then((data) => GiftShopRedemptionSchema.parse(data))
}
