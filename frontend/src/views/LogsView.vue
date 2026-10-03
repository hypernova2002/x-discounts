<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import type { DateRange } from '@/components/DateRangePicker.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { listActivityLogs } from '@/api/activityLogs'
import { ACTIVITY_LOG_ACTIONS } from '@/models/activityLog'
import type { ActivityLog } from '@/models/activityLog'
import { formatDateTime } from '@/lib/format'

const auth = useAuthStore()
const { t } = useI18n()

const logs = ref<ActivityLog[]>([])
const loading = ref(false)
const loadError = ref('')
const range = ref<DateRange | null>(null)
const entityTypeFilter = ref<string | null>(null)
const actionFilter = ref<string | null>(null)

// Every model that includes Auditable (see backend/app/models/concerns/auditable.rb).
const ENTITY_TYPE_OPTIONS = [
  'Project',
  'Campaign',
  'Discount',
  'DiscountEffect',
  'DiscountStackingCompatibility',
  'CouponCode',
  'CustomAttribute',
  'Customer',
  'Order',
  'OrderLineItem',
  'OrderDiscount',
  'Redemption',
  'DiscountRefund',
  'PointsRedemption',
  'LoyaltyPointLot',
  'LoyaltyPointLedgerEntry',
  'MembershipScheme',
  'MembershipTier',
  'GiftShopItem',
  'GiftShopRedemption',
  'ApiKey',
  'ProjectMembership',
].map((value) => ({ label: value, value }))

const ACTION_OPTIONS = ACTIVITY_LOG_ACTIONS.map((value) => ({ label: t(`logs.action.${value}`), value }))
const ACTION_SEVERITIES: Record<string, string> = { create: 'success', update: 'info', delete: 'danger' }

async function load() {
  loading.value = true
  loadError.value = ''
  try {
    logs.value = await listActivityLogs({
      entityType: entityTypeFilter.value ?? undefined,
      action: actionFilter.value ?? undefined,
      from: range.value?.from,
      to: range.value?.to,
      perPage: 200,
      token: auth.token ?? undefined,
      projectId: auth.project?.id,
    })
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('logs.loadError')
  } finally {
    loading.value = false
  }
}

watch([entityTypeFilter, actionFilter, range], load)
onMounted(load)

interface LogGroup {
  request_id: string | null
  actor_label: string | null
  created_at: string
  entries: ActivityLog[]
}

// Groups adjacent same-request_id rows for display — guaranteed contiguous
// since the backend orders by id desc. A row with no request_id (shouldn't
// normally happen; every write in this app is authenticated) renders as its
// own singleton group.
const groups = computed<LogGroup[]>(() => {
  const result: LogGroup[] = []
  for (const log of logs.value) {
    const last = result[result.length - 1]
    if (last && log.request_id && last.request_id === log.request_id) {
      last.entries.push(log)
    } else {
      result.push({ request_id: log.request_id, actor_label: log.actor_label, created_at: log.created_at, entries: [log] })
    }
  }
  return result
})

function groupKey(group: LogGroup): string {
  return group.request_id || `single-${group.entries[0].id}`
}

function groupSummary(group: LogGroup): string {
  const first = group.entries[0]
  const label = `${t(`logs.action.${first.action}`)} ${first.entity_type} "${first.entity_label}"`
  return group.entries.length > 1 ? t('logs.groupSummarySuffix', { label, count: group.entries.length - 1 }) : label
}

const expandedGroups = ref<Set<string>>(new Set())
function toggleGroup(group: LogGroup) {
  const key = groupKey(group)
  const next = new Set(expandedGroups.value)
  if (next.has(key)) next.delete(key)
  else next.add(key)
  expandedGroups.value = next
}

const detailEntry = ref<ActivityLog | null>(null)
function showDetail(entry: ActivityLog) {
  detailEntry.value = entry
}

interface ChangeRow {
  field: string
  isDiff: boolean
  before: unknown
  after: unknown
}

// Normalizes both shapes changes can take: {field: [old, new]} for an update,
// or a flat {field: value} snapshot for a create/delete.
const changeRows = computed<ChangeRow[]>(() => {
  if (!detailEntry.value) return []
  return Object.entries(detailEntry.value.changes).map(([field, pair]) => ({
    field,
    isDiff: Array.isArray(pair) && pair.length === 2,
    before: Array.isArray(pair) ? pair[0] : undefined,
    after: Array.isArray(pair) ? pair[1] : pair,
  }))
})

function formatChangeValue(value: unknown): string {
  if (value === null || value === undefined) return '—'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <DateRangePicker v-model="range" />
      </template>
    </PageHeader>

    <BaseCard class="section-card">
      <template #content>
        <div class="filters">
          <BaseSelect
            v-model="entityTypeFilter"
            :options="ENTITY_TYPE_OPTIONS"
            option-label="label"
            option-value="value"
            :placeholder="t('logs.entityTypeFilterPlaceholder')"
            show-clear
            filter
          />
          <BaseSelect v-model="actionFilter" :options="ACTION_OPTIONS" option-label="label" option-value="value" :placeholder="t('logs.actionFilterPlaceholder')" show-clear />
        </div>

        <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>
        <p v-else-if="!loading && !groups.length" class="empty-hint">{{ t('logs.empty') }}</p>

        <div v-else class="log-groups">
          <div v-for="group in groups" :key="groupKey(group)" class="log-group">
            <button type="button" class="log-group__header" :class="{ 'log-group__header--static': group.entries.length === 1 }" @click="group.entries.length > 1 && toggleGroup(group)">
              <i
                v-if="group.entries.length > 1"
                :class="['pi', expandedGroups.has(groupKey(group)) ? 'pi-chevron-down' : 'pi-chevron-right']"
                aria-hidden="true"
              />
              <span class="log-group__summary">{{ groupSummary(group) }}</span>
              <span class="log-group__actor">{{ group.actor_label || t('logs.systemActor') }}</span>
              <span class="log-group__time">{{ formatDateTime(group.created_at, auth.project?.timezone) }}</span>
            </button>
            <ul v-if="group.entries.length === 1 || expandedGroups.has(groupKey(group))" class="log-entries">
              <li v-for="entry in group.entries" :key="entry.id" class="log-entry" @click="showDetail(entry)">
                <BaseTag :severity="ACTION_SEVERITIES[entry.action]" :value="t(`logs.action.${entry.action}`)" />
                <span class="log-entry__type">{{ entry.entity_type }}</span>
                <span class="log-entry__label">{{ entry.entity_label }}</span>
                <span class="log-entry__field-count">{{ t('logs.fieldsChanged', { count: Object.keys(entry.changes).length }) }}</span>
              </li>
            </ul>
          </div>
        </div>
      </template>
    </BaseCard>

    <BaseDialog :visible="!!detailEntry" modal :header="t('logs.detailDialog.header')" :style="{ width: '32rem' }" @update:visible="detailEntry = null">
      <div v-if="detailEntry" class="detail-dialog">
        <dl class="details">
          <dt>{{ t('logs.detailDialog.entity') }}</dt>
          <dd>{{ detailEntry.entity_type }} — {{ detailEntry.entity_label }}</dd>
          <dt>{{ t('logs.detailDialog.actor') }}</dt>
          <dd>{{ detailEntry.actor_label || t('logs.systemActor') }}</dd>
          <dt>{{ t('logs.detailDialog.time') }}</dt>
          <dd>{{ formatDateTime(detailEntry.created_at, auth.project?.timezone) }}</dd>
        </dl>
        <p v-if="!changeRows.length" class="empty-hint">{{ t('logs.detailDialog.noFields') }}</p>
        <table v-else class="changes-table">
          <thead>
            <tr>
              <th>{{ t('logs.detailDialog.fieldColumn') }}</th>
              <th>{{ changeRows[0].isDiff ? t('logs.detailDialog.beforeColumn') : t('logs.detailDialog.valueColumn') }}</th>
              <th v-if="changeRows[0].isDiff">{{ t('logs.detailDialog.afterColumn') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in changeRows" :key="row.field">
              <td>{{ row.field }}</td>
              <td>{{ formatChangeValue(row.isDiff ? row.before : row.after) }}</td>
              <td v-if="row.isDiff">{{ formatChangeValue(row.after) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.section-card {
  margin-bottom: 1.5rem;
}

.filters {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  margin: 0;
}

.log-groups {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.log-group {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.log-group__header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.625rem 0.75rem;
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  font: inherit;
}

.log-group__header--static {
  cursor: default;
}

.log-group__header:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: -2px;
}

.log-group__summary {
  flex: 1;
  font-weight: 500;
}

.log-group__actor,
.log-group__time {
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  white-space: nowrap;
}

.log-entries {
  list-style: none;
  margin: 0;
  padding: 0 0.75rem 0.5rem 2rem;
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.log-entry {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: var(--font-size-sm);
  cursor: pointer;
  padding: 0.25rem 0;
}

.log-entry:hover .log-entry__label {
  text-decoration: underline;
}

.log-entry__type {
  color: var(--color-text-muted);
}

.log-entry__field-count {
  color: var(--color-text-muted);
  margin-left: auto;
}

.details {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.375rem 0.75rem;
  margin: 0 0 1rem;
  font-size: var(--font-size-sm);
}

.details dt {
  font-weight: 600;
  color: var(--color-text-muted);
}

.details dd {
  margin: 0;
}

.changes-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--font-size-sm);
}

.changes-table th,
.changes-table td {
  text-align: left;
  padding: 0.375rem 0.5rem;
  border-bottom: 1px solid var(--color-border);
  word-break: break-word;
}

.changes-table th {
  color: var(--color-text-muted);
  font-weight: 600;
}
</style>
