<script setup>
import { useI18n } from 'vue-i18n'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseButton from '@/components/base/BaseButton.vue'

defineProps({ visible: { type: Boolean, required: true } })
const emit = defineEmits(['stay', 'discard'])

const { t } = useI18n()
</script>

<template>
  <BaseDialog
    :visible="visible"
    modal
    :closable="false"
    :header="t('unsavedChanges.title')"
    :style="{ width: '24rem' }"
    @update:visible="(v) => !v && emit('stay')"
  >
    <p class="message">{{ t('unsavedChanges.message') }}</p>
    <div class="actions">
      <BaseButton outlined :label="t('unsavedChanges.stayButton')" @click="emit('stay')" />
      <BaseButton severity="danger" :label="t('unsavedChanges.discardButton')" @click="emit('discard')" />
    </div>
  </BaseDialog>
</template>

<style scoped>
.message {
  margin: 0 0 1rem;
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}
</style>
