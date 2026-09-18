import { z } from 'zod'

// Mirrors ConditionVocabulary::ENTITIES / ::DATA_TYPES on the backend
// (backend/app/models/concerns/condition_vocabulary.rb).
export const CUSTOM_ATTRIBUTE_ENTITIES = ['cart', 'line_item', 'customer']
export const CUSTOM_ATTRIBUTE_DATA_TYPES = ['string', 'number', 'date', 'boolean']

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const CustomAttributeSchema = z
  .object({
    id: z.string(),
    entity: z.string(),
    key: z.string(),
    data_type: z.string(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export const CustomAttributeListSchema = z.object({ custom_attributes: z.array(CustomAttributeSchema) }).passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (customAttributes.json).
// entity/data_type are always populated by a Select with a default value, so
// there's no realistic empty-selection path — the enum check just guards
// against an invalid value ever reaching the backend.
export function customAttributeInputSchema(t) {
  return z.object({
    entity: z.enum(CUSTOM_ATTRIBUTE_ENTITIES),
    key: z.string().min(1, t('customAttributes.keyRequired')),
    data_type: z.enum(CUSTOM_ATTRIBUTE_DATA_TYPES),
  })
}
