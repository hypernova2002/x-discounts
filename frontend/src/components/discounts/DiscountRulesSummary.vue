<script setup>
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'
import ConditionSummary from './ConditionSummary.vue'
import { formatNumber } from '@/lib/format'

defineOptions({ name: 'DiscountRulesSummary' })

defineProps({
  discount: { type: Object, required: true },
})

const { t } = useI18n()

function configSummary(effect) {
  const c = effect.config
  if (effect.effect_type === 'percentage_off') return t('discountRulesSummary.percentageOff', { percentage: formatNumber(c.percentage) })
  if (effect.effect_type === 'fixed_amount_off') return t('discountRulesSummary.fixedAmountOff', { amount: formatNumber(c.amount), currency: c.currency })
  if (effect.effect_type === 'free_item') {
    const key = c.repeatable ? 'discountRulesSummary.freeItemRepeatable' : 'discountRulesSummary.freeItem'
    return t(key, { buyQuantity: formatNumber(c.buy_quantity), getQuantity: formatNumber(c.get_quantity) })
  }
  return ''
}
</script>

<template>
  <div class="discount-rules">
    <div class="discount-rules__section">
      <h4>{{ $t('discountRulesSummary.eligibilityHeading') }}</h4>
      <ConditionSummary :node="discount.eligibility_condition" />
    </div>
    <div class="discount-rules__section">
      <h4>{{ $t('discountRulesSummary.effectsHeading') }}</h4>
      <p v-if="!discount.effects.length" class="discount-rules__empty">{{ $t('discountRulesSummary.noEffects') }}</p>
      <div v-for="effect in discount.effects" :key="effect.id" class="discount-rules__effect">
        <div class="discount-rules__effect-header">
          <BaseTag :value="effect.effect_type" />
          <BaseTag severity="secondary" :value="effect.scope" />
          <span>{{ configSummary(effect) }}</span>
        </div>
        <div v-if="effect.scope === 'line_item'" class="discount-rules__condition">
          {{ $t('discountRulesSummary.appliesToLineItemsWhere') }} <ConditionSummary :node="effect.target_condition" />
        </div>
        <div v-if="effect.effect_type === 'free_item'" class="discount-rules__condition">
          {{ $t('discountRulesSummary.buyLabel') }} <ConditionSummary :node="effect.config.buy_condition" /><br />
          {{ $t('discountRulesSummary.getLabel') }} <ConditionSummary :node="effect.config.get_condition" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.discount-rules {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  font-size: 0.875rem;
}

.discount-rules__section h4 {
  margin: 0 0 0.25rem;
  font-size: 0.8125rem;
  text-transform: uppercase;
  letter-spacing: 0.02em;
  color: var(--color-text-muted);
}

.discount-rules__effect {
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 0.5rem 0.75rem;
  margin-bottom: 0.5rem;
}

.discount-rules__effect:last-child {
  margin-bottom: 0;
}

.discount-rules__effect-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.discount-rules__condition {
  margin-top: 0.375rem;
}

.discount-rules__empty {
  color: var(--color-text-muted);
  margin: 0;
}
</style>
