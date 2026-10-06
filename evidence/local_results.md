# curl test evidence

- Base URL: `http://localhost:8787/api`
- Run at: 2026-10-06T07:51:51Z

## G1 — List equipment

Expected `200`, got `200` → **PASS**

```bash
curl -i 'http://localhost:8787/api/equipment'
```

```http
HTTP/1.1 200 OK
Content-Length: 178
Content-Type: application/json

[{"id":"eq-1","name":"Projector A","location":"Building 1"},{"id":"eq-2","name":"Camera B","location":"Building 2"},{"id":"eq-3","name":"Meeting Room C","location":"Building 3"}]

```

## G2 — List bookings

Expected `200`, got `200` → **PASS**

```bash
curl -i 'http://localhost:8787/api/bookings'
```

```http
HTTP/1.1 200 OK
Content-Length: 2
Content-Type: application/json

[]

```

## G3 — Create a booking

Expected `201`, got `201` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation"}'
```

```http
HTTP/1.1 201 Created
Content-Length: 282
Content-Type: application/json

{"id":"bk-4852418b-82de-4d56-a99b-6265678e95a3","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation","createdAt":"2026-10-06T07:51:53.053Z","updatedAt":"2026-10-06T07:51:53.053Z"}

```

## G4 — Get one booking

Expected `200`, got `200` → **PASS**

```bash
curl -i 'http://localhost:8787/api/bookings/bk-4852418b-82de-4d56-a99b-6265678e95a3'
```

```http
HTTP/1.1 200 OK
Content-Length: 282
Content-Type: application/json

{"id":"bk-4852418b-82de-4d56-a99b-6265678e95a3","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation","createdAt":"2026-10-06T07:51:53.053Z","updatedAt":"2026-10-06T07:51:53.053Z"}

```

## G5 — Update a booking (PATCH)

Expected `200`, got `200` → **PASS**

```bash
curl -i '-X' 'PATCH' 'http://localhost:8787/api/bookings/bk-4852418b-82de-4d56-a99b-6265678e95a3' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T12:00:00.000Z","endAt":"2026-10-20T14:00:00.000Z","purpose":"Updated class presentation"}'
```

```http
HTTP/1.1 200 OK
Content-Length: 290
Content-Type: application/json

{"id":"bk-4852418b-82de-4d56-a99b-6265678e95a3","equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T12:00:00.000Z","endAt":"2026-10-20T14:00:00.000Z","purpose":"Updated class presentation","createdAt":"2026-10-06T07:51:53.053Z","updatedAt":"2026-10-06T07:51:54.377Z"}

```

## G6 — Invalid time range (start after end)

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-21T11:00:00.000Z","endAt":"2026-10-21T09:00:00.000Z","purpose":"Invalid time range test"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Length: 40
Content-Type: application/json

{"error":"startAt must be before endAt"}

```

## G7 — Overlapping booking (POST)

Expected `409`, got `409` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T12:30:00.000Z","endAt":"2026-10-20T13:30:00.000Z","purpose":"Conflict test"}'
```

```http
HTTP/1.1 409 Conflict
Content-Length: 115
Content-Type: application/json

{"error":"Equipment 'eq-1' is already booked in this time range (booking bk-4852418b-82de-4d56-a99b-6265678e95a3)"}

```

## G8 — Missing booking

Expected `404`, got `404` → **PASS**

```bash
curl -i 'http://localhost:8787/api/bookings/not-found'
```

```http
HTTP/1.1 404 Not Found
Content-Length: 29
Content-Type: application/json

{"error":"Booking not found"}

```

## E1 — Back-to-back booking allowed (starts when previous ends)

Expected `201`, got `201` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T14:00:00.000Z","endAt":"2026-10-20T15:00:00.000Z","purpose":"Back-to-back test"}'
```

```http
HTTP/1.1 201 Created
Content-Length: 275
Content-Type: application/json

{"id":"bk-bec7146c-c5ae-425b-81b9-833d1088f86d","equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T14:00:00.000Z","endAt":"2026-10-20T15:00:00.000Z","purpose":"Back-to-back test","createdAt":"2026-10-06T07:51:56.521Z","updatedAt":"2026-10-06T07:51:56.521Z"}

```

## E2 — Overlapping booking (PATCH into another booking's time)

Expected `409`, got `409` → **PASS**

```bash
curl -i '-X' 'PATCH' 'http://localhost:8787/api/bookings/bk-bec7146c-c5ae-425b-81b9-833d1088f86d' '-H' 'Content-Type: application/json' '-d' '{"startAt":"2026-10-20T13:00:00.000Z"}'
```

```http
HTTP/1.1 409 Conflict
Content-Length: 115
Content-Type: application/json

{"error":"Equipment 'eq-1' is already booked in this time range (booking bk-4852418b-82de-4d56-a99b-6265678e95a3)"}

```

## E3 — Missing required fields

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-1"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Length: 97
Content-Type: application/json

{"error":"borrowerName is required; purpose is required; startAt is required; endAt is required"}

```

## E4 — equipmentId does not exist

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-999","borrowerName":"A","startAt":"2026-10-22T09:00:00.000Z","endAt":"2026-10-22T10:00:00.000Z","purpose":"x"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Length: 47
Content-Type: application/json

{"error":"equipmentId 'eq-999' does not exist"}

```

## E5 — Malformed JSON body

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId": "eq-1",'
```

```http
HTTP/1.1 400 Bad Request
Content-Length: 42
Content-Type: application/json

{"error":"Request body is not valid JSON"}

```

## E6 — Impossible calendar date (Feb 30)

Expected `400`, got `400` → **PASS**

```bash
curl -i '-X' 'POST' 'http://localhost:8787/api/bookings' '-H' 'Content-Type: application/json' '-d' '{"equipmentId":"eq-2","borrowerName":"A","startAt":"2026-02-30T09:00:00.000Z","endAt":"2026-02-30T10:00:00.000Z","purpose":"x"}'
```

```http
HTTP/1.1 400 Bad Request
Content-Length: 176
Content-Type: application/json

{"error":"startAt must be an ISO 8601 date-time with timezone, e.g. 2026-10-20T09:00:00.000Z; endAt must be an ISO 8601 date-time with timezone, e.g. 2026-10-20T09:00:00.000Z"}

```

## E7 — PATCH a booking that does not exist

Expected `404`, got `404` → **PASS**

```bash
curl -i '-X' 'PATCH' 'http://localhost:8787/api/bookings/not-found' '-H' 'Content-Type: application/json' '-d' '{"purpose":"x"}'
```

```http
HTTP/1.1 404 Not Found
Content-Length: 29
Content-Type: application/json

{"error":"Booking not found"}

```

## G9 — Delete a booking

Expected `204`, got `204` → **PASS**

```bash
curl -i '-X' 'DELETE' 'http://localhost:8787/api/bookings/bk-4852418b-82de-4d56-a99b-6265678e95a3'
```

```http
HTTP/1.1 204 No Content


```

## E8 — Delete the same booking again

Expected `404`, got `404` → **PASS**

```bash
curl -i '-X' 'DELETE' 'http://localhost:8787/api/bookings/bk-4852418b-82de-4d56-a99b-6265678e95a3'
```

```http
HTTP/1.1 404 Not Found
Content-Length: 29
Content-Type: application/json

{"error":"Booking not found"}

```

## E9 — Clean up: delete back-to-back booking

Expected `204`, got `204` → **PASS**

```bash
curl -i '-X' 'DELETE' 'http://localhost:8787/api/bookings/bk-bec7146c-c5ae-425b-81b9-833d1088f86d'
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
