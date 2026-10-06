# API Contract — Campus Equipment Booking API

`BASE_URL = http://localhost:8787/api` — all requests/responses are JSON.

## Equipment

| Method | Path | Success | Errors |
|---|---|---:|---|
| GET | `/equipment` | 200 — array of `{ id, name, location }` | — |

## Bookings

| Method | Path | Success | Errors |
|---|---|---:|---|
| GET | `/bookings` (optional `?equipmentId=eq-1`) | 200 — array of bookings | — |
| GET | `/bookings/:id` | 200 — booking | 404 |
| POST | `/bookings` | 201 — created booking | 400, 409 |
| PATCH | `/bookings/:id` | 200 — updated booking | 400, 404, 409 |
| DELETE | `/bookings/:id` | 204 — no body | 404 |

### Request body (POST: all fields required; PATCH: any subset, at least one)

```json
{
  "equipmentId": "eq-1",
  "borrowerName": "Somchai Jaidee",
  "startAt": "2026-10-20T09:00:00.000Z",
  "endAt": "2026-10-20T11:00:00.000Z",
  "purpose": "Class presentation"
}
```

### Booking response

```json
{
  "id": "bk-0b6c…",
  "equipmentId": "eq-1",
  "borrowerName": "Somchai Jaidee",
  "startAt": "2026-10-20T09:00:00.000Z",
  "endAt": "2026-10-20T11:00:00.000Z",
  "purpose": "Class presentation",
  "createdAt": "…",
  "updatedAt": "…"
}
```

## Validation rules

- `equipmentId`, `borrowerName` (≤100), `purpose` (≤200): non-empty strings (trimmed).
- `startAt`, `endAt`: ISO 8601 date-time **with timezone**; stored normalized to UTC.
- `startAt` must be before `endAt`.
- `equipmentId` must exist in `equipment`.
- No overlap with another booking of the same equipment: overlap when `existing.startAt < new.endAt AND new.startAt < existing.endAt`. Back-to-back (one ends 11:00, next starts 11:00) is allowed. Checked on **POST and PATCH** (PATCH excludes the booking itself).
- Unknown fields and malformed JSON are rejected.

## Errors — always `{ "error": "message" }`

| Status | When | Why this code |
|---:|---|---|
| 400 | Missing/invalid field, bad JSON, bad date, `startAt >= endAt`, unknown `equipmentId` in body | The client sent invalid data; fixing the request fixes it. Unknown `equipmentId` is invalid *data* in the body — the URL `/bookings` itself exists, so it is not 404. |
| 404 | `/bookings/:id` does not exist, or unknown route | The resource identified by the URL is not found. |
| 409 | Time range overlaps an existing booking of the same equipment | Request is valid but conflicts with the current state of the server. |
| 500 | Unexpected server error | Details are logged on the server, never returned. |
