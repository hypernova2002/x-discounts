import { defineStore } from 'pinia'
import { apiFetch, ApiError } from '@/lib/api'
import { useCustomAttributes } from '@/composables/useCustomAttributes'
import { useCoupons } from '@/composables/useCoupons'
import { setLocale } from '@/i18n'
import type { User } from '@/models/user'
import type { Project } from '@/models/project'

const TOKEN_KEY = 'x-discounts.session-token'
const PROJECT_KEY = 'x-discounts.project-id'

interface AuthState {
  token: string | null
  user: User | null
  project: Project | null
  role: string | null
  projects: Project[]
  loading: boolean
  error: string | null
  otpChallengeToken: string | null
  otpRequired: boolean
  _restorePromise: Promise<void> | null
}

interface SignupPayload {
  account_name: string
  name: string
  email: string
  password: string
  password_confirmation: string
}

// Raw /api/v1/{login,signup,login/otp} response — this store calls apiFetch
// directly rather than through a src/api/*.ts + zod schema, so these shapes are
// asserted, not runtime-validated (same trust boundary this store has always had).
interface AuthResponse {
  token?: string
  user?: User
  otp_required?: boolean
  otp_challenge_token?: string
}

interface SessionData {
  token: string
  user: User
}

interface MeResponse {
  user: User
  project: Project | null
  role: string | null
  otp_required: boolean
}

interface ProjectsResponse {
  projects: Project[]
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    token: null,
    user: null,
    project: null,
    role: null,
    projects: [],
    loading: false,
    error: null,
    otpChallengeToken: null,
    otpRequired: false,
    _restorePromise: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    hasProject: (state) => !!state.project,
    needsOtpSetup: (state) => state.otpRequired && !!state.user && !state.user.otp_enabled,
  },

  actions: {
    // Memoized so main.ts (fire-and-forget, to start the fetch as early as possible)
    // and the router guard (awaited, so it never evaluates auth state mid-restore)
    // share the same in-flight call instead of racing two separate restores.
    restore(): Promise<void> {
      if (!this._restorePromise) this._restorePromise = this._doRestore()
      return this._restorePromise
    },

    async _doRestore(): Promise<void> {
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

    async signup(payload: SignupPayload): Promise<void> {
      return this.authenticate('/api/v1/signup', payload)
    },

    async login(email: string, password: string): Promise<void> {
      return this.authenticate('/api/v1/login', { email, password })
    },

    async authenticate(path: string, payload: object): Promise<void> {
      this.loading = true
      this.error = null
      this.otpChallengeToken = null
      try {
        const data = (await apiFetch(path, { method: 'POST', body: payload })) as AuthResponse
        if (data.otp_required) {
          this.otpChallengeToken = data.otp_challenge_token ?? null
          return
        }
        await this._applySession(data as SessionData)
      } catch (e) {
        this.error = e instanceof ApiError ? e.message : 'Unable to reach the API'
        throw e
      } finally {
        this.loading = false
      }
    },

    async verifyOtp(code: string): Promise<void> {
      this.loading = true
      this.error = null
      try {
        const data = (await apiFetch('/api/v1/login/otp', {
          method: 'POST',
          body: { otp_challenge_token: this.otpChallengeToken, code },
        })) as SessionData
        await this._applySession(data)
        this.otpChallengeToken = null
      } catch (e) {
        this.error = e instanceof ApiError ? e.message : 'Unable to reach the API'
        throw e
      } finally {
        this.loading = false
      }
    },

    async _applySession(data: SessionData): Promise<void> {
      this.token = data.token
      this.user = data.user
      setLocale(this.user?.locale)
      localStorage.setItem(TOKEN_KEY, this.token)
      await this.resolveProject()
    },

    async loadMe(projectId: string): Promise<void> {
      const data = (await apiFetch('/api/v1/me', { token: this.token ?? undefined, projectId })) as MeResponse
      this.user = data.user
      this.project = data.project
      this.role = data.role
      this.otpRequired = data.otp_required
      setLocale(this.user?.locale)
    },

    async updateLocale(locale: string): Promise<void> {
      this.user = (await apiFetch(`/api/v1/admin/users/${this.user?.id}`, {
        method: 'PATCH',
        token: this.token ?? undefined,
        projectId: this.project?.id,
        body: { locale },
      })) as User
      setLocale(this.user.locale)
    },

    async fetchProjects(): Promise<Project[]> {
      const data = (await apiFetch('/api/v1/admin/projects', { token: this.token ?? undefined })) as ProjectsResponse
      this.projects = data.projects
      return this.projects
    },

    // After login/signup, or on restore with no cached project: auto-pick if there's
    // exactly one project, otherwise leave unset so the UI prompts for a choice.
    async resolveProject(): Promise<void> {
      const projects = await this.fetchProjects()
      if (projects.length === 1) {
        await this.selectProject(projects[0].id)
      }
    },

    async selectProject(projectId: string): Promise<void> {
      await this.loadMe(projectId)
      localStorage.setItem(PROJECT_KEY, projectId)
      // Custom attributes are project-scoped but cached only by entity — without this,
      // switching projects (with or without a logout in between) leaves the previous
      // project's attributes showing in every key dropdown until something else clears it.
      useCustomAttributes().invalidate()
      useCoupons().invalidate()
    },

    async logout(): Promise<void> {
      try {
        await apiFetch('/api/v1/logout', { method: 'DELETE', token: this.token ?? undefined })
      } catch {
        // best-effort — clear local state regardless of whether this succeeded
      }
      this.clear()
    },

    clear(): void {
      this.token = null
      this.user = null
      this.project = null
      this.role = null
      this.projects = []
      this.error = null
      this.otpChallengeToken = null
      this.otpRequired = false
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(PROJECT_KEY)
      useCustomAttributes().invalidate()
      useCoupons().invalidate()
    },
  },
})
