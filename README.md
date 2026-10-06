# Campus Equipment Booking API

TypeScript + Hono on Cloudflare Workers runtime, with local D1 (SQLite) via `wrangler`.

**Base API URL used for testing:** `http://localhost:8787/api`

## Run

```bash
npm install
npm run db:init     # create tables + seed equipment in local D1 (safe to re-run)
npm run dev         # starts http://localhost:8787
```

Quick check:

```bash
curl -s http://localhost:8787/api/equipment
```

Contract: see [API_CONTRACT.md](API_CONTRACT.md).

## Schema / ERD

```mermaid
erDiagram
    EQUIPMENT ||--o{ BOOKINGS : "is booked in"
    EQUIPMENT {
        TEXT id PK "eq-1"
        TEXT name
        TEXT location
    }
    BOOKINGS {
        TEXT id PK "bk-uuid"
        TEXT equipment_id FK
        TEXT borrower_name
        TEXT start_at "ISO UTC"
        TEXT end_at "ISO UTC, CHECK start_at < end_at"
        TEXT purpose
        TEXT created_at
        TEXT updated_at
    }
```

One equipment has many bookings (1:N). Full DDL: [schema.sql](schema.sql).

## How the overlap check works

Two time ranges `[A.start, A.end)` and `[B.start, B.end)` overlap exactly when `A.start < B.end AND B.start < A.end`.

| Existing 09:00–11:00 vs new | Overlap? | Result |
|---|---|---|
| 10:00–12:00 (partial) | yes | 409 |
| 08:00–12:00 (covers) | yes | 409 |
| 09:30–10:30 (inside) | yes | 409 |
| 11:00–12:00 (touching) | no (`11:00 < 11:00` is false) | 201 |
| other equipment, same time | not compared | 201 |

- **Create:** compare against all bookings of the same `equipmentId`.
- **Update (PATCH):** merge the patch onto the stored booking, then run the same check but exclude the booking itself (`id != ?`), otherwise a booking would always conflict with its own old time.
- The check runs twice: first a `SELECT` to return a clear 409 message, then again inside the `INSERT … WHERE NOT EXISTS` / `UPDATE … AND NOT EXISTS` statement, so check-and-write is one atomic SQL statement and two concurrent requests cannot both succeed.

## Known limitations

- No authentication: anyone can edit or delete any booking.
- No pagination on `GET /bookings`.
- Equipment cannot be created/edited through the API (seed data only).

## Assumptions

1. No starter repository was provided, so the project was created from scratch with the course stack (Hono + local D1).
2. Times must be ISO 8601 with a timezone; they are normalized to UTC (`toISOString`) before storing, so string comparison in SQL is a correct time comparison.
3. Intervals are half-open `[startAt, endAt)`: a booking ending at 11:00 does not conflict with one starting at 11:00.
4. All five booking fields are required on create; `purpose` must be non-empty.
5. A nonexistent `equipmentId` in the request body returns **400** (invalid data), while a nonexistent booking id in the URL returns **404**.
6. Equipment is read-only seed data (3 items); only bookings have full CRUD.
7. No authentication and no CORS (testing uses curl, not a browser).
