<script setup>
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import CustomAttributeSelect from './CustomAttributeSelect.vue'
import { useAuthStore } from '@/stores/auth'
import { useCustomAttributes } from '@/composables/useCustomAttributes'
import { reservedKeysFor } from '@/lib/reservedConditionKeys'

defineOptions({ name: 'ConditionTreeEditor' })

const { t } = useI18n()

const GROUP_OPERATORS = ['and', 'or', 'not']
const NULLARY_OPERATORS = ['is_null', 'is_not_null']

const OPERATORS_BY_DATA_TYPE = {
  string: ['eq', 'ne', 'in', 'not_in', 'contains', ...NULLARY_OPERATORS],
  number: ['eq', 'ne', 'gt', 'gte', 'lt', 'lte', 'in', 'not_in', ...NULLARY_OPERATORS],
  date: ['eq', 'ne', 'gt', 'gte', 'lt', 'lte', ...NULLARY_OPERATORS],
  boolean: ['eq', 'ne', ...NULLARY_OPERATORS],
}

const NODE_TYPE_OPTIONS = computed(() => [
  { label: t('conditionTreeEditor.nodeTypes.condition'), value: 'leaf' },
  { label: t('conditionTreeEditor.nodeTypes.group'), value: 'group' },
])
const GROUP_OPERATOR_OPTIONS = computed(() => [
  { label: t('conditionTreeEditor.groupOperators.all'), value: 'and' },
  { label: t('conditionTreeEditor.groupOperators.any'), value: 'or' },
  { label: t('conditionTreeEditor.groupOperators.not'), value: 'not' },
])
const LEAF_OPERATOR_OPTIONS = computed(() => [
  { label: t('conditionTreeEditor.operators.eq'), value: 'eq' },
  { label: t('conditionTreeEditor.operators.ne'), value: 'ne' },
  { label: t('conditionTreeEditor.operators.gt'), value: 'gt' },
  { label: t('conditionTreeEditor.operators.gte'), value: 'gte' },
  { label: t('conditionTreeEditor.operators.lt'), value: 'lt' },
  { label: t('conditionTreeEditor.operators.lte'), value: 'lte' },
  { label: t('conditionTreeEditor.operators.in'), value: 'in' },
  { label: t('conditionTreeEditor.operators.notIn'), value: 'not_in' },
  { label: t('conditionTreeEditor.operators.contains'), value: 'contains' },
  { label: t('conditionTreeEditor.operators.isNull'), value: 'is_null' },
  { label: t('conditionTreeEditor.operators.isNotNull'), value: 'is_not_null' },
])
const ENTITY_OPTIONS = computed(() => [
  { label: t('conditionTreeEditor.entities.cart'), value: 'cart' },
  { label: t('conditionTreeEditor.entities.lineItem'), value: 'line_item' },
  { label: t('conditionTreeEditor.entities.customer'), value: 'customer' },
])

function defaultLeaf() {
  return { entity: 'cart', key: '', operator: 'eq', value: '' }
}

const props = defineProps({
  modelValue: { type: Object, default: null },
  allowEmpty: { type: Boolean, default: true },
  removable: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'remove'])

const auth = useAuthStore()
const { load: loadCustomAttributes, attributesFor } = useCustomAttributes()

watch(
  () => props.modelValue?.entity,
  (entity) => {
    if (entity) loadCustomAttributes(entity, { token: auth.token, projectId: auth.project?.id })
  },
  { immediate: true }
)

const isGroup = computed(() => !!props.modelValue && GROUP_OPERATORS.includes(props.modelValue.operator))
const nodeType = computed(() => (isGroup.value ? 'group' : 'leaf'))
const isMultiValue = computed(() => !!props.modelValue && ['in', 'not_in'].includes(props.modelValue.operator))
const isNullaryOperator = computed(() => !!props.modelValue && NULLARY_OPERATORS.includes(props.modelValue.operator))

const entityAttributes = computed(() => [
  ...reservedKeysFor(props.modelValue?.entity),
  ...attributesFor(props.modelValue?.entity),
])
const selectedAttribute = computed(() => entityAttributes.value.find((a) => a.key === props.modelValue?.key))
const availableOperators = computed(() => {
  const dataType = selectedAttribute.value?.data_type
  if (!dataType) return LEAF_OPERATOR_OPTIONS.value
  return LEAF_OPERATOR_OPTIONS.value.filter((o) => OPERATORS_BY_DATA_TYPE[dataType].includes(o.value))
})

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

// Turns a single leaf into a 2-condition AND group, keeping the leaf as-is instead
// of requiring the user to manually switch to "Group" first (which used to discard it).
function addSiblingCondition() {
  emit('update:modelValue', { operator: 'and', conditions: [props.modelValue, defaultLeaf()] })
}

function setGroupOperator(op) {
  const conditions = op === 'not' ? props.modelValue.conditions.slice(0, 1) : props.modelValue.conditions
  update({ operator: op, conditions })
}

function setEntity(entity) {
  update({ entity, key: '', operator: 'eq', value: '' })
}

function setKey(key) {
  update({ key, operator: 'eq', value: '' })
}

function setOperator(operator) {
  update({ operator, value: NULLARY_OPERATORS.includes(operator) ? null : props.modelValue.value })
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

function coerce(str) {
  const trimmed = str.trim()
  if (trimmed === 'true') return true
  if (trimmed === 'false') return false
  if (trimmed !== '' && !Number.isNaN(Number(trimmed))) return Number(trimmed)
  return trimmed
}

const valueDisplay = computed({
  get() {
    const v = props.modelValue?.value
    if (v == null) return ''
    return Array.isArray(v) ? v.join(', ') : String(v)
  },
  set(raw) {
    if (isMultiValue.value) {
      update({
        value: raw
          .split(',')
          .map((s) => coerce(s.trim()))
          .filter((s) => s !== ''),
      })
    } else {
      update({ value: coerce(raw) })
    }
  },
})
</script>

<template>
  <div class="condition-node">
    <div v-if="!modelValue" class="condition-empty">
      <span>{{ $t('conditionTreeEditor.emptyState') }}</span>
      <BaseButton size="small" text :label="$t('conditionTreeEditor.addConditionButton')" @click="addCondition" />
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
          <BaseSelect
            :model-value="modelValue.entity"
            :options="ENTITY_OPTIONS"
            option-label="label"
            option-value="value"
            @update:model-value="setEntity"
          />
          <CustomAttributeSelect :model-value="modelValue.key" :entity="modelValue.entity" @update:model-value="setKey" />
          <BaseSelect
            :model-value="modelValue.operator"
            :options="availableOperators"
            option-label="label"
            option-value="value"
            @update:model-value="setOperator"
          />
          <BaseInputText
            v-if="!isNullaryOperator"
            v-model="valueDisplay"
            :placeholder="isMultiValue ? $t('conditionTreeEditor.valueListPlaceholder') : $t('conditionTreeEditor.valuePlaceholder')"
          />
          <BaseButton size="small" text :label="$t('conditionTreeEditor.addSiblingConditionButton')" @click="addSiblingCondition" />
        </template>

        <BaseButton v-if="allowEmpty" text severity="danger" icon="pi pi-times" @click="$emit('update:modelValue', null)" />
        <BaseButton v-else-if="removable" text severity="danger" icon="pi pi-times" @click="$emit('remove')" />
      </div>

      <div v-if="isGroup" class="condition-children">
        <ConditionTreeEditor
          v-for="(child, i) in modelValue.conditions"
          :key="i"
          :model-value="child"
          :allow-empty="false"
          removable
          @update:model-value="(v) => updateChild(i, v)"
          @remove="removeChild(i)"
        />
        <BaseButton v-if="modelValue.operator !== 'not'" size="small" text :label="$t('conditionTreeEditor.addConditionButton')" @click="addChild" />
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
