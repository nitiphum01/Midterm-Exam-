# Quality Gate Review

- **Pre-review snapshot:** commit `f975d81` ("v1 snapshot") — first working version.
- **Evidence files:** `evidence/qg_before.txt` (v1 code) and `evidence/qg_after.txt` (after fixes), produced by running the same curl script against both versions.

| # | Quality Gate area | Finding | Action taken | Evidence |
|---|---|---|---|---|
| 1 | **Accuracy** | An impossible date was accepted and silently changed: `startAt: "2026-02-30T09:00:00.000Z"` was stored as `2026-03-02T09:00` and returned `201`. JavaScript `Date` rolls over invalid days instead of failing. | `parseTime()` now rebuilds the calendar date with `Date.UTC(y, m-1, d)` and rejects it if year/month/day changed. | Before: `201` with `startAt` = `2026-03-02…` (qg_before [B]). After: `400 {"error":"startAt must be an ISO 8601 date-time…"}` (qg_after [B]); a real leap day `2028-02-29` still returns `201` (qg_after [D]). |
| 2 | **Accuracy** | Malformed JSON returned a misleading message: `{"error":"Request body must be a JSON object"}`, so the user cannot tell the body failed to parse. | `readJson()` returns an `INVALID_JSON` marker on parse failure; `validate()` maps it to `"Request body is not valid JSON"`. | Before: qg_before [A]. After: `400 {"error":"Request body is not valid JSON"}` (qg_after [A]). |
| 3 | **Reliability** | The overlap check (`SELECT`) and the write (`INSERT`/`UPDATE`) were two separate statements. Two simultaneous requests could both pass the `SELECT` before either inserts, creating an overlap. | The write statements now include the overlap condition: `INSERT … SELECT … WHERE NOT EXISTS (overlap)` and `UPDATE … WHERE id = ? AND NOT EXISTS (overlap AND id != ?)`. If `meta.changes = 0` the API returns `409`. Check and write happen in one statement. | 10 concurrent POSTs for the same slot: exactly one `201`, nine `409`, one row stored (qg_after [C]). **Honest note:** local D1 processes requests one at a time, so v1 also passed this test (qg_before [C]); I could not reproduce the race locally. The fix is defensive for deployed Workers, where requests can run in parallel. |
| 4 | **Reasoning / You Own It** | I could state the overlap rule, but the docs did not explain *why* it is correct, the touching-range case, or why PATCH must exclude its own id. There was also no `AI_LOG.md`. | Added "How the overlap check works" (truth table + create/update explanation) and "Known limitations" to `README.md`; created `AI_LOG.md` listing what AI generated and what I verified. | `README.md` sections. Verified that a PATCH on its own booking does not falsely conflict (`200`, qg_after [E]) and that a PATCH into another booking's slot gives `409` (qg_after [F]). |

## Checklist status

| Area | Status |
|---|---|
| 1 Purpose | Routes, bodies, and status codes match the common contract. No extra features (no frontend/CORS). |
| 2 Reliability | Overlap blocked on create and update (atomic); `equipmentId` checked; invalid input → 400, never crashes. |
| 3 Course Context | Hono + local D1 via wrangler; AI use recorded in `AI_LOG.md`. |
| 4 Reasoning | 400/404/409 reasons in `API_CONTRACT.md`; overlap reasoning in `README.md`. |
| 5 Execution Value | README run steps tested from a clean `.wrangler` state. |
| 6 Accuracy | `startAt < endAt` enforced (API + `CHECK`); all errors `{ "error": "..." }`; all SQL uses `.bind()`. |
| 7 Delivery Quality | Contract, schema/ERD, evidence present. |
| 8 You Own It | See `AI_LOG.md`. |

**Submission decision:** REWORK → after these fixes and Step 4 evidence (18/18 curl cases pass on local and deployed, see `evidence/`): **READY**.
