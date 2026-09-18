<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseButton from '@/components/base/BaseButton.vue'

defineOptions({ name: 'MembershipRequirementEditor' })

const { t } = useI18n()

const GROUP_OPERATORS = ['and', 'or', 'not']

const NODE_TYPE_OPTIONS = computed(() => [
  { label: t('membershipRequirementEditor.nodeTypes.requirement'), value: 'leaf' },
  { label: t('membershipRequirementEditor.nodeTypes.group'), value: 'group' },
])
const GROUP_OPERATOR_OPTIONS = computed(() => [
  { label: t('membershipRequirementEditor.groupOperators.all'), value: 'and' },
  { label: t('membershipRequirementEditor.groupOperators.any'), value: 'or' },
  { label: t('membershipRequirementEditor.groupOperators.not'), value: 'not' },
])
// Only aggregate activity metrics make sense as join requirements — not identity
// fields like membership_tier, and not arbitrary custom attributes.
const METRIC_OPTIONS = computed(() => [
  { label: t('membershipRequirementEditor.metrics.totalSpent'), value: 'total_spent' },
  { label: t('membershipRequirementEditor.metrics.orderCount'), value: 'order_count' },
  { label: t('membershipRequirementEditor.metrics.itemCount'), value: 'item_count' },
  { label: t('membershipRequirementEditor.metrics.pointsEarned'), value: 'points_earned' },
])
const OPERATOR_OPTIONS = computed(() => [
  { label: t('membershipRequirementEditor.operators.eq'), value: 'eq' },
  { label: t('membershipRequirementEditor.operators.ne'), value: 'ne' },
  { label: t('membershipRequirementEditor.operators.gt'), value: 'gt' },
  { label: t('membershipRequirementEditor.operators.gte'), value: 'gte' },
  { label: t('membershipRequirementEditor.operators.lt'), value: 'lt' },
  { label: t('membershipRequirementEditor.operators.lte'), value: 'lte' },
])

const props = defineProps({
  modelValue: { type: Object, default: null },
  allowEmpty: { type: Boolean, default: true },
  removable: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'remove'])

function defaultLeaf() {
  return { entity: 'customer', key: 'total_spent', operator: 'gte', value: 0, window_days: null }
}

const isGroup = computed(() => !!props.modelValue && GROUP_OPERATORS.includes(props.modelValue.operator))
const nodeType = computed(() => (isGroup.value ? 'group' : 'leaf'))

function update(patch) {
  emit('update:modelValue', { ...props.modelValue, ...patch })
}

function setNodeType(type) {
  if (type === 'group') {
    emit('update:modelValue', { operator: 'and', conditions: [props.modelValue || defaultLeaf()] })
  } else {
    emit('update:modelValue', props.modelValue?.conditions?.[0] || defaultLeaf())
  }
}

function addCondition() {
  emit('update:modelValue', defaultLeaf())
}

function addSiblingCondition() {
  emit('update:modelValue', { operator: 'and', conditions: [props.modelValue, defaultLeaf()] })
}

function setGroupOperator(op) {
  const conditions = op === 'not' ? props.modelValue.conditions.slice(0, 1) : props.modelValue.conditions
  update({ operator: op, conditions })
}

function setKey(key) {
  update({ key, entity: 'customer' })
}

function setWindowDays(days) {
  update({ window_days: days || null })
}

function updateChild(index, value) {
  const conditions = [...props.modelValue.conditions]
  conditions[index] = value
  update({ conditions })
}

function addChild() {
  update({ conditions: [...props.modelValue.conditions, defaultLeaf()] })
}

function removeChild(index) {
  update({ conditions: props.modelValue.conditions.filter((_, i) => i !== index) })
}
</script>

<template>
  <div class="condition-node">
    <div v-if="!modelValue" class="condition-empty">
      <span>{{ $t('membershipRequirementEditor.emptyState') }}</span>
      <BaseButton size="small" text :label="$t('membershipRequirementEditor.addRequirementButton')" @click="addCondition" />
    </div>

    <div v-else class="condition-box">
      <div class="condition-row">
        <BaseSelect
          class="node-type-select"
          :model-value="nodeType"
          :options="NODE_TYPE_OPTIONS"
          option-label="label"
          option-value="value"
          @update:model-value="setNodeType"
        />

        <template v-if="isGroup">
          <BaseSelect
            :model-value="modelValue.operator"
            :options="GROUP_OPERATOR_OPTIONS"
            option-label="label"
            option-value="value"
            @update:model-value="setGroupOperator"
          />
        </template>

        <template v-else>
          <BaseSelect :model-value="modelValue.key" :options="METRIC_OPTIONS" option-label="label" option-value="value" @update:model-value="setKey" />
          <BaseSelect
            :model-value="modelValue.operator"
            :options="OPERATOR_OPTIONS"
            option-label="label"
            option-value="value"
            @update:model-value="(v) => update({ operator: v })"
          />
          <BaseInputNumber :model-value="modelValue.value" :min="0" @update:model-value="(v) => update({ value: v })" />
          <BaseInputNumber
            :model-value="modelValue.window_days"
            :placeholder="t('membershipRequirementEditor.lifetimePlaceholder')"
            :min="1"
            suffix=" days"
            @update:model-value="setWindowDays"
          />
          <BaseButton size="small" text :label="$t('membershipRequirementEditor.addSiblingRequirementButton')" @click="addSiblingCondition" />
        </template>

        <BaseButton v-if="allowEmpty" text severity="danger" icon="pi pi-times" @click="$emit('update:modelValue', null)" />
        <BaseButton v-else-if="removable" text severity="danger" icon="pi pi-times" @click="$emit('remove')" />
      </div>

      <div v-if="isGroup" class="condition-children">
        <MembershipRequirementEditor
          v-for="(child, i) in modelValue.conditions"
          :key="i"
          :model-value="child"
          :allow-empty="false"
          removable
          @update:model-value="(v) => updateChild(i, v)"
          @remove="removeChild(i)"
        />
        <BaseButton v-if="modelValue.operator !== 'not'" size="small" text :label="$t('membershipRequirementEditor.addRequirementButton')" @click="addChild" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.condition-empty {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.condition-box {
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 0.75rem;
}

.condition-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

/* Base* selects/inputs default to width:100%, which as a flex child with no
   explicit flex-basis claims the whole row and wraps onto its own line —
   give each control a shrink-to-content basis instead. Buttons already
   size to content, so they're excluded. */
.condition-row > :not(button) {
  flex: 1 1 10rem;
  min-width: 0;
}

.condition-row > button {
  flex: 0 0 auto;
}

.condition-row > .node-type-select {
  flex: 0 1 auto;
  min-width: 8rem;
}

.condition-children {
  margin-top: 0.75rem;
  margin-left: 1.5rem;
  padding-left: 0.75rem;
  border-left: 2px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
</style>
