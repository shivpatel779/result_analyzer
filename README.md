# Result Analyzer

A Ruby on Rails application that ingests student test results from a third-party
service (MSM) and runs scheduled **End-of-Day (EOD)** and **monthly** calculations.

- Ingests results via a JSON API and persists them.
- Every day at **18:00** aggregates per-subject **daily statistics** (low / high / count).
- On the **Monday of the week containing the third Wednesday** of each month, computes
  per-subject **monthly averages** over a lookback window that grows until it covers at
  least **200** results.

Business logic lives in **service objects**; controllers and jobs are thin. The project
was built **test-first** with RSpec, and tests are the priority deliverable.

---

## Tech stack

- **Ruby** 3.3+, **Rails** 8.1.3
- **PostgreSQL**
- **Tailwind CSS** (`tailwindcss-rails`, standalone binary — no Node/yarn required)
- **Solid Queue** (Rails 8 default) with recurring tasks for scheduling
- **RSpec** + **FactoryBot** + **Faker**

---

## Setup

```bash
# 1. Install dependencies
bundle install

# 2. Configure database access (see "Database configuration" below).
#    dotenv-rails is included, so the easiest option is a gitignored env file:
cat > .env.development.local <<'ENV'
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost
ENV
cp .env.development.local .env.test.local   # the test database uses the same credentials

# 3. Create and migrate
bin/rails db:create db:migrate

# 4. (Optional) load demo data
bin/rails db:seed

# 5. Run the test suite
bundle exec rspec

# 6. Start the app (Rails + Tailwind watcher)
bin/dev
```

The app serves the dashboard at <http://localhost:3000>.

### Database configuration

`config/database.yml` reads connection details from the environment so no credentials
are committed. Provide them via real environment variables or a gitignored
`.env.development.local` / `.env.test.local` file (loaded by `dotenv-rails`):

| Variable            | Default     |
|---------------------|-------------|
| `DATABASE_HOST`     | `localhost` |
| `DATABASE_PORT`     | `5432`      |
| `DATABASE_USERNAME` | `postgres`  |
| `DATABASE_PASSWORD` | (none)      |

All `.env*` files are gitignored.

---

## API

### `POST /api/test_results`

Ingestion endpoint for MSM. Accepts a JSON body:

```json
{
  "student_name": "Ada Lovelace",
  "subject": "Math",
  "marks": 87,
  "timestamp": "2026-06-22T14:30:00Z"
}
```

- **201 Created** with the persisted record on success.
- **422 Unprocessable Content** with an `errors` object when validation fails
  (missing fields, out-of-range marks, malformed timestamp).

```bash
curl -i -X POST http://localhost:3000/api/test_results \
  -H 'Content-Type: application/json' \
  -d '{"student_name":"Ada","subject":"Math","marks":87,"timestamp":"2026-06-22T14:30:00Z"}'
```

---

## Domain model

| Model                  | Purpose                                                              |
|------------------------|----------------------------------------------------------------------|
| `TestResult`           | Raw MSM submission (`student_name`, `subject`, `marks`, `recorded_at`). |
| `DailyResultStatistic` | One row per `[date, subject]`: `daily_low`, `daily_high`, `result_count`. |
| `MonthlyResultAverage` | One row per `[subject, period]`: `avg_daily_high`, `avg_daily_low`, `result_count`, `days_used`. |

### Service objects (`app/services/`)

- `Ingestion::CreateTestResult` — validates and stores an MSM payload.
- `Eod::CalculateDailyStatistics` — builds the daily statistics per subject.
- `Monthly::TriggerDate` — resolves the trigger Monday and answers `run_today?`.
- `Monthly::CalculateAverages` — runs the 200-threshold lookback and averaging.

### Jobs & scheduling

Both jobs are thin and delegate to services. Registered in `config/recurring.yml`:

- `EodStatisticsJob` — **every day at 18:00**.
- `MonthlyAveragesJob` — **every day at 18:05**; the trigger-date guard inside the job
  ensures work only happens on the trigger Monday.

Run Solid Queue (which executes recurring tasks) with `bin/jobs`. Jobs can also be run
manually:

```ruby
EodStatisticsJob.perform_now                       # today
MonthlyAveragesJob.perform_now(date: Date.new(2026, 6, 15))
```

---

## The monthly calculation in detail

Runs **per subject**. Starting from the most recent `DailyResultStatistic` on or before
the run date, it takes the most recent **5 days**; if their cumulative `result_count` is
below **200**, it keeps extending further back one day at a time until the cumulative
count reaches 200 (or history is exhausted). It then stores the mean `daily_high`, the
mean `daily_low`, the total `result_count`, and the number of `days_used`.

---

## Assumptions

- **Marks** are stored as an integer percentage score in the range **0–100 inclusive**.
  Values outside this range, non-integer values, and non-numeric values are rejected at
  ingestion.
- **Timezone.** The application time zone is **UTC** (`config.time_zone`). All
  day-boundary logic — which results belong to a given day, the 18:00 EOD trigger, and
  the third-Wednesday/Monday math — is anchored to this zone via `Time.zone` and
  `Date.current`. Incoming `timestamp` values are parsed in this zone.
- **No results for a day.** The EOD service writes **no** `DailyResultStatistic` rows for
  a subject/day with no results (rather than zero-valued rows).
- **Monthly scope is per subject.** Each subject's 200-threshold window is computed
  independently, producing one `MonthlyResultAverage` row per subject.
- **Lookback may cross month boundaries — yes.** If a subject has fewer than 200 results
  in the current month's recent days, the window extends back into previous months until
  the threshold is met.
- **Insufficient history.** If all available statistics for a subject still total fewer
  than 200, every available day is used and the actual (sub-threshold) `result_count`
  and `days_used` are recorded.
- **Minimum window.** The window always starts at the most recent 5 days; if those
  already total ≥ 200, exactly those 5 days are used.
- **Averages** are simple (unweighted) means of the daily highs/lows over the window,
  rounded to two decimal places.
- **Ingestion is unauthenticated.** The MSM endpoint performs validation only; add
  authentication (e.g. a shared secret) before exposing it publicly.
- **Idempotency.** Both the EOD and monthly services upsert on their unique keys, so
  re-running for the same day/period updates existing rows instead of duplicating.

---

## Testing

```bash
bundle exec rspec
```

Coverage spans models, the ingestion request + service, the EOD service and job, the
trigger-date resolver (table-driven across all 12 months of 2026), the monthly averaging
service (200-threshold boundaries: exactly 200, just under, well over; cross-month
lookback; insufficient history; per-subject isolation; rounding) and the monthly job
guard. Boundary-sensitive specs use explicit values for determinism.
