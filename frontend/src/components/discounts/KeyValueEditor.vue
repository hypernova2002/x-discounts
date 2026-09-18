<script setup>
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import CustomAttributeSelect from './CustomAttributeSelect.vue'

defineOptions({ name: 'KeyValueEditor' })

const props = defineProps({
  modelValue: { type: Array, required: true },
  entity: { type: String, required: true },
})
const emit = defineEmits(['update:modelValue'])

function update(list) {
  emit('update:modelValue', list)
}
function add() {
  update([...props.modelValue, { key: '', value: '' }])
}
function remove(index) {
  update(props.modelValue.filter((_, i) => i !== index))
}
function setKey(index, key) {
  const list = [...props.modelValue]
  list[index] = { ...list[index], key }
  update(list)
}
function setValue(index, value) {
  const list = [...props.modelValue]
  list[index] = { ...list[index], value }
  update(list)
}
</script>

<template>
  <div class="kv-editor">
    <div v-for="(pair, i) in modelValue" :key="i" class="kv-row">
      <CustomAttributeSelect :model-value="pair.key" :entity="entity" @update:model-value="(v) => setKey(i, v)" />
      <BaseInputText :model-value="pair.value" :placeholder="$t('keyValueEditor.valuePlaceholder')" @update:model-value="(v) => setValue(i, v)" />
      <BaseButton text severity="danger" icon="pi pi-times" @click="remove(i)" />
    </div>
    <BaseButton size="small" text :label="$t('keyValueEditor.addAttributeButton')" @click="add" />
  </div>
</template>

<style scoped>
.kv-editor {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: flex-start;
}

.kv-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

/* Base* inputs default to width:100%, which inside a flex row with no explicit
   flex-basis reads as "claim the whole row" and squeezes/wraps unexpectedly —
   give each an explicit share of the row instead. */
.kv-row > :nth-child(1),
.kv-row > :nth-child(2) {
  flex: 1 1 0%;
  min-width: 0;
}

.kv-row > :nth-child(3) {
  flex: 0 0 auto;
}
</style>
