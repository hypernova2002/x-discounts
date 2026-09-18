<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
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
    <div class="effect-row">
      <BaseSelect
        :model-value="modelValue.effect_type"
        :options="effectTypeOptions"
        option-label="label"
        option-value="value"
        @update:model-value="setEffectType"
      />
      <BaseSelect
        :model-value="modelValue.scope"
        :options="SCOPE_OPTIONS"
        option-label="label"
        option-value="value"
        :disabled="modelValue.effect_type === 'points_per_item'"
        @update:model-value="setScope"
      />
      <BaseButton text severity="danger" icon="pi pi-trash" :label="$t('effectEditor.removeEffectButton')" @click="$emit('remove')" />
    </div>

    <div v-if="modelValue.effect_type === 'percentage_off'" class="effect-field">
      <label>{{ $t('effectEditor.fields.percentageOff') }}</label>
      <BaseInputNumber
        :model-value="modelValue.config.percentage"
        suffix="%"
        :min="0"
        :max="100"
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
      <div class="effect-config-row">
        <div class="effect-field">
          <label>{{ $t('effectEditor.fields.buyQuantity') }}</label>
          <BaseInputNumber :model-value="modelValue.config.buy_quantity" :min="1" @update:model-value="(v) => updateConfig({ buy_quantity: v })" />
        </div>
        <div class="effect-field">
          <label>{{ $t('effectEditor.fields.getQuantity') }}</label>
          <BaseInputNumber :model-value="modelValue.config.get_quantity" :min="1" @update:model-value="(v) => updateConfig({ get_quantity: v })" />
        </div>
        <div class="effect-field effect-field--switch">
          <label>{{ $t('effectEditor.fields.repeatable') }}</label>
          <BaseToggleSwitch :model-value="modelValue.config.repeatable" @update:model-value="(v) => updateConfig({ repeatable: v })" />
        </div>
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
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.effect-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* Base* selects default to width:100%, which as a flex child with no
   explicit flex-basis claims the whole row and squeezes everything else —
   give each control a shrink-to-content basis instead. The button already
   sizes to content, so it's excluded. */
.effect-row > :not(button) {
  flex: 1 1 10rem;
  min-width: 0;
}

.effect-row > button {
  flex: 0 0 auto;
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

.effect-field--switch {
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
}

.effect-hint {
  color: var(--color-text-muted);
  font-size: 0.8125rem;
  margin: 0;
  max-width: 24rem;
}
</style>
