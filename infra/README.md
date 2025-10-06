# infra

This directory is the root for the Supabase local project. **Always run Supabase CLI commands from here** so that configuration, migrations, and containers resolve correctly.

## Key locations
- `supabase/functions/` - all Edge Functions live here; scaffold new ones with `supabase functions new <name>`.
- `lib/` - shared TypeScript modules that can be imported by functions, scripts, and other infra tooling.

## Common commands
- start: `supabase start`
- stop: `supabase stop`
- status: `supabase status`
- reset local test DB: `supabase db reset --local --yes`
- generate migrations: `supabase db diff -f <name>`

Use helpers from `lib/` inside functions under `supabase/functions/` to keep logic modular.