# x-discounts

A multi-tenant discounts, coupons, and loyalty-points platform: an admin API for managing campaigns, discounts, coupon codes, membership tiers, and a gift shop, plus a public API for validating and redeeming discounts against a cart.

## Overview

x-discounts lets a business define campaigns containing discounts (promotions, coupon codes, or loyalty-point rules), manage customers and their membership tiers/loyalty-point balances, and run a points-redeemable gift shop — all scoped per **project** within an **account**. A public API (signup/login, discount validation, discount redemption) is consumed by the business's own storefront; an admin API and dashboard manage everything behind it.

This is a monorepo containing two independently deployable apps: **`frontend/`** (Vue 3 admin dashboard) and **`backend/`** (Rails API).

## Architecture

```
Browser
  │
  ▼
frontend/  — Vue 3 SPA (Vite dev server, :5175)
  │  REST/JSON over VITE_API_BASE_URL
  ▼
backend/   — Rails API-only app (Puma, :3001 → container :3000)
  │
  ├─▶ PostgreSQL (:5432)  — primary datastore (via Sequel)
  └─▶ Redis               — Sidekiq job queue
        ▲
        └── sidekiq worker process (background jobs)
```

The frontend is a pure API client — it never talks to Postgres/Redis directly, only to the Rails API. In local dev (`docker compose up`) all five pieces (`db`, `redis`, `app`, `sidekiq`, `frontend`) run as separate Compose services on one shared Docker network.

## Tech stack

### Frontend

| Purpose | Library |
|---|---|
| Framework | Vue 3 (`^3.5`), `<script setup>` |
| Build tool | Vite 8 |
| Routing | Vue Router 5 |
| State management | Pinia |
| UI components | OpenVue (PrimeVue-v4-tracking primitives) + Tailwind CSS v4 |
| Icons | PrimeIcons |
| i18n | vue-i18n |
| Validation / schemas | Zod |
| Testing | Vitest |
| Linting / formatting | ESLint, oxlint, Prettier |

### Backend

| Purpose | Gem |
|---|---|
| Framework | Rails `~> 7.1.6` (API-only, Ruby 3.3.12) |
| App server | Puma |
| ORM | Sequel (`sequel-rails`), PostgreSQL (`pg`) |
| Pagination | Pagy |
| Request validation | `json_model_rb` |
| Response serialization | Alba |
| API documentation | `openapi-ruby` (generated from RSpec request specs) |
| Background jobs | Sidekiq + Redis |
| CORS | `rack-cors` |
| Password hashing | bcrypt |
| Bulk export | rubyzip (CSV → zip) |
| Testing | RSpec (`rspec-rails`) + `factory_bot_rails` |

## Prerequisites

- **Docker** and **Docker Compose** — required. The backend (Ruby, Postgres, Redis) runs entirely in Docker; **do not install Ruby or Rails on the host.**
- **Node.js** `^22.18.0` or `>=24.12.0` and npm — only needed if you want to run the frontend directly on the host instead of through Docker.

## Installation

### Backend setup

```bash
# from the repo root
cp docker-compose.example.yml docker-compose.yml   # docker-compose.yml is gitignored; this is your local copy
docker compose build app
docker compose run --rm app bin/rails db:create db:migrate
```

### Frontend setup

```bash
cd frontend
npm install
```

(Skip this if you'd rather let the `frontend` Compose service build its own `node_modules` — see below.)

## Running locally

Start everything (Postgres, Redis, Rails API, Sidekiq worker, and the Vite dev server) with one command from the repo root:

```bash
docker compose up
```

| App | URL |
|---|---|
| Frontend | http://localhost:5175 |
| Backend API | http://localhost:3001 |
| API docs (Swagger UI) | http://localhost:3001/api-docs |

There are no `.env` files in this project — every environment variable (`DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `REDIS_URL`, `CORS_ORIGINS`, `VITE_API_BASE_URL`) is set directly in `docker-compose.yml` per service. Edit your local `docker-compose.yml` (copied from the example) to change any of them.

To run the frontend on the host instead of in its container: `cd frontend && npm run dev` (still points at `http://localhost:3001` by default via `VITE_API_BASE_URL`).

## Available scripts

### Frontend (`frontend/package.json`)

| Command | What it does |
|---|---|
| `npm run dev` | Start the Vite dev server on :5175 |
| `npm run build` | Production build to `frontend/dist` |
| `npm run preview` | Preview the production build locally |
| `npm run test` | Run the Vitest suite once |
| `npm run test:watch` | Run Vitest in watch mode |
| `npm run lint` | Run oxlint then ESLint, both with `--fix` |
| `npm run format` | Format `src/` with Prettier |

### Backend (`backend/bin/`, Rails)

Run these inside the container, e.g. `docker compose exec app <command>` (or `docker compose run --rm app <command>` if `app` isn't already running):

| Command | What it does |
|---|---|
| `bin/rails server -b 0.0.0.0` | Start the Rails API server (this is the `app` service's default command) |
| `bin/rails console` | Open a Rails console |
| `bin/rails db:create` | Create the dev/test databases |
| `bin/rails db:migrate` | Run pending Sequel migrations |
| `bin/rails db:seed` | Load `db/seeds.rb` |
| `bundle exec rspec` | Run the RSpec suite (also regenerates `openapi/public_api.yaml`) |
| `bundle exec sidekiq` | Start the background job worker (this is the `sidekiq` service's default command) |
| `bin/setup` | Idempotent local setup: installs gems, clears logs/tmp, restarts the server |

## Project structure

```
.
├── backend/                    Rails 7 API-only app (Sequel ORM)
├── frontend/                   Vue 3 SPA
├── docker-compose.example.yml  Committed template — copy to docker-compose.yml
└── docker-compose.yml          Gitignored local copy (db, redis, app, sidekiq, frontend services)
```

**`backend/`** (non-obvious folders only):
- `app/api_components/` — shared OpenAPI parameter/schema/security-scheme definitions used by `openapi-ruby`
- `app/request_models/` — `json_model_rb` classes that deserialize/validate incoming JSON
- `app/serializers/` — Alba response serializers
- `db/migrate/` — Sequel-style migrations (`Sequel.migration do ... end`, not ActiveRecord)
- `openapi/public_api.yaml` — generated OpenAPI document, served at `/api-docs`
- `spec/requests/` — request specs; these double as the source for the generated API docs

**`frontend/`** (non-obvious folders only):
- `src/components/base/` — thin wrappers around each OpenVue primitive used in the app
- `src/api/` — HTTP calls to the backend, one file per resource
- `src/models/` — Zod schemas for API request/response shapes
- `src/composables/` — shared reactive logic (`useAsync`, `useBaseToast`, etc.)
- `src/i18n/locales/<en|ja>/` — one JSON file per view/component namespace, auto-loaded

## API documentation

The backend generates OpenAPI docs from its RSpec request specs (`openapi-ruby`). With the backend running:

- Rendered docs: http://localhost:3001/api-docs
- Raw spec file: `backend/openapi/public_api.yaml`

## Testing

### Frontend

```bash
cd frontend
npm run test          # single run
npm run test:watch    # watch mode
```

Or via Docker: `docker compose exec frontend npm test`.

### Backend

```bash
docker compose exec app bundle exec rspec
```

(Use `docker compose run --rm app bundle exec rspec` if the `app` service isn't already up.)

## License

[MIT](LICENSE)
