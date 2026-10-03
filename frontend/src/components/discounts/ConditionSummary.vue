<script setup lang="ts">
import { useI18n } from 'vue-i18n'

defineOptions({ name: 'ConditionSummary' })

export interface ConditionNode {
  operator: string
  entity?: string
  key?: string
  value?: unknown
  conditions?: ConditionNode[]
}

withDefaults(defineProps<{ node?: ConditionNode | null }>(), { node: null })

const { t } = useI18n()

const GROUP_LABEL_KEYS: Record<string, string> = { and: 'all', or: 'any', not: 'not' }
const OPERATOR_LABEL_KEYS: Record<string, string> = {
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
const NULLARY_OPERATORS = ['is_null', 'is_not_null']

function isGroup(node?: ConditionNode | null): boolean {
  return !!node && ['and', 'or', 'not'].includes(node.operator)
}

function groupLabel(operator: string): string {
  const key = GROUP_LABEL_KEYS[operator]
  return key ? t(`conditionSummary.groups.${key}`) : operator
}

function operatorLabel(operator: string): string {
  const key = OPERATOR_LABEL_KEYS[operator]
  return key ? t(`conditionSummary.operators.${key}`) : operator
}

function formatValue(value: unknown): string {
  if (value == null) return ''
  return Array.isArray(value) ? value.join(', ') : String(value)
}
</script>

<template>
  <span v-if="!node || Object.keys(node).length === 0" class="condition-summary condition-summary--empty">{{ $t('conditionSummary.appliesToEveryone') }}</span>
  <span v-else-if="!isGroup(node)" class="condition-summary">
    <strong>{{ node.entity }}.{{ node.key }}</strong>
    {{ operatorLabel(node.operator) }}
    <template v-if="!NULLARY_OPERATORS.includes(node.operator)">{{ formatValue(node.value) }}</template>
  </span>
  <div v-else class="condition-summary-group">
    <span class="condition-summary-group__label">{{ groupLabel(node.operator) }}:</span>
    <ul>
      <li v-for="(child, i) in node.conditions" :key="i"><ConditionSummary :node="child" /></li>
    </ul>
  </div>
</template>

<style scoped>
.condition-summary--empty {
  color: var(--p-text-muted-color, #6b7280);
  font-style: italic;
}

.condition-summary-group {
  font-size: 0.9375rem;
}

.condition-summary-group__label {
  font-weight: 600;
}

.condition-summary-group ul {
  margin: 0.25rem 0 0;
  padding-left: 1.25rem;
}
</style>
