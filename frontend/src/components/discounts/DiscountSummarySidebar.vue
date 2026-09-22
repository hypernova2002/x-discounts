<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import { formatCurrency, formatNumber, formatDateRange } from '@/lib/format'
import { zonedInputToIso } from '@/lib/timezone'

// A live, read-only reflection of the discount form — never mutates `form`,
// so there's no event surface here and no risk to the actual save payload.
// Deliberately NOT a dump of every field: each section is a short, generic
// summary (see the eligibility/effect formatters below) rather than a
// reproduction of the full rule tree, per the coupon-editor UX pass. Shared
// by coupon and promotion editing (loyalty has its own points-based effects
// this summary doesn't attempt to render, so it isn't shown there) — the
// "Coupon"/"Promotion" section title and the Availability section's shape
// (two named periods vs. one) are the only kind-specific parts.
const props = defineProps({
  form: { type: Object, required: true },
  timezone: { type: String, default: null },
  activeSection: { type: String, default: null },
})

const { t } = useI18n()

const GROUP_OPERATORS = ['and', 'or', 'not']
const NULLARY_OPERATORS = ['is_null', 'is_not_null']
// Same mapping as ConditionSummary.vue — duplicated rather than shared since
// the two components summarize differently (full nested tree vs. a flat,
// capped leaf list) and this map is a handful of lines.
const OPERATOR_LABEL_KEYS = {
  eq: 'eq',
  ne: 'ne',
  gt: 'gt',
  gte: 'gte',
  lt: 'lt',
  lte: 'lte',
  in: 'in',
  not_in: 'notIn',
  contains: 'contains',
  is_null: 'isEmpty',
  is_not_null: 'isSet',
}

const LEAF_CAP = 4

// Flattens every leaf condition regardless of and/or/not nesting — a
// deliberate simplification (see the plan): this sidebar shows "what
// generally has to be true," not the exact logical structure, since
// reproducing the full tree here is what the design explicitly avoids.
function collectLeaves(node, acc = []) {
  if (!node) return acc
  if (GROUP_OPERATORS.includes(node.operator)) {
    for (const child of node.conditions || []) collectLeaves(child, acc)
  } else if (node.entity) {
    acc.push(node)
  }
  return acc
}

function formatValue(value) {
  if (value == null) return ''
  return Array.isArray(value) ? value.join(' / ') : String(value)
}

// Generic, field-agnostic rendering ("key op value") — not a bespoke
// natural-language translator per custom-attribute key, since the app has no
// reliable way to know what an arbitrary key like "days_before_departure"
// means beyond its literal name.
function formatLeaf(node) {
  const opKey = OPERATOR_LABEL_KEYS[node.operator]
  const opLabel = opKey ? t(`conditionSummary.operators.${opKey}`) : node.operator
  const valueText = NULLARY_OPERATORS.includes(node.operator) ? '' : formatValue(node.value)
  return valueText ? `${node.key} ${opLabel} ${valueText}` : `${node.key} ${opLabel}`
}

const eligibilityLeaves = computed(() => collectLeaves(props.form.eligibility_condition))
const eligibilityTooComplex = computed(() => eligibilityLeaves.value.length > LEAF_CAP)
const eligibilitySummaryLines = computed(() =>
  eligibilityTooComplex.value ? [] : eligibilityLeaves.value.map(formatLeaf),
)

// Coupon and promotion both only ever use these three effect types (loyalty's
// points-based types are a different discount kind entirely, not summarized
// here).
const SUMMARIZABLE_EFFECT_TYPES = ['percentage_off', 'fixed_amount_off', 'free_item']

function scopeLabel(scope) {
  return t(`effectEditor.scopes.${scope === 'line_item' ? 'lineItem' : 'cart'}`)
}

function formatEffect(effect) {
  if (effect.effect_type === 'percentage_off') {
    return t('discountSummarySidebar.percentageOffSummary', { percentage: effect.config?.percentage ?? 0, scope: scopeLabel(effect.scope) })
  }
  if (effect.effect_type === 'fixed_amount_off') {
    return t('discountSummarySidebar.fixedAmountOffSummary', { amount: formatCurrency(effect.config?.amount ?? 0), scope: scopeLabel(effect.scope) })
  }
  if (effect.effect_type === 'free_item') {
    return t('discountSummarySidebar.freeItemSummary', { buy: effect.config?.buy_quantity ?? 0, get: effect.config?.get_quantity ?? 0 })
  }
  return effect.effect_type
}

const effectSummaries = computed(() => (props.form.effects || []).filter((e) => SUMMARIZABLE_EFFECT_TYPES.includes(e.effect_type)).map(formatEffect))

const usageSummaryLines = computed(() => {
  const lines = []
  if (props.form.max_redemptions) lines.push(t('discountSummarySidebar.totalRedemptionsLabel', { count: formatNumber(props.form.max_redemptions) }))
  if (props.form.max_redemptions_per_customer) {
    lines.push(t('discountSummarySidebar.perCustomerLabel', { count: formatNumber(props.form.max_redemptions_per_customer) }))
  }
  return lines.length ? lines : [t('discountSummarySidebar.unlimitedLabel')]
})

// *_from/_until are datetime-local wall-clock strings (see
// isoToZonedInput/zonedInputToIso in lib/timezone.js) — not real ISO instants
// — so they need converting back to a real instant before formatDateRange
// re-renders them in the project timezone, or the date could shift by a day
// depending on the zone's offset (same class of bug fixed earlier this
// session for analytics chart labels).
function formatPeriod(fromLocal, untilLocal) {
  if (!fromLocal && !untilLocal) return t('discountSummarySidebar.anytimeLabel')
  const fromIso = fromLocal ? zonedInputToIso(fromLocal, props.timezone) : null
  const untilIso = untilLocal ? zonedInputToIso(untilLocal, props.timezone) : null
  return formatDateRange(fromIso, untilIso, props.timezone)
}

const isCoupon = computed(() => props.form.kind === 'coupon')

const issuancePeriodText = computed(() => formatPeriod(props.form.coupon?.issued_from, props.form.coupon?.issued_until))
const redemptionPeriodText = computed(() => formatPeriod(props.form.coupon?.valid_from, props.form.coupon?.valid_until))
const activePeriodText = computed(() => formatPeriod(props.form.promotion?.active_from, props.form.promotion?.active_until))

// Conservative, entirely client-side derivable warnings only — see the plan's
// explicit "don't invent what can't be reliably determined" constraint.
const warnings = computed(() => {
  const list = []
  if (!props.form.effects || props.form.effects.length === 0) list.push(t('discountSummarySidebar.warningNoEffects'))
  if (isCoupon.value) {
    const c = props.form.coupon || {}
    if (c.valid_from && c.valid_until && c.valid_until < c.valid_from) list.push(t('discountSummarySidebar.warningRedemptionDates'))
    if (c.issued_from && c.issued_until && c.issued_until < c.issued_from) list.push(t('discountSummarySidebar.warningIssuanceDates'))
  } else {
    const p = props.form.promotion || {}
    if (p.active_from && p.active_until && p.active_until < p.active_from) list.push(t('discountSummarySidebar.warningActiveDates'))
  }
  return list
})
</script>

<template>
  <BaseCard class="summary-card">
    <template #content>
      <section class="summary-section" :class="{ 'summary-section--active': activeSection === 'coupon' }">
        <h3 class="summary-heading">{{ t(isCoupon ? 'discountSummarySidebar.couponSectionTitle' : 'discountSummarySidebar.promotionSectionTitle') }}</h3>
        <p class="summary-name">{{ form.name || t('discountSummarySidebar.unnamedLabel') }}</p>
        <p v-if="form.key" class="summary-key">{{ form.key }}</p>
        <BaseTag :severity="form.enabled ? 'success' : 'secondary'" :value="t(form.enabled ? 'discountSummarySidebar.enabledStatus' : 'discountSummarySidebar.disabledStatus')" />
      </section>

      <section class="summary-section" :class="{ 'summary-section--active': activeSection === 'discount' }">
        <h3 class="summary-heading">{{ t('discountSummarySidebar.discountSectionTitle') }}</h3>
        <ul v-if="effectSummaries.length" class="summary-list">
          <li v-for="(line, i) in effectSummaries" :key="i">{{ line }}</li>
        </ul>
        <p v-else class="summary-empty">{{ t('discountSummarySidebar.noEffectsYet') }}</p>
      </section>

      <section class="summary-section" :class="{ 'summary-section--active': activeSection === 'eligibility' }">
        <h3 class="summary-heading">{{ t('discountSummarySidebar.eligibilitySectionTitle') }}</h3>
        <p v-if="!eligibilityLeaves.length" class="summary-empty">{{ t('discountSummarySidebar.appliesToEveryone') }}</p>
        <p v-else-if="eligibilityTooComplex" class="summary-muted">{{ t('discountSummarySidebar.conditionsCountLabel', { count: eligibilityLeaves.length }) }}</p>
        <ul v-else class="summary-list">
          <li v-for="(line, i) in eligibilitySummaryLines" :key="i">{{ line }}</li>
        </ul>
      </section>

      <section class="summary-section" :class="{ 'summary-section--active': activeSection === 'usage' }">
        <h3 class="summary-heading">{{ t('discountSummarySidebar.usageSectionTitle') }}</h3>
        <ul class="summary-list">
          <li v-for="(line, i) in usageSummaryLines" :key="i">{{ line }}</li>
        </ul>
      </section>

      <section class="summary-section" :class="{ 'summary-section--active': activeSection === 'availability' }">
        <h3 class="summary-heading">{{ t('discountSummarySidebar.availabilitySectionTitle') }}</h3>
        <template v-if="isCoupon">
          <p class="summary-availability-label">{{ t('discountSummarySidebar.issuancePeriodLabel') }}</p>
          <p class="summary-muted">{{ issuancePeriodText }}</p>
          <p class="summary-availability-label">{{ t('discountSummarySidebar.redemptionPeriodLabel') }}</p>
          <p class="summary-muted">{{ redemptionPeriodText }}</p>
        </template>
        <template v-else>
          <p class="summary-availability-label">{{ t('discountSummarySidebar.activePeriodLabel') }}</p>
          <p class="summary-muted">{{ activePeriodText }}</p>
        </template>
      </section>

      <section v-if="warnings.length" class="summary-section summary-section--warnings">
        <h3 class="summary-heading">{{ t('discountSummarySidebar.warningsSectionTitle') }}</h3>
        <ul class="summary-list summary-list--warnings">
          <li v-for="(warning, i) in warnings" :key="i">
            <i class="pi pi-exclamation-triangle" aria-hidden="true" />
            {{ warning }}
          </li>
        </ul>
      </section>
    </template>
  </BaseCard>
</template>

<style scoped>
.summary-card {
  font-size: 0.8125rem;
}

.summary-section {
  padding: 0.875rem 0;
  border-top: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  transition: background-color 0.15s;
}

.summary-section:first-child {
  padding-top: 0;
  border-top: none;
}

.summary-section--active {
  background: var(--color-primary-subtle);
  margin: 0 -0.75rem;
  padding-left: 0.75rem;
  padding-right: 0.75rem;
}

.summary-section--warnings {
  border-top: 1px solid var(--color-border);
}

.summary-heading {
  margin: 0 0 0.5rem;
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
}

.summary-name {
  margin: 0 0 0.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.summary-key {
  margin: 0 0 0.5rem;
  font-family: ui-monospace, monospace;
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.summary-list {
  margin: 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  color: var(--color-text);
}

.summary-list--warnings li {
  display: flex;
  align-items: flex-start;
  gap: 0.375rem;
  color: var(--color-warning);
}

.summary-list--warnings .pi {
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.summary-empty,
.summary-muted {
  margin: 0;
  color: var(--color-text-muted);
}

.summary-availability-label {
  margin: 0.5rem 0 0.125rem;
  font-weight: 600;
  color: var(--color-text);
}

.summary-availability-label:first-of-type {
  margin-top: 0;
}
</style>
