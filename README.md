# clearbox-delivery (monorepo)

## Layout
- `infra/` – Supabase project assets, migrations, CI tooling, and shared libraries.
  - `infra/supabase/functions/` – All Supabase Edge Functions live here.
  - `infra/lib/` – Shared TypeScript modules for functions and infra tooling.
- `frontend/` – Flutter client (scaffolded later).
- `tests/` – Deno unit and integration test suites.

## Development quickstart
```bash
# from repository root
deno task test:unit

cd infra
supabase start
supabase db reset --local --yes
cd ..
deno task test:integration
```

### Sustainable flow (TDD)
- Place new specs under `tests/unit/` or `tests/integration/`.
- Build Edge Functions inside `infra/supabase/functions/` using Supabase CLI helpers.
- Reuse helpers from `infra/lib/` across functions or infra scripts.
- Iterate with `deno task test:unit`, `supabase db reset --local --yes`, and `deno task test:integration`.
- For schema changes generate a migration:
```bash
cd infra
supabase db diff -f <name>
```
- Default branching: work on `feature/<feat-name>` off `develop`, then open a PR back to `develop` (CI runs unit + integration).