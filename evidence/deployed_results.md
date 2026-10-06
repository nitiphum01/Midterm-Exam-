# curl test evidence

- Base URL: `https://equipment-booking-api.nitiphumhon.workers.dev/api`
- Run at: 2026-10-06T07:26:53Z

## G1 — List equipment

Expected `200`, got `200` → **PASS**

```bash
curl -i 'https://equipment-booking-api.nitiphumhon.workers.dev/api/equipment'
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 178

[{"id":"eq-1","name":"Projector A","location":"Building 1"},{"id":"eq-2","name":"Camera B","location":"Building 2"},{"id":"eq-3","name":"Meeting Room C","location":"Building 3"}]

```

## G2 — List bookings

Expected `200`, got `200` → **PASS**

```bash
curl -i 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings'
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 2

[]

```

## G3 — Create a booking

Expected `201`, got `201` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation"}'
```

```http
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 282

{"id":"bk-a07144dc-6241-4e7f-886f-19056a4a251e","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation","createdAt":"2026-10-06T07:26:56.831Z","updatedAt":"2026-10-06T07:26:56.831Z"}

```

## G4 — Get one booking

Expected `200`, got `200` → **PASS**

```bash
curl -i 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-a07144dc-6241-4e7f-886f-19056a4a251e'
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 282

{"id":"bk-a07144dc-6241-4e7f-886f-19056a4a251e","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation","createdAt":"2026-10-06T07:26:56.831Z","updatedAt":"2026-10-06T07:26:56.831Z"}

```

## G5 — Update a booking (PATCH)

Expected `200`, got `200` → **PASS**

```bash
curl -i '-X' 'PATCH' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-a07144dc-6241-4e7f-886f-19056a4a251e' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T12:00:00.000Z","endAt":"2026-10-20T14:00:00.000Z","purpose":"Updated class presentation"}'
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 290

{"id":"bk-a07144dc-6241-4e7f-886f-19056a4a251e","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T12:00:00.000Z","endAt":"2026-10-20T14:00:00.000Z","purpose":"Updated class presentation","createdAt":"2026-10-06T07:26:56.831Z","updatedAt":"2026-10-06T07:26:59.195Z"}

```

## G6 — Invalid time range (start after end)

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-21T11:00:00.000Z","endAt":"2026-10-21T09:00:00.000Z","purpose":"Invalid time range test"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
Content-Length: 40

{"error":"startAt must be before endAt"}

```

## G7 — Overlapping booking (POST)

Expected `409`, got `409` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T12:30:00.000Z","endAt":"2026-10-20T13:30:00.000Z","purpose":"Conflict test"}'
```

```http
HTTP/1.1 409 Conflict
Content-Type: application/json
Content-Length: 115

{"error":"Equipment 'eq-1' is already booked in this time range (booking bk-a07144dc-6241-4e7f-886f-19056a4a251e)"}

```

## G8 — Missing booking

Expected `404`, got `404` → **PASS**

```bash
curl -i 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/not-found'
```

```http
HTTP/1.1 404 Not Found
Content-Type: application/json
Content-Length: 29

{"error":"Booking not found"}

```

## E1 — Back-to-back booking allowed (starts when previous ends)

Expected `201`, got `201` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T14:00:00.000Z","endAt":"2026-10-20T15:00:00.000Z","purpose":"Back-to-back test"}'
```

```http
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 275

{"id":"bk-58fd8b81-ab3e-48fb-bdc2-02d5a3a4de4e","equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T14:00:00.000Z","endAt":"2026-10-20T15:00:00.000Z","purpose":"Back-to-back test","createdAt":"2026-10-06T07:27:02.817Z","updatedAt":"2026-10-06T07:27:02.817Z"}

```

## E2 — Overlapping booking (PATCH into another booking's time)

Expected `409`, got `409` → **PASS**

```bash
curl -i '-X' 'PATCH' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-58fd8b81-ab3e-48fb-bdc2-02d5a3a4de4e' '-H' 'Content-Type: application/json' '-d' '{"startAt":"2026-10-20T13:00:00.000Z"}'
```

```http
HTTP/1.1 409 Conflict
Content-Type: application/json
Content-Length: 115

{"error":"Equipment 'eq-1' is already booked in this time range (booking bk-a07144dc-6241-4e7f-886f-19056a4a251e)"}

```

## E3 — Missing required fields

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
Content-Length: 97

{"error":"borrowerName is required; purpose is required; startAt is required; endAt is required"}

```

## E4 — equipmentId does not exist

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-999","borrowerName":"A","startAt":"2026-10-22T09:00:00.000Z","endAt":"2026-10-22T10:00:00.000Z","purpose":"x"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
Content-Length: 47

{"error":"equipmentId 'eq-999' does not exist"}

```

## E5 — Malformed JSON body

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId": "eq-1",'
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
Content-Length: 42

{"error":"Request body is not valid JSON"}

```

## E6 — Impossible calendar date (Feb 30)

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-2","borrowerName":"A","startAt":"2026-02-30T09:00:00.000Z","endAt":"2026-02-30T10:00:00.000Z","purpose":"x"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
Content-Length: 176

{"error":"startAt must be an ISO 8601 date-time with timezone, e.g. 2026-10-20T09:00:00.000Z; endAt must be an ISO 8601 date-time with timezone, e.g. 2026-10-20T09:00:00.000Z"}

```

## E7 — PATCH a booking that does not exist

Expected `404`, got `404` → **PASS**

```bash
curl -i '-X' 'PATCH' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/not-found' '-H' 'Content-Type: application/json' '-d' '{"purpose":"x"}'
```

```http
HTTP/1.1 404 Not Found
Content-Type: application/json
Content-Length: 29

{"error":"Booking not found"}

```

## G9 — Delete a booking

Expected `204`, got `204` → **PASS**

```bash
curl -i '-X' 'DELETE' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-a07144dc-6241-4e7f-886f-19056a4a251e'
```

```http
HTTP/1.1 204 No Content


```

## E8 — Delete the same booking again

Expected `404`, got `404` → **PASS**

```bash
curl -i '-X' 'DELETE' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-a07144dc-6241-4e7f-886f-19056a4a251e'
```

```http
HTTP/1.1 404 Not Found
Content-Type: application/json
Content-Length: 29

{"error":"Booking not found"}

```

## E9 — Clean up: delete back-to-back booking

Expected `204`, got `204` → **PASS**

```bash
curl -i '-X' 'DELETE' 'https://equipment-booking-api.nitiphumhon.workers.dev/api/bookings/bk-58fd8b81-ab3e-48fb-bdc2-02d5a3a4de4e'
```

```http
HTTP/1.1 204 No Content


```

## Summary

| Case | Description | Expected | Actual | Result |
|---|---|---:|---:|---|
| G1 | List equipment | 200 | 200 | PASS |
| G2 | List bookings | 200 | 200 | PASS |
| G3 | Create a booking | 201 | 201 | PASS |
| G4 | Get one booking | 200 | 200 | PASS |
| G5 | Update a booking (PATCH) | 200 | 200 | PASS |
| G6 | Invalid time range (start after end) | 400 | 400 | PASS |
| G7 | Overlapping booking (POST) | 409 | 409 | PASS |
| G8 | Missing booking | 404 | 404 | PASS |
| E1 | Back-to-back booking allowed (starts when previous ends) | 201 | 201 | PASS |
| E2 | Overlapping booking (PATCH into another booking's time) | 409 | 409 | PASS |
| E3 | Missing required fields | 400 | 400 | PASS |
| E4 | equipmentId does not exist | 400 | 400 | PASS |
| E5 | Malformed JSON body | 400 | 400 | PASS |
| E6 | Impossible calendar date (Feb 30) | 400 | 400 | PASS |
| E7 | PATCH a booking that does not exist | 404 | 404 | PASS |
| G9 | Delete a booking | 204 | 204 | PASS |
| E8 | Delete the same booking again | 404 | 404 | PASS |
| E9 | Clean up: delete back-to-back booking | 204 | 204 | PASS |

**18 passed, 0 failed**
