import { z } from 'zod'
import type { ComposerTranslation } from 'vue-i18n'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const UserSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    email: z.string(),
    locale: z.string(),
    otp_enabled: z.boolean(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export type User = z.infer<typeof UserSchema>

export const UserListSchema = z.object({ users: z.array(UserSchema) }).passthrough()

export type UserList = z.infer<typeof UserListSchema>

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (users.json).
export function userInputSchema(t: ComposerTranslation) {
  return z.object({
    name: z.string().min(1, t('users.nameRequired')),
    email: z.string().min(1, t('users.emailRequired')),
  })
}

export type UserInput = z.infer<ReturnType<typeof userInputSchema>>

// Self-service password change. Mirrors the backend's User#validate_password
// rule (min 8 chars) so client-side errors feel consistent with server ones.
export function changePasswordInputSchema(t: ComposerTranslation) {
  return z
    .object({
      current_password: z.string().min(1, t('userSettings.currentPasswordRequired')),
      new_password: z.string().min(8, t('userSettings.newPasswordTooShort')),
      new_password_confirmation: z.string().min(1, t('userSettings.confirmPasswordRequired')),
    })
    .refine((data) => data.new_password === data.new_password_confirmation, {
      message: t('userSettings.passwordsDontMatch'),
      path: ['new_password_confirmation'],
    })
}

export type ChangePasswordInput = z.infer<ReturnType<typeof changePasswordInputSchema>>

export function otpCodeInputSchema(t: ComposerTranslation) {
  return z.object({
    code: z.string().min(1, t('otpEnrollment.codeRequired')),
  })
}

export type OtpCodeInput = z.infer<ReturnType<typeof otpCodeInputSchema>>

// Admin setting/resetting another user's password — no current_password, since
// the acting user is an account admin, not the account being changed.
export function adminResetPasswordInputSchema(t: ComposerTranslation) {
  return z
    .object({
      password: z.string().min(8, t('users.newPasswordTooShort')),
      password_confirmation: z.string().min(1, t('users.confirmPasswordRequired')),
    })
    .refine((data) => data.password === data.password_confirmation, {
      message: t('users.passwordsDontMatch'),
      path: ['password_confirmation'],
    })
}

export type AdminResetPasswordInput = z.infer<ReturnType<typeof adminResetPasswordInputSchema>>
