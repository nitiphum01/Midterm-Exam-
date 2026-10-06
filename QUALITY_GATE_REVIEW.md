# Quality Gate Review

The Quality Gate (`quality_gate.md`) was applied twice: **after the first version** (findings 1–4) and again in the **final check before submission** (findings 5–8).

| Commit | Meaning |
|---|---|
| `f975d81` | **Pre-review snapshot (v1)** — first working version, before the Quality Gate |
| `776c741` | Quality Gate fixes 1–4 + review docs |
| `3d9d8b0` | Deployed to Cloudflare Workers + remote D1 |
| `f9d614a` | Step 4 curl test suite + evidence |
| `54d4d94` | Final pass: AI log transparency, Windows run note |
| (this commit) | Final pass: test-script fix (finding 6), docs update |

Evidence files:
- `evidence/qg_before.txt` (v1 code) and `evidence/qg_after.txt` (after fixes 1–4), produced by running the same script (`tests/quality_gate_checks.sh`) against both versions.
- `evidence/local_results.md` and `evidence/deployed_results.md` — full curl suite (`tests/curl_tests.sh`), 18/18 on both.

## Round 1 — after the first version

| # | Quality Gate area | Finding | Action taken | Evidence |
|---|---|---|---|---|
| 1 | **Accuracy** | An impossible date was accepted and silently changed: `startAt: "2026-02-30T09:00:00.000Z"` was stored as `2026-03-02T09:00` and returned `201`. JavaScript `Date` rolls over invalid days instead of failing. | `parseTime()` now rebuilds the calendar date with `Date.UTC(y, m-1, d)` and rejects it if year/month/day changed. | Before: `201` with `startAt` = `2026-03-02…` (qg_before [B]). After: `400 {"error":"startAt must be an ISO 8601 date-time…"}` (qg_after [B]); a real leap day `2028-02-29` still returns `201` (qg_after [D]). Also case E6 in the curl suite. |
| 2 | **Accuracy** | Malformed JSON returned a misleading message: `{"error":"Request body must be a JSON object"}`, so the user cannot tell the body failed to parse. | `readJson()` returns an `INVALID_JSON` marker on parse failure; `validate()` maps it to `"Request body is not valid JSON"`. | Before: qg_before [A]. After: `400 {"error":"Request body is not valid JSON"}` (qg_after [A]; curl suite E5). |
| 3 | **Reliability** | The overlap check (`SELECT`) and the write (`INSERT`/`UPDATE`) were two separate statements. Two simultaneous requests could both pass the `SELECT` before either inserts, creating an overlap. | The write statements now include the overlap condition: `INSERT … SELECT … WHERE NOT EXISTS (overlap)` and `UPDATE … WHERE id = ? AND NOT EXISTS (overlap AND id != ?)`. If `meta.changes = 0` the API returns `409`. Check and write happen in one statement. | 10 concurrent POSTs for the same slot: exactly one `201`, nine `409`, one row stored (qg_after [C]). **Honest note:** local D1 processes requests one at a time, so v1 also passed this test (qg_before [C]); I could not reproduce the race locally. The fix is defensive for deployed Workers, where requests can run in parallel. |
| 4 | **Reasoning / You Own It** | I could state the overlap rule, but the docs did not explain *why* it is correct, the touching-range case, or why PATCH must exclude its own id. There was also no `AI_LOG.md`. | Added "How the overlap check works" (truth table + create/update explanation) and "Known limitations" to `README.md`; created `AI_LOG.md` listing what AI generated and what I verified. | `README.md` sections. Verified that a PATCH on its own booking does not falsely conflict (`200`, qg_after [E]) and that a PATCH into another booking's slot gives `409` (qg_after [F]). |

## Round 2 — final check before submission

| # | Quality Gate area | Finding | Action taken | Evidence |
|---|---|---|---|---|
| 5 | **Delivery Quality** | The first curl evidence logged commands without quotes (`-d {"equipmentId":…}`), so a marker could not copy-paste and re-run them. | `run_case` now prints every argument in single quotes. | Each case in `evidence/*_results.md` shows a runnable command, e.g. `curl -i '-X' 'POST' '…/bookings' '-H' 'Content-Type: application/json' '-d' '{…}'`. |
| 6 | **Reliability / Accuracy** (test evidence) | After my own manual test left a booking on 2026-10-20 in the remote DB, the suite reported G3 = `409` (FAIL) but G4–G9 still "passed". Cause: the script read the booking id with `grep 'bk-…'` from *any* response — the 409 message contains the id of the **other** booking — so it tested, patched and finally **deleted someone else's booking**, while the evidence looked mostly green. | Added `created_id()`: the id is taken only from a `201` response's `"id"` field. If G3 does not create a booking, the script writes **STOPPED** into the evidence and exits with code `1` instead of continuing. | Re-test with a leftover booking present: script printed `G3 failed … stopping`, `exit=1`, and the leftover booking was still there (`GET` → `200`). Clean runs afterwards: local 18/18, deployed 18/18; remote `GET /bookings` → `[]`. |
| 7 | **Execution Value** | README run steps had only been tested inside my working folder (with existing `node_modules` and `.wrangler` state). Also, on Windows PowerShell `npm`/`npx` fail with "running scripts is disabled on this system". | Cloned the repo from GitHub into an empty folder and followed README exactly; added a note to use `npm.cmd`/`npx.cmd` (or Git Bash) on Windows. | Fresh clone: `npm install` → `npm run db:init` → `npm run dev` → curl suite 18/18. |
| 8 | **You Own It** | `AI_LOG.md` listed prompts, but did not state plainly that the AI wrote most of the code and ran most verification commands — a reader could assume I did all of it. | Added a transparency note and rows 7–13 (PowerShell issue, Cloudflare setup, deploy + error 1042, final check, `/api` 404 decision, my own manual test, doc update), plus a list of AI output I did **not** accept blindly. | `AI_LOG.md`. |

Also checked in round 2, **no change needed**:
- **Accuracy / security:** searched `src/index.ts` for `${…}` — the only interpolation inside SQL is the constant `NO_OVERLAP`; all request data goes through `.bind()`.
- **Purpose:** opening `BASE_URL` (`…/api`) returns `404 {"error":"Route GET /api not found"}`. This is correct (not a route in the contract); I decided **not** to add a `GET /api` route because §1 says not to add unrelated features.

## Checklist status (final)

| Area | Status |
|---|---|
| 1 Purpose | Routes, bodies, status codes match the common contract. No extra features (no frontend/CORS, no `GET /api`). |
| 2 Reliability | Overlap blocked on create and update (atomic `NOT EXISTS`); `equipmentId` checked; invalid input → 400, never crashes; test script can no longer touch the wrong booking. |
| 3 Course Context | TypeScript + Hono + D1 (local via wrangler, deployed on Cloudflare); AI use recorded in `AI_LOG.md`. |
| 4 Reasoning | 400/404/409 reasons + status→test mapping in `API_CONTRACT.md`; overlap reasoning in `README.md`. |
| 5 Execution Value | README verified from a fresh GitHub clone; Windows note added. |
| 6 Accuracy | `startAt < endAt` enforced (API + `CHECK`); impossible dates rejected; all errors `{ "error": "..." }`; all SQL uses `.bind()`. |
| 7 Delivery Quality | Contract, schema/ERD, AI log, review, copy-pasteable evidence (local + deployed). |
| 8 You Own It | Transparent `AI_LOG.md`; decisions listed; I can explain each fix above. |

**Submission decision:** REWORK (after round 1 and again after finding 6) → **READY**: all required work is complete, 18/18 curl cases pass on local and deployed, and the evidence files were regenerated after the last fix.
