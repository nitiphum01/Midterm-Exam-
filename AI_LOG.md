# AI Log

**Tool:** Claude Code (Claude Opus 5.5), used as a development assistant.

| # | Prompt (summary) | What I used | How I verified it |
|---|---|---|---|
| 1 | "Read the exam brief and rubric, list the rules, tools, and a step-by-step plan; wait for my approval." | The step plan (Step 0–5) and the decision list (stack, 400 vs 404 for unknown `equipmentId`, booking id format). | Checked the plan against `exam_brief_en.md` and `rubric_en.md` myself; I chose Hono + local D1 and 400 for unknown `equipmentId`. |
| 2 | "Set up the project (Step 0)." | `wrangler.jsonc`, `tsconfig.json`, npm scripts. | Ran `wrangler dev`, `GET /api/health` returned `{"status":"ok","db":true}`; `npx tsc` passed. |
| 3 | "Do Step 1–2: contract, schema/ERD, CRUD." | `schema.sql`, `src/index.ts`, `API_CONTRACT.md`, `README.md`. | Ran 12 curl cases (201/200/204/400/404/409); read each route and query; confirmed every SQL uses `.bind()` (no string concatenation of request data). |
| 4 | "Read quality_gate.md and curl_test_guide.md, then do Step 3." | Findings and fixes 1–4 in `QUALITY_GATE_REVIEW.md`. | Ran the same curl script against v1 (`git stash`) and the fixed code, saved to `evidence/qg_before.txt` / `qg_after.txt`. |
| 5 | "Deploy to Cloudflare (remote D1)." | `wrangler d1 create`, remote schema load, `wrangler deploy`. | Called the live URL: 200/201/409/204/404 as expected; removed the smoke-test booking. |
| 6 | "Do Step 4: curl tests + evidence." | `tests/curl_tests.sh` (guide cases G1–G9 + extra E1–E9). | Ran it on local and deployed: 18/18 pass. Noticed the first version logged commands without quotes (not copy-pasteable) and had it fixed before saving evidence. |

## What I did not accept blindly

- The AI suspected `2026-02-30` would be accepted; I confirmed it in Node (`new Date('2026-02-30T09:00:00Z')` → `2026-03-02`) before fixing.
- For the race-condition fix, the before/after test showed **no difference locally** (local D1 is sequential). I kept the fix because the reasoning holds for deployed Workers, and recorded this limitation honestly instead of claiming the test proved it.

## Key decisions I made (and can explain)

- `400` for nonexistent `equipmentId` in the body (invalid data); `404` only when the URL resource is missing; `409` for time conflicts.
- Half-open intervals: back-to-back bookings are allowed.
- Times normalized to UTC ISO strings so SQL string comparison equals time comparison.
