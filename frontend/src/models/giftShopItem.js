import { z } from 'zod'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const GiftShopItemSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string().nullable(),
    points_cost: z.number(),
    stock: z.number().nullable(),
    enabled: z.boolean(),
    in_stock: z.boolean(),
    photo_url: z.string().nullable(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export const GiftShopItemListSchema = z.object({ gift_shop_items: z.array(GiftShopItemSchema) }).passthrough()

// Response shape (GiftShopRedemptionResource), returned by the redeem action.
export const GiftShopRedemptionSchema = z
  .object({
    id: z.string(),
    item_name: z.string(),
    quantity: z.number(),
    points_spent: z.number(),
    redeemed_at: z.string(),
    item_id: z.string().nullable(),
    customer_id: z.string(),
  })
  .passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (giftShopItemForm.json).
// Shared by create and update — update applies .partial() at the call site.
export function giftShopItemInputSchema(t) {
  return z.object({
    name: z.string().min(1, t('giftShopItemForm.nameRequired')),
    description: z.string().nullable(),
    points_cost: z
      .number({ message: t('giftShopItemForm.pointsCostInvalid') })
      .int(t('giftShopItemForm.pointsCostInvalid'))
      .gt(0, t('giftShopItemForm.pointsCostInvalid')),
    stock: z
      .number({ message: t('giftShopItemForm.stockInvalid') })
      .int(t('giftShopItemForm.stockInvalid'))
      .gte(0, t('giftShopItemForm.stockInvalid'))
      .nullable(),
    enabled: z.boolean(),
  })
}
