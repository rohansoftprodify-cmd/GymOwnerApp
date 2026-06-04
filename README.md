# Gym Owner App (Flutter + Supabase)

Multi-gym owner app for member registration, attendance, subscriptions, product sales, promotions, and reports.

Member-facing mobile app: **[gym_member_app](../gym_member_app)** (separate Flutter project, same Supabase backend).

This repository is separate from [Megylla](https://github.com/your-org/Megylla) (bike maintenance iOS app).

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) stable and [Supabase CLI](https://supabase.com/docs/guides/cli).
2. From this repo root:
   ```bash
   flutter pub get
   cp config.json.example config.json
   # Edit config.json with your project URL and anon key, then:
   flutter run --dart-define-from-file=config.json
   ```
   Or pass defines explicitly:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=<your-project-url> \
     --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
   ```
3. Apply database migrations (Supabase SQL editor or CLI), including:
   - `supabase/migrations/20260602163000_init_gym_saas.sql`
   - `supabase/migrations/20260603180000_member_role_enum.sql` (adds `member` role — run first)
   - `supabase/migrations/20260603180100_member_accounts.sql` (member app login + RLS)
   - `supabase/migrations/20260603180200_fix_rls_recursion.sql` (fixes members list stack overflow)
   - Optional dev data: `supabase/seed.sql` (requires matching `auth.users` IDs)

## Project layout

- `lib/` — Gym **owner** Flutter app (auth, tenant context, dashboard modules)
- `supabase/migrations/` — Postgres schema, RLS, RPC functions, report views
- `supabase/functions/create-gym-member/` — Edge function to provision member auth accounts
- `supabase/functions/reset-gym-member-password/` — Staff resets password for a member with app login
- `supabase/functions/provision-gym-member-login/` — Staff creates app login for an existing member without one
- `supabase/tests/` — Manual tenant-isolation checks

## Member accounts (owner → member app)

1. Apply migration `20260603180000_member_role_enum.sql`, then `20260603180100_member_accounts.sql`.
2. Deploy edge functions:
   ```bash
   supabase functions deploy create-gym-member
   supabase functions deploy reset-gym-member-password
   supabase functions deploy provision-gym-member-login
   ```
3. In the **owner app**: Gym Profile → **Members** → **Add member** (name, email, password, plan), or open a member → **Member app login** to create login or update password.
4. Share the generated credentials with the member.
5. Run the **member app** from the [gym_member_app](../gym_member_app) project with the same Supabase `--dart-define` values.

Members get `gym_roles.role = member` and are linked via `members.user_id`. RLS ensures:
- Owners/staff see all members in their gym only.
- Member app users see only their own profile, subscription, and attendance for that gym.

## E2E smoke path

1. Sign in as a gym owner (user with a row in `gym_roles`).
2. Register a member → mark check-in/check-out → add fee plan and subscription.
3. Publish a product → record a sale → add a promotion → open Reports.

## Staging and production

- Use separate Supabase projects for staging and production.
- Production: migrations only; do not run demo seed.
- Before release: `flutter analyze`, `flutter test`, and `supabase/tests/tenant_rls_checks.sql`.
