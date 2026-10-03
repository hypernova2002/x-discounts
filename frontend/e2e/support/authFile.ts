import { fileURLToPath } from 'node:url'

// Shared by playwright.config.ts (storageState option) and auth.setup.ts
// (where it's written) — kept out of auth.setup.ts itself so the config file
// doesn't have to import a Playwright test file to get the path.
export const authFile = fileURLToPath(new URL('../.auth/user.json', import.meta.url))
