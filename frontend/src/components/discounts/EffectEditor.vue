<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseSelectButton from '@/components/base/BaseSelectButton.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import ConditionTreeEditor from './ConditionTreeEditor.vue'

const { t } = useI18n()

const DISCOUNT_EFFECT_TYPE_OPTIONS = computed(() => [
  { label: t('effectEditor.effectTypes.percentageOff'), value: 'percentage_off' },
  { label: t('effectEditor.effectTypes.fixedAmountOff'), value: 'fixed_amount_off' },
  { label: t('effectEditor.effectTypes.freeItem'), value: 'free_item' },
])
const LOYALTY_EFFECT_TYPE_OPTIONS = computed(() => [
  { label: t('effectEditor.effectTypes.pointsPerCurrency'), value: 'points_per_currency' },
  { label: t('effectEditor.effectTypes.pointsFlat'), value: 'points_flat' },
  { label: t('effectEditor.effectTypes.pointsPerItem'), value: 'points_per_item' },
  { label: t('effectEditor.effectTypes.pointsMultiplier'), value: 'points_multiplier' },
])
const SCOPE_OPTIONS = computed(() => [
  { label: t('effectEditor.scopes.cart'), value: 'cart' },
  { label: t('effectEditor.scopes.lineItem'), value: 'line_item' },
])

// A meaningful configuration choice, not a generic dropdown (coupon-editor UX
// pass, point 4) — icon per effect type, drawn from this app's one icon system
// (PrimeIcons, already used elsewhere e.g. nav's pi-percentage for Promotions).
const EFFECT_TYPE_ICONS = {
  percentage_off: 'pi-percentage',
  fixed_amount_off: 'pi-dollar',
  free_item: 'pi-gift',
  points_per_currency: 'pi-star',
  points_flat: 'pi-star',
  points_per_item: 'pi-star',
  points_multiplier: 'pi-bolt',
}

// A computed (not a plain object) so it re-evaluates on a live locale switch —
// same reactivity requirement as any other t()-driven lookup table in this app.
const EFFECT_TYPE_DESCRIPTIONS = computed(() => ({
  percentage_off: t('effectEditor.effectTypeDescriptions.percentageOff'),
  fixed_amount_off: t('effectEditor.effectTypeDescriptions.fixedAmountOff'),
  free_item: t('effectEditor.effectTypeDescriptions.freeItem'),
  points_per_currency: t('effectEditor.effectTypeDescriptions.pointsPerCurrency'),
  points_flat: t('effectEditor.effectTypeDescriptions.pointsFlat'),
  points_per_item: t('effectEditor.effectTypeDescriptions.pointsPerItem'),
  points_multiplier: t('effectEditor.effectTypeDescriptions.pointsMultiplier'),
}))

const props = defineProps({
  modelValue: { type: Object, required: true },
  kind: { type: String, default: 'promotion' },
})
const emit = defineEmits(['update:modelValue', 'remove'])

const effectTypeOptions = computed(() => (props.kind === 'loyalty' ? LOYALTY_EFFECT_TYPE_OPTIONS.value : DISCOUNT_EFFECT_TYPE_OPTIONS.value))

function defaultLeaf() {
  return { entity: 'cart', key: '', operator: 'eq', value: '' }
}

function defaultConfigFor(type) {
  if (type === 'percentage_off') return { percentage: 10 }
  if (type === 'fixed_amount_off') return { amount: 1, currency: 'USD' }
  if (type === 'points_per_currency') return { rate: 1 }
  if (type === 'points_flat') return { points: 100 }
  if (type === 'points_per_item') return { points_per_item: 10 }
  if (type === 'points_multiplier') return { multiplier: 2 }
  return {
    buy_quantity: 1,
    get_quantity: 1,
    repeatable: false,
    buy_condition: defaultLeaf(),
    get_condition: defaultLeaf(),
  }
}

function update(patch) {
  emit('update:modelValue', { ...props.modelValue, ...patch })
}

function updateConfig(patch) {
  update({ config: { ...props.modelValue.config, ...patch } })
}

function setEffectType(type) {
  const scope = type === 'points_per_item' ? 'line_item' : props.modelValue.scope
  const target_condition = scope === 'line_item' ? props.modelValue.target_condition || defaultLeaf() : null
  emit('update:modelValue', { ...props.modelValue, effect_type: type, scope, target_condition, config: defaultConfigFor(type) })
}

function setScope(scope) {
  const target_condition = scope === 'line_item' ? props.modelValue.target_condition || defaultLeaf() : null
  update({ scope, target_condition })
}
</script>

<template>
  <div class="effect-editor">
    <div class="effect-header">
      <BaseSelect
        class="effect-type-select"
        :model-value="modelValue.effect_type"
        :options="effectTypeOptions"
        option-label="label"
        option-value="value"
        @update:model-value="setEffectType"
      >
        <template #value="{ value }">
          <span class="effect-type-value">
            <span class="effect-type-icon"><i :class="['pi', EFFECT_TYPE_ICONS[value]]" aria-hidden="true" /></span>
            <span class="effect-type-text">
              <span class="effect-type-label">{{ effectTypeOptions.find((o) => o.value === value)?.label }}</span>
              <span class="effect-type-desc">{{ EFFECT_TYPE_DESCRIPTIONS[value] }}</span>
            </span>
          </span>
        </template>
        <template #option="{ option, selected }">
          <span class="effect-type-option">
            <span class="effect-type-icon"><i :class="['pi', EFFECT_TYPE_ICONS[option.value]]" aria-hidden="true" /></span>
            <span class="effect-type-text">
              <span class="effect-type-label">{{ option.label }}</span>
              <span class="effect-type-desc">{{ EFFECT_TYPE_DESCRIPTIONS[option.value] }}</span>
            </span>
            <i v-if="selected" class="pi pi-check effect-type-check" aria-hidden="true" />
          </span>
        </template>
      </BaseSelect>
      <BaseButton text severity="danger" icon="pi pi-trash" :label="$t('effectEditor.removeEffectButton')" @click="$emit('remove')" />
    </div>

    <BaseSelectButton
      class="effect-scope"
      :model-value="modelValue.scope"
      :options="SCOPE_OPTIONS"
      option-label="label"
      option-value="value"
      :disabled="modelValue.effect_type === 'points_per_item'"
      @update:model-value="setScope"
    />

    <div v-if="modelValue.effect_type === 'percentage_off'" class="effect-field">
      <BaseInputNumber
        :model-value="modelValue.config.percentage"
        suffix="%"
        :min="0"
        :max="100"
        :aria-label="$t('effectEditor.fields.percentageOff')"
        @update:model-value="(v) => updateConfig({ percentage: v })"
      />
    </div>

    <div v-else-if="modelValue.effect_type === 'fixed_amount_off'" class="effect-config-row">
      <div class="effect-field">
        <label>{{ $t('effectEditor.fields.amount') }}</label>
        <BaseInputNumber :model-value="modelValue.config.amount" :min-fraction-digits="2" @update:model-value="(v) => updateConfig({ amount: v })" />
      </div>
      <div class="effect-field">
        <label>{{ $t('effectEditor.fields.currency') }}</label>
        <BaseInputText :model-value="modelValue.config.currency" placeholder="USD" @update:model-value="(v) => updateConfig({ currency: v })" />
      </div>
    </div>

    <template v-else-if="modelValue.effect_type === 'free_item'">
      <div class="free-item-row">
        <span class="free-item-word">{{ $t('effectEditor.freeItemBuyWord') }}</span>
        <BaseInputNumber
          class="free-item-qty"
          :model-value="modelValue.config.buy_quantity"
          :min="1"
          :aria-label="$t('effectEditor.fields.buyQuantity')"
          @update:model-value="(v) => updateConfig({ buy_quantity: v })"
        />
        <i class="pi pi-arrow-right free-item-arrow" aria-hidden="true" />
        <span class="free-item-word">{{ $t('effectEditor.freeItemGetWord') }}</span>
        <BaseInputNumber
          class="free-item-qty"
          :model-value="modelValue.config.get_quantity"
          :min="1"
          :aria-label="$t('effectEditor.fields.getQuantity')"
          @update:model-value="(v) => updateConfig({ get_quantity: v })"
        />
        <span class="free-item-word">{{ $t('effectEditor.freeItemFreeWord') }}</span>
        <span class="free-item-spacer" />
        <label class="free-item-repeatable">
          <BaseToggleSwitch :model-value="modelValue.config.repeatable" @update:model-value="(v) => updateConfig({ repeatable: v })" />
          {{ $t('effectEditor.fields.repeatable') }}
        </label>
      </div>
      <div class="effect-field">
        <label>{{ $t('effectEditor.fields.buyCondition') }}</label>
        <ConditionTreeEditor
          :model-value="modelValue.config.buy_condition"
          :allow-empty="false"
          @update:model-value="(v) => updateConfig({ buy_condition: v })"
        />
      </div>
      <div class="effect-field">
        <label>{{ $t('effectEditor.fields.getCondition') }}</label>
        <ConditionTreeEditor
          :model-value="modelValue.config.get_condition"
          :allow-empty="false"
          @update:model-value="(v) => updateConfig({ get_condition: v })"
        />
      </div>
    </template>

    <div v-else-if="modelValue.effect_type === 'points_per_currency'" class="effect-field">
      <label>{{ $t('effectEditor.fields.pointsPerCurrency') }}</label>
      <BaseInputNumber
        :model-value="modelValue.config.rate"
        :min="0"
        :min-fraction-digits="0"
        :max-fraction-digits="2"
        @update:model-value="(v) => updateConfig({ rate: v })"
      />
    </div>

    <div v-else-if="modelValue.effect_type === 'points_flat'" class="effect-field">
      <label>{{ $t('effectEditor.fields.points') }}</label>
      <BaseInputNumber :model-value="modelValue.config.points" :min="1" @update:model-value="(v) => updateConfig({ points: v })" />
    </div>

    <div v-else-if="modelValue.effect_type === 'points_per_item'" class="effect-field">
      <label>{{ $t('effectEditor.fields.pointsPerItem') }}</label>
      <BaseInputNumber :model-value="modelValue.config.points_per_item" :min="1" @update:model-value="(v) => updateConfig({ points_per_item: v })" />
    </div>

    <div v-else-if="modelValue.effect_type === 'points_multiplier'" class="effect-field">
      <label>{{ $t('effectEditor.fields.multiplier') }}</label>
      <BaseInputNumber
        :model-value="modelValue.config.multiplier"
        suffix="x"
        :min="1"
        :min-fraction-digits="0"
        :max-fraction-digits="2"
        @update:model-value="(v) => updateConfig({ multiplier: v })"
      />
      <p class="effect-hint">{{ $t('effectEditor.multiplierHint') }}</p>
    </div>

    <div v-if="modelValue.scope === 'line_item'" class="effect-field">
      <label>{{ $t('effectEditor.fields.appliesToLineItems') }}</label>
      <ConditionTreeEditor :model-value="modelValue.target_condition" :allow-empty="false" @update:model-value="(v) => update({ target_condition: v })" />
    </div>
  </div>
</template>

<style scoped>
.effect-editor {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
  padding: 1.25rem 0;
}

.effect-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.effect-type-select {
  flex: 1 1 auto;
  min-width: 0;
}

/* The selected value shown on the closed select — icon + label/description
   stack, replacing the plain text label a generic dropdown would show. */
.effect-type-value {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  min-width: 0;
}

.effect-type-option {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  min-width: 0;
  width: 100%;
}

.effect-type-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 1.75rem;
  height: 1.75rem;
  border-radius: var(--radius-sm);
  background: var(--color-primary-subtle);
  color: var(--color-primary);
  font-size: 0.8125rem;
}

.effect-type-text {
  display: flex;
  flex-direction: column;
  min-width: 0;
  text-align: left;
}

.effect-type-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.effect-type-desc {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.effect-type-check {
  margin-left: auto;
  flex-shrink: 0;
  color: var(--color-primary);
}

.effect-scope {
  align-self: flex-start;
}

.effect-config-row {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
}

.effect-field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.effect-field label {
  font-size: 0.875rem;
  font-weight: 600;
}

.effect-hint {
  color: var(--color-text-muted);
  font-size: 0.8125rem;
  margin: 0;
  max-width: 24rem;
}

.free-item-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.free-item-word {
  font-size: 0.875rem;
  color: var(--color-text);
}

.free-item-qty {
  flex: 0 0 5rem;
}

.free-item-arrow {
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.free-item-spacer {
  flex: 1 1 auto;
}

.free-item-repeatable {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  cursor: pointer;
}
</style>
