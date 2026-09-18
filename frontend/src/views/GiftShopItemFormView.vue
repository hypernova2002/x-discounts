<script setup>
import { computed, reactive, ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseTextarea from '@/components/base/BaseTextarea.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { apiUpload, apiFileUrl, ApiError } from '@/lib/api'
import { getGiftShopItem, createGiftShopItem, updateGiftShopItem } from '@/api/giftShopItems'
import { giftShopItemInputSchema } from '@/models/giftShopItem'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const itemId = computed(() => route.params.id || null)
const isEdit = computed(() => !!itemId.value)

const loading = ref(false)
const saving = ref(false)
const loadError = ref('')
const errors = ref({})

const form = reactive({
  name: '',
  description: '',
  points_cost: 100,
  stock: null,
  unlimitedStock: true,
  enabled: true,
})

const existingPhotoUrl = ref(null)
const photoFile = ref(null)
const photoPreviewUrl = ref(null)

function onPhotoSelected(event) {
  const file = event.target.files?.[0]
  if (!file) return
  photoFile.value = file
  if (photoPreviewUrl.value) URL.revokeObjectURL(photoPreviewUrl.value)
  photoPreviewUrl.value = URL.createObjectURL(file)
}

onBeforeUnmount(() => {
  if (photoPreviewUrl.value) URL.revokeObjectURL(photoPreviewUrl.value)
})

async function load() {
  loading.value = true
  try {
    const data = await getGiftShopItem(itemId.value, { token: auth.token, projectId: auth.project?.id })
    form.name = data.name
    form.description = data.description || ''
    form.points_cost = data.points_cost
    form.stock = data.stock
    form.unlimitedStock = data.stock == null
    form.enabled = data.enabled
    existingPhotoUrl.value = data.photo_url
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('giftShopItemForm.loadError')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (isEdit.value) load()
})

function buildPayload() {
  return {
    name: form.name,
    description: form.description || null,
    points_cost: form.points_cost,
    stock: form.unlimitedStock ? null : form.stock,
    enabled: form.enabled,
  }
}

async function uploadPhotoIfSelected(id) {
  if (!photoFile.value) return
  await apiUpload(`/api/v1/admin/gift_shop_items/${id}/photo`, {
    token: auth.token,
    projectId: auth.project?.id,
    fieldName: 'photo',
    file: photoFile.value,
  })
}

async function submit() {
  errors.value = {}

  const payload = buildPayload()

  const result = giftShopItemInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  saving.value = true
  try {
    let id = itemId.value
    if (isEdit.value) {
      await updateGiftShopItem(id, result.data, { token: auth.token, projectId: auth.project?.id })
      toast.add({ severity: 'success', summary: t('giftShopItemForm.itemUpdated'), life: 3000 })
    } else {
      const item = await createGiftShopItem(result.data, { token: auth.token, projectId: auth.project?.id })
      id = item.id
      toast.add({ severity: 'success', summary: t('giftShopItemForm.itemCreated'), life: 3000 })
    }
    await uploadPhotoIfSelected(id)
    router.push({ name: 'gift-shop' })
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('giftShopItemForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
  router.push({ name: 'gift-shop' })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <h2>{{ isEdit ? $t('giftShopItemForm.editTitle') : $t('giftShopItemForm.newTitle') }}</h2>
      </template>
    </PageHeader>

    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <form class="item-form" @submit.prevent="submit">
      <BaseCard>
        <template #content>
          <div class="field-grid">
            <div class="field">
              <label for="name">{{ $t('giftShopItemForm.nameLabel') }}</label>
              <BaseInputText id="name" v-model="form.name" :invalid="!!errors.name" />
              <small v-if="errors.name" class="text-danger text-[0.8125rem]">{{ errors.name }}</small>
            </div>
            <div class="field">
              <label for="points_cost">{{ $t('giftShopItemForm.pointsCostLabel') }}</label>
              <BaseInputNumber id="points_cost" v-model="form.points_cost" :min="1" :invalid="!!errors.points_cost" />
              <small v-if="errors.points_cost" class="text-danger text-[0.8125rem]">{{ errors.points_cost }}</small>
            </div>
            <div class="field field--switch">
              <label for="enabled">{{ $t('giftShopItemForm.enabledLabel') }}</label>
              <BaseToggleSwitch id="enabled" v-model="form.enabled" />
            </div>
            <div class="field field--switch">
              <label for="unlimited">{{ $t('giftShopItemForm.unlimitedStockLabel') }}</label>
              <BaseToggleSwitch id="unlimited" v-model="form.unlimitedStock" />
            </div>
            <div v-if="!form.unlimitedStock" class="field">
              <label for="stock">{{ $t('giftShopItemForm.stockLabel') }}</label>
              <BaseInputNumber id="stock" v-model="form.stock" :min="0" :invalid="!!errors.stock" />
              <small v-if="errors.stock" class="text-danger text-[0.8125rem]">{{ errors.stock }}</small>
            </div>
          </div>

          <div class="field description-field">
            <label for="description">{{ $t('giftShopItemForm.descriptionLabel') }}</label>
            <BaseTextarea id="description" v-model="form.description" rows="3" auto-resize />
          </div>

          <div class="field photo-field">
            <label for="photo">{{ $t('giftShopItemForm.photoLabel') }}</label>
            <img v-if="photoPreviewUrl" :src="photoPreviewUrl" :alt="$t('giftShopItemForm.newPhotoAlt')" class="photo-preview" />
            <img
              v-else-if="existingPhotoUrl"
              :src="apiFileUrl(existingPhotoUrl)"
              :alt="$t('giftShopItemForm.currentPhotoAlt')"
              class="photo-preview"
            />
            <input id="photo" type="file" accept="image/png,image/jpeg,image/webp,image/gif" @change="onPhotoSelected" />
          </div>

          <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>

          <div class="form-actions">
            <BaseButton type="button" text :label="$t('giftShopItemForm.cancelButton')" @click="cancel" />
            <BaseButton type="submit" :label="isEdit ? $t('giftShopItemForm.saveChangesButton') : $t('giftShopItemForm.createButton')" :loading="saving" />
          </div>
        </template>
      </BaseCard>
    </form>
  </AppShell>
</template>

<style scoped>
.item-form {
  margin-top: 1rem;
}

.field-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.field label {
  font-size: 0.875rem;
  font-weight: 600;
}

.field--switch {
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
}

.description-field {
  margin-top: 1rem;
}

.photo-field {
  margin-top: 1rem;
}

.photo-preview {
  width: 10rem;
  height: 10rem;
  object-fit: cover;
  border-radius: 6px;
  border: 1px solid var(--color-border);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1.5rem;
}
</style>
