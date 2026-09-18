import { defineStore } from 'pinia'
import { apiFetch, ApiError } from '@/lib/api'
import { useCustomAttributes } from '@/composables/useCustomAttributes'
import { useCoupons } from '@/composables/useCoupons'
import { setLocale } from '@/i18n'

const TOKEN_KEY = 'x-discounts.session-token'
const PROJECT_KEY = 'x-discounts.project-id'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: null,
    user: null,
    project: null,
    role: null,
    projects: [],
    loading: false,
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    hasProject: (state) => !!state.project,
  },

  actions: {
    // Memoized so main.js (fire-and-forget, to start the fetch as early as possible)
    // and the router guard (awaited, so it never evaluates auth state mid-restore)
    // share the same in-flight call instead of racing two separate restores.
    restore() {
      if (!this._restorePromise) this._restorePromise = this._doRestore()
      return this._restorePromise
    },

    async _doRestore() {
      const token = localStorage.getItem(TOKEN_KEY)
      if (!token) return

      this.token = token
      const cachedProjectId = localStorage.getItem(PROJECT_KEY)
      try {
        if (cachedProjectId) await this.loadMe(cachedProjectId)
        if (!this.project) await this.resolveProject()
      } catch {
        this.clear()
      }
    },

    async signup(payload) {
      return this.authenticate('/api/v1/signup', payload)
    },

    async login(email, password) {
      return this.authenticate('/api/v1/login', { email, password })
    },

    async authenticate(path, payload) {
      this.loading = true
      this.error = null
      try {
        const data = await apiFetch(path, { method: 'POST', body: payload })
        this.token = data.token
        this.user = data.user
        setLocale(this.user?.locale)
        localStorage.setItem(TOKEN_KEY, this.token)
        await this.resolveProject()
      } catch (e) {
        this.error = e instanceof ApiError ? e.message : 'Unable to reach the API'
        throw e
      } finally {
        this.loading = false
      }
    },

    async loadMe(projectId) {
      const data = await apiFetch('/api/v1/me', { token: this.token, projectId })
      this.user = data.user
      this.project = data.project
      this.role = data.role
      setLocale(this.user?.locale)
    },

    async updateLocale(locale) {
      this.user = await apiFetch(`/api/v1/admin/users/${this.user.id}`, {
        method: 'PATCH',
        token: this.token,
        projectId: this.project?.id,
        body: { locale },
      })
      setLocale(this.user.locale)
    },

    async fetchProjects() {
      const data = await apiFetch('/api/v1/admin/projects', { token: this.token })
      this.projects = data.projects
      return this.projects
    },

    // After login/signup, or on restore with no cached project: auto-pick if there's
    // exactly one project, otherwise leave unset so the UI prompts for a choice.
    async resolveProject() {
      const projects = await this.fetchProjects()
      if (projects.length === 1) {
        await this.selectProject(projects[0].id)
      }
    },

    async selectProject(projectId) {
      await this.loadMe(projectId)
      localStorage.setItem(PROJECT_KEY, projectId)
      // Custom attributes are project-scoped but cached only by entity — without this,
      // switching projects (with or without a logout in between) leaves the previous
      // project's attributes showing in every key dropdown until something else clears it.
      useCustomAttributes().invalidate()
      useCoupons().invalidate()
    },

    async logout() {
      try {
        await apiFetch('/api/v1/logout', { method: 'DELETE', token: this.token })
      } catch {
        // best-effort — clear local state regardless of whether this succeeded
      }
      this.clear()
    },

    clear() {
      this.token = null
      this.user = null
      this.project = null
      this.role = null
      this.projects = []
      this.error = null
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(PROJECT_KEY)
      useCustomAttributes().invalidate()
      useCoupons().invalidate()
    },
  },
})
