<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseCheckbox from '@/components/base/BaseCheckbox.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { createCustomer } from '@/api/customers'
import { customerInputSchema } from '@/models/customer'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const saving = ref(false)
const errors = ref({})

const form = reactive({
  external_id: '',
  name: '',
  email: '',
  phone_number: '',
  country: '',
  date_of_birth: '',
  marketing_opt_in: false,
})

async function submit() {
  errors.value = {}

  const payload = {
    external_id: form.external_id,
    name: form.name || null,
    email: form.email || null,
    phone_number: form.phone_number || null,
    country: form.country || null,
    date_of_birth: form.date_of_birth || null,
    marketing_opt_in: form.marketing_opt_in,
  }

  const result = customerInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  saving.value = true
  try {
    const customer = await createCustomer(result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('customerForm.customerCreated'), life: 3000 })
    router.push({ name: 'customer-show', params: { id: customer.id } })
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('customerForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
  router.push({ name: 'customers' })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <h2>{{ $t('customerForm.newTitle') }}</h2>
      </template>
    </PageHeader>

    <form class="customer-form" @submit.prevent="submit">
      <BaseCard>
        <template #content>
          <div class="form-grid">
            <div class="field">
              <label for="external_id">{{ $t('customerForm.externalIdLabel') }}</label>
              <BaseInputText id="external_id" v-model="form.external_id" :invalid="!!errors.external_id" />
              <small v-if="errors.external_id" class="field-error">{{ errors.external_id }}</small>
            </div>
            <div class="field">
              <label for="name">{{ $t('customerForm.nameLabel') }}</label>
              <BaseInputText id="name" v-model="form.name" :invalid="!!errors.name" />
              <small v-if="errors.name" class="field-error">{{ errors.name }}</small>
            </div>
            <div class="field">
              <label for="email">{{ $t('customerForm.emailLabel') }}</label>
              <BaseInputText id="email" v-model="form.email" type="email" :invalid="!!errors.email" />
              <small v-if="errors.email" class="field-error">{{ errors.email }}</small>
            </div>
            <div class="field">
              <label for="phone_number">{{ $t('customerForm.phoneLabel') }}</label>
              <BaseInputText id="phone_number" v-model="form.phone_number" :invalid="!!errors.phone_number" />
              <small v-if="errors.phone_number" class="field-error">{{ errors.phone_number }}</small>
            </div>
            <div class="field">
              <label for="country">{{ $t('customerForm.countryLabel') }}</label>
              <BaseInputText id="country" v-model="form.country" :invalid="!!errors.country" />
              <small v-if="errors.country" class="field-error">{{ errors.country }}</small>
            </div>
            <div class="field">
              <label for="date_of_birth">{{ $t('customerForm.dateOfBirthLabel') }}</label>
              <BaseInputText id="date_of_birth" v-model="form.date_of_birth" type="date" :invalid="!!errors.date_of_birth" />
              <small v-if="errors.date_of_birth" class="field-error">{{ errors.date_of_birth }}</small>
            </div>
            <div class="field field--checkbox">
              <BaseCheckbox v-model="form.marketing_opt_in" binary input-id="marketing_opt_in" />
              <label for="marketing_opt_in">{{ $t('customerForm.marketingOptInLabel') }}</label>
            </div>
          </div>
        </template>
      </BaseCard>

      <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>

      <div class="form-actions">
        <BaseButton type="button" text :label="$t('customerForm.cancelButton')" @click="cancel" />
        <BaseButton type="submit" :label="$t('customerForm.createButton')" :loading="saving" />
      </div>
    </form>
  </AppShell>
</template>

<style scoped>
.customer-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 1rem;
  max-width: 32rem;
}

.form-grid {
  display: flex;
  flex-direction: column;
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

.field--checkbox {
  flex-direction: row;
  align-items: center;
  gap: 0.5rem;
}

.field--checkbox label {
  font-weight: 400;
}

.field-error {
  color: var(--color-danger);
  font-size: 0.8125rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}
</style>
