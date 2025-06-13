# MPB Implementation Guide  
Kick-start turning **mpb-web-v2** into the first workable slice of the streamlined Max Potential Basketball (MPB) system.

---

## 0 · Prerequisites
| Tool | Version | Install Hint |
|------|---------|--------------|
| Node | 18 + | `nvm install 18 && nvm use` |
| pnpm | ≥ 8 | `npm i -g pnpm` |
| Supabase CLI | ≥ 1.154 | `brew install supabase/tap/supabase` |
| Git | any |  |

Create a Supabase project in the dashboard and note:
```
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

---

## 1 · Recommended Repo Layout

```
mpb/
├─ apps/
│  └─ web/            (Next.js 15 – existing mpb-web-v2)
├─ packages/
│  ├─ db/             (generated database types)
│  └─ ui/             (shared Tailwind/React components)
├─ supabase/
│  ├─ migrations/     (SQL – copy from mp-basketball, trimmed)
│  ├─ seed/
│  └─ functions/      (Edge Functions)
├─ .github/workflows/
│  └─ ci.yml
└─ turbo.json         (or pnpm-workspace.yaml)
```

Move the current **mpb-web-v2** code to `apps/web`.

---

## 2 · Bootstrapping the Backend

### 2.1 Migrations

```bash
supabase init --db-url $SUPABASE_URL         # if not done
cp -r path/to/mp-basketball/schemas/mp-basketball/migrations supabase/
supabase db push                             # run migrations
```

Remove exotic or deprecated tables for now:
- Anything under `productivity_tables.sql`
- Legacy `actor` tables (use `person` model only)

### 2.2 Seed Minimal Data

```bash
supabase db remote set $SUPABASE_URL
psql $SUPABASE_URL -f supabase/seed/person_rows.sql
```

Keep seeds small (coach + 5 players) for fast iterations.

---

## 3 · Generate End-to-End Types

```bash
# root package.json
"scripts": {
  "gen:types": "supabase gen types typescript --local > packages/db/index.ts"
}

pnpm run gen:types
```

`packages/db/index.ts` now contains typed helpers for Postgres tables.

---

## 4 · Shared Supabase Utilities

Create `packages/db/supabaseClient.ts`:

```ts
import { createBrowserClient } from '@supabase/ssr';
export const supabaseBrowser = () =>
  createBrowserClient<import('./index').Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
```

Create `packages/db/serverClient.ts` for Edge/server components:

```ts
import { createServerClient } from '@supabase/ssr';
export const supabaseServer = (cookies: () => Record<string,string>) =>
  createServerClient<import('./index').Database>(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    { cookies }
  );
```

---

## 5 · Auth Pages (MVP)

In `apps/web/src/app/(auth)/login/page.tsx`:

```tsx
'use client';
import { supabaseBrowser } from 'db/supabaseClient';
export default function Login() {
  const handleLogin = async (formData: FormData) => {
    const email = formData.get('email') as string;
    const { error } = await supabaseBrowser().auth.signInWithOtp({ email });
    if (!error) alert('Check your inbox!');
  };
  return (
    <form action={handleLogin} className="grid gap-4 max-w-sm mx-auto mt-24">
      <input name="email" placeholder="Email" className="input" />
      <button className="btn-primary">Send Magic Link</button>
    </form>
  );
}
```

Add middleware in `apps/web/src/middleware.ts` to gate `/dashboard*`.

---

## 6 · Attendance Component (Phase-0 Feature)

1. Create Edge Function `supabase/functions/toggleAttendance.ts`:

```ts
import { createClient } from 'https://deno.land/x/supabase/mod.ts';
Deno.serve(async (req) => {
  const { session_uid, person_uid, present } = await req.json();
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  await supabase.from('attendance')
    .upsert({ session_uid, person_uid, status: present ? 'present' : 'absent' });
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
});
```

2. Deploy: `supabase functions deploy toggleAttendance`.

3. Front-end hook (`packages/ui/useAttendance.ts`):

```ts
export const useAttendance = (sessionUid: string) => {
  const supabase = supabaseBrowser();
  const { data, error } = useQuery(['att', sessionUid], () =>
    supabase.from('attendance').select('*').eq('session_uid', sessionUid)
  );
  const toggle = (personUid: string, present: boolean) =>
    fetch('/api/toggle-attendance', {
      method: 'POST', body: JSON.stringify({ session_uid: sessionUid, person_uid: personUid, present })
    });
  return { data: data?.data ?? [], toggle, error };
};
```

4. Create `pages/api/toggle-attendance.ts` proxy → call Edge Function.

---

## 7 · Starter Drill Bank UI

```
apps/web/src/app/drills/page.tsx
packages/ui/DrillCard.tsx
```

Use `drill` table CRUD via Supabase `db` types. Keep fields:
- `title` (varchar)
- `intent` (text)
- `supported_formats` (jsonb array)
- `base_constraints` (jsonb, default `[]`)

Render `DrillCard` grid with Tailwind.

---

## 8 · Plan-Generator Edge Function (Skeleton)

`supabase/functions/generatePlan.ts`:

```ts
import { createClient } from 'https://deno.land/x/supabase/mod.ts';

export const handler = async (req: Request) => {
  const { session_uid } = await req.json();
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // 1. fetch attendance, pdp tags, team arc, recent reflections
  // 2. run simple algo: pick drills that match attendance count
  // 3. return ordered blocks array

  return new Response(JSON.stringify({ blocks: [] }), { status: 200 });
};
```

Deploy, then call from `/dashboard/session/[uid]/plan` page.

---

## 9 · Review / Finalize Workflow

- Add column `status enum('draft','active','completed')` to `session`.
- UI `<FinalizeButton>` sets status to `active`; Postgres RLS forbids further edits unless coach role.

---

## 10 · CI / Code Quality

`.github/workflows/ci.yml` (excerpt):

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: 8 }
      - run: pnpm i --frozen-lockfile
      - run: pnpm run gen:types
      - run: pnpm turbo build
```

---

## 11 · Immediate Next Steps Checklist

| # | Action | Time |
|---|--------|------|
| 1 | Convert repo to monorepo (`apps/`, `packages/`, `supabase/`) | 30 min |
| 2 | Copy trimmed migrations → run `supabase db push` | 15 min |
| 3 | Add `.env.local` in `apps/web` with URL & anon key | 5 min |
| 4 | Run `pnpm run gen:types` & commit `packages/db/index.ts` | 3 min |
| 5 | Implement Auth magic-link page + middleware | 1 hr |
| 6 | Deploy `toggleAttendance` Edge Function & hook UI | 1 hr |
| 7 | CRUD Drill Bank (title + intent) | 2 hr |
| 8 | Skeleton `generatePlan` Edge Function returning `{blocks:[]}` | 30 min |
| 9 | Commit & push – GitHub CI should pass | 10 min |

You now have the nucleus of the streamlined, efficient MPB system: typed backend, real-time attendance, modular drill bank, and the foundation for ARC-driven practice generation. Expand iteratively by enriching blocks, overlay engines, and analytics as outlined in the Architecture doc.
