# ScopeStrength

Open source software for personal trainers and their clients. Trainers manage clients,
build programmes and track progress; clients log their own workouts, weight and photos,
and message their trainer. Everything runs in one Phoenix application backed by
PostgreSQL.

Hosted version: [scopestrength.com](https://scopestrength.com). You can also host it
yourself — the whole application is in this repository under the AGPL, with no paid
tier, no feature flags and no phone-home.

---

## Why self-host

- **Your data stays yours.** Client names, weights, notes and photos live in your own
  database and your own file storage.
- **Nothing is held back.** The hosted version and this repository are the same code.
- **Swap the parts you care about.** Email and file storage are chosen with environment
  variables, so you can point them at your own SMTP server and your own object storage,
  or run entirely on local disk.
- **Read the whole thing.** It is one Phoenix app, not a service mesh. The progression
  rules, the volume maths and the access checks are each a single readable module.

---

## Features

### For trainers

- **Clients** — add clients, record age, height, sex and free-text notes, and keep
  dated session notes per client.
- **Programmes** — build programmes made of templates (training days), each holding
  exercises with sets, reps or a rep range, and RIR. Duplicate a programme in one click.
- **Assignment** — assign a programme to a client. A client has exactly one active
  programme at a time, enforced in the database, and both assignment and removal
  notify the client.
- **Progression** — pick a progression method per programme and a rep range per
  exercise. The app then judges every logged set and shows whether the client should
  progress, hold or reduce. See [Progression](#progression) below.
- **Client progress** — per-exercise strength history, personal records, session by
  session comparisons, body weight charts and progress photos.
- **Volume tracking** — weekly or monthly set counts per muscle group, split into
  direct and effective volume using per-exercise muscle contributions you can tune.
- **Exercise library** — 97 seeded exercises across 20 muscle groups and 6 equipment
  types, with 188 muscle contribution rows. Add your own custom exercises, mark them
  unilateral, and edit how much each one contributes to each muscle.
- **Invites** — invite a client by email; they get a code that links their new account
  to you at registration.
- **Chat** — real-time messaging with each client, with file and image attachments.
- **Reports** — export a client's weight history and full workout log as a spreadsheet.

### For clients

- **Workout logging** — create a workout, add exercises, and log weight, reps, RIR and
  RPE per set. Load a day straight from the assigned programme, or from a programme
  they built themselves.
- **Unilateral exercises** — log left and right separately; each side is counted and
  progressed on its own.
- **Their own programmes** — copy the assigned programme and adapt it, or build one
  from scratch.
- **Progress** — strength progress per exercise, volume tracking by muscle, body
  weight log and progress photos.
- **Chat and notifications** — message the trainer, and get notified when a programme
  is assigned or changed.

### Throughout

- **Real time.** Built on Phoenix LiveView. Chat, notifications and the unread badge
  update over a websocket with no page reloads.
- **Installable.** A web manifest, icons, service worker and offline page mean it can
  be installed to a phone home screen and survives a flaky connection.
- **Accounts.** Registration, login, email confirmation, password reset and email
  change, with trainer and client roles gating every route.

---

## Progression

Progression is the part most worth reading before you use the app, because it decides
what the client sees after every set.

A programme carries a **progression method**. Each exercise in a template carries a
**rep range** (minimum and maximum). When a client is assigned a programme, the app
creates one progression row per set of per exercise — and for unilateral exercises,
one per side of each set.

Currently one method is implemented, **dynamic double progression**:

| Reps logged | Status | Meaning |
|---|---|---|
| at or above the maximum | `progress` | the range is beaten; add load next session |
| between the minimum and maximum | `hold` | stay at this load and add reps |
| below the minimum | `reduce` | the load is too heavy; cut it |

Each set is judged independently and the client decides what to load next session, so
the app records a judgement rather than prescribing a weight. Sets logged beyond what
the programme prescribes inherit the prescription of the sets that do exist, and an
exercise logged ad hoc with no prescription at all falls back to a 5–10 range.

Changing a rep range re-judges each row against that side's most recent set, so a
tightened range takes effect immediately rather than leaving stale badges behind.

The rules live in `Scopestrength.Progression`, which is a pure module with no database
access, and the state handling in `Scopestrength.ClientProgressions`. Adding a method
means adding a clause to the first and an entry to its list.

---

## Running it

### Requirements

- Elixir 1.14 or newer (developed on 1.18) with a matching Erlang/OTP
- PostgreSQL 14 or newer
- Node is **not** required; assets are built with esbuild and tailwind via Mix

### Development

```bash
git clone <your fork or this repository>
cd scopestrength
mix setup          # fetches deps, creates and migrates the database, seeds exercises, builds assets
mix phx.server
```

Open http://localhost:4000. Nothing needs configuring to run locally: uploads go to
local disk and email goes to an in-app mailbox at http://localhost:4000/dev/mailbox.

The fastest way to see the app with data in it is the **Try the demo** button on the
login page, which creates a trainer, three clients, two programmes and logged workouts.

### Tests

```bash
mix test
```

### Production

Set these, then run the release:

| Variable | Required | Notes |
|---|---|---|
| `DATABASE_URL` | yes | `ecto://user:pass@host/database` |
| `SECRET_KEY_BASE` | yes | generate with `mix phx.gen.secret` |
| `PHX_HOST` | yes | the public hostname, e.g. `app.example.com` |
| `PORT` | no | the port to listen on |
| `POOL_SIZE` | no | database connections, defaults to 2 |

Then choose an email adapter and, optionally, object storage. Both are described in
[`.env.example`](.env.example) and configured in [`config/runtime.exs`](config/runtime.exs).

---

## Email

Password resets and account confirmations need a way to send mail. Set `MAILER_ADAPTER`
to one of:

| Adapter | Variables |
|---|---|
| `smtp` | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` |
| `resend` | `MAILER_API_KEY` |
| `sendgrid` | `MAILER_API_KEY` |
| `postmark` | `MAILER_API_KEY` |
| `mailgun` | `MAILER_API_KEY`, `MAILGUN_DOMAIN` |

Set `MAIL_FROM` to the sender address, for example
`MAIL_FROM="ScopeStrength <no-reply@example.com>"`.

Any SMTP server works, so you never need an account with a particular provider. Leave
`MAILER_ADAPTER` unset in development and mail is kept in memory for you to read at
`/dev/mailbox`. Leave it unset in production and the app still runs, but password reset
emails are dropped and a warning is logged at boot.

---

## File storage

Progress photos, chat attachments and profile pictures are stored through a swappable
adapter. What goes in the database is a key, never a URL, so switching adapters does not
rewrite existing rows.

- **Local disk (default).** Files land in `priv/static/uploads`. Nothing to configure.
  If you run in a container, mount that directory as a volume or uploads are lost on
  restart.
- **Object storage.** Set `S3_BUCKET` with `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY`
  to use AWS S3, Cloudflare R2, Backblaze B2, MinIO or DigitalOcean Spaces. Non-AWS
  providers also need `S3_HOST`. Keep the bucket private; files are served through
  presigned URLs that expire, and large uploads go straight from the browser to the
  bucket rather than through the server.

Adding another backend means implementing three functions of the
`Scopestrength.Storage` behaviour.

---

## Finding your way around the code

```
lib/scopestrength/            contexts — the business logic, no web concerns
  account.ex                  registration, login, tokens, password reset
  clients.ex  trainers.ex     the two roles
  programmes.ex               programmes, templates, exercises, assignment, cloning
  training.ex                 workouts and logged sets
  progression.ex              the progression rules, pure functions
  client_progressions.ex      progression state per client, exercise, set and side
  exercises.ex  exercise.ex   exercise library and muscle contributions
  chat.ex                     messages and attachments
  notifications.ex            the notification records
  storage.ex  storage/        the file storage behaviour and its adapters
  reports/client_report.ex    spreadsheet export

lib/scopestrength_web/
  router.ex                   every route, grouped by role
  live/                       trainer pages
  live/client/                client pages
  components/                 shared UI components
  user_auth.ex                session handling and route guards

priv/repo/migrations/         schema history
priv/repo/seeds.exs           muscles, equipment, exercises, contributions
test/                         context and LiveView tests
```

Two conventions worth knowing. Contexts never touch the connection or socket, so they
are testable on their own. Access checks live at the top of each LiveView's `mount`,
and anything addressed by an id from the URL is looked up scoped to the current user.

---

## Contributing

Issues and pull requests are welcome. Please run `mix test` before opening a pull
request, and add a test alongside any bug fix.

The codebase carries the AGPL header on each file and, by convention, no other comments
— explanation belongs in `@doc` and `@moduledoc` strings.

---

## Licence

ScopeStrength is free software licensed under the
[GNU Affero General Public License v3.0 or later](LICENSE).

You may run, study, modify and share it. The AGPL's network clause means that if you
run a modified version as a service for other people, you must offer those users the
source of your modified version.
