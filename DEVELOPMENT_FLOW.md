# Development Workflow Guide

This document describes the standard development workflow for this project.
It combines Git branching strategy, Test-Driven Development (TDD), Supabase integration, and CI/CD best practices.

---

## 1. Branching Strategy

- **Main branches**
  - `main`: Production-ready code only. Releases are tagged from here.
  - `develop`: Integration branch for new features, staging before merging into `main`.

- **Feature branches**
  - Branch from `develop` when starting new work.
  - Naming convention: `feature/<feat-name>`.

- **Merging**
  - Open Pull Request from `feature/*` → `develop`.
  - Merge into `main` only during release.

- **Cleanup**
  - After merging, delete feature branches locally and remotely.

---

## 2. Local Development Workflow (TDD)

### 1. Start from a feature branch
```bash
git fetch origin
git checkout -b feature/<feat-name> origin/develop
```

### 2. Write tests first (TDD principle)
- Place **unit tests** in: `tests/unit/`
- Place **integration tests** in: `tests/integration/`
- Naming convention: `<name>.test.ts`

### 3. Run unit tests
```bash
deno task test:unit
```

### 4. If database schema changes are needed
1. Start Supabase local environment:
   ```bash
   cd infra
   supabase start
   ```
2. Apply/reset DB for test environment:
   ```bash
   supabase db reset --force --env-file .env.test
   ```
3. Run integration tests:
   ```bash
   cd ..
   deno task test:integration
   ```

### 5. Generate migration when schema changes
```bash
cd infra
supabase db diff -f <name>
cd ..
```

### 6. Repeat TDD cycle until tests pass
- Write/adjust code under `infra/supabase/functions/` or `infra/lib/`
- Run `deno task test:unit` and `deno task test:integration` until green

---

## 3. Commit & Push

### 1. Before committing
- Verify `deno task test:unit` and `deno task test:integration` both pass.
- Ensure schema migrations are generated and applied.

### 2. Commit changes
```bash
git add .
git commit -m "feat: <describe feature or change>"
```

### 3. Push feature branch
```bash
git push -u origin feature/<feat-name>
```

---

## 4. Pull Request & Review

- Open PR from `feature/<feat-name>` → `develop`
- Ensure CI/CD pipeline (tests, migrations) passes before merging
- Request code review from at least one teammate

---

## 5. CI/CD Integration

- GitHub Actions (`.github/workflows/test.yml`) runs tests automatically on PRs
- Local Supabase (`infra/`) setup ensures consistent test environments
- `develop` branch is always stable and ready for staging deployment

---

## 6. Release Workflow

1. Merge `develop` → `main` for production release
2. Tag release version
```bash
git checkout main
git merge develop
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin main --tags
```
3. Deploy production build
