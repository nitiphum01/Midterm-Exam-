# AI Log

**Tool:** Claude Code (Claude Opus 5.5), used as a development assistant.

**Transparency note:** The AI wrote most of the code, docs, and test script, and ran the verification commands (tsc, wrangler, curl) at my request. I decided the stack and the key design choices, approved every step before it was done, reviewed the outputs and evidence files, and re-checked the main routes, SQL queries, and overlap logic myself so that I can explain them.

| # | Prompt (summary) | What I used | How I verified it |
|---|---|---|---|
| 1 | "Read the exam brief and rubric, list the rules, tools, and a step-by-step plan; wait for my approval." | The step plan (Step 0–5) and the decision list (stack, 400 vs 404 for unknown `equipmentId`, booking id format). | Checked the plan against `exam_brief_en.md` and `rubric_en.md` myself; I chose Hono + local D1 and 400 for unknown `equipmentId`. |
| 2 | "Set up the project (Step 0)." | `wrangler.jsonc`, `tsconfig.json`, npm scripts. | Ran `wrangler dev`, `GET /api/health` returned `{"status":"ok","db":true}`; `npx tsc` passed. |
| 3 | "Do Step 1–2: contract, schema/ERD, CRUD." | `schema.sql`, `src/index.ts`, `API_CONTRACT.md`, `README.md`. | Ran 12 curl cases (201/200/204/400/404/409); read each route and query; confirmed every SQL uses `.bind()` (no string concatenation of request data). |
| 4 | "Read quality_gate.md and curl_test_guide.md, then do Step 3." | Findings and fixes 1–4 in `QUALITY_GATE_REVIEW.md`. | Ran the same curl script against v1 (`git stash`) and the fixed code, saved to `evidence/qg_before.txt` / `qg_after.txt`. |
| 5 | "Deploy to Cloudflare (remote D1)." | `wrangler d1 create`, remote schema load, `wrangler deploy`. | Called the live URL: 200/201/409/204/404 as expected; removed the smoke-test booking. |
| 6 | "Do Step 4: curl tests + evidence." | `tests/curl_tests.sh` (guide cases G1–G9 + extra E1–E9). | Ran it on local and deployed: 18/18 pass. Noticed the first version logged commands without quotes (not copy-pasteable) and had it fixed before saving evidence. |
| 7 | "`npx`/`npm` fail in PowerShell (`npm.ps1 cannot be loaded … running scripts is disabled`). How do I fix it?" | Use `npm.cmd` / `npx.cmd`, or run everything in Git Bash. Did **not** change the system execution policy. | `npx.cmd wrangler login` and `npm.cmd run dev` worked. Added a Windows note to `README.md`. |
| 8 | "Set me up for Cloudflare from developers.cloudflare.com/agent-setup/prompt.md." | Installed the Cloudflare plugin for Claude Code (`claude plugin install cloudflare@cloudflare`). Skipped the optional beta `cf` CLI. | `claude plugin list` showed it enabled. Deployment itself was done with `wrangler`, not the plugin. |
| 9 | "Deploy after I logged in." | `wrangler d1 create booking-db` → id put in `wrangler.jsonc`; `db:init:remote`; `wrangler deploy`. | Live URL answered 200/201/409/204/404. Right after the first deploy some requests returned Cloudflare `error code: 1042`; retried after a short wait and it worked — caused by the new `workers.dev` subdomain propagating, not by the code. |
| 10 | "Step 5: final check before submission." | Fresh clone from GitHub, followed README, ran tests; grep of SQL; transparency note in this log; practice Q&A (not submitted). | Fresh clone: `npm install` → `db:init` → `dev` → 18/18 pass. Every `${…}` inside SQL is the constant `NO_OVERLAP`; all request data goes through `.bind()`. |
| 11 | "Opening `…/api` shows `{"error":"Route GET /api not found"}` — is that correct?" | Explanation: `BASE_URL` is a prefix, not a route; 404 JSON is the correct behaviour. | Opened `…/api/equipment` and `…/api/bookings` → 200. **Decision:** did not add a `GET /api` route, because Quality Gate §1 says not to add features outside the contract. |
| 12 | "How do I test bookings myself?" | Step-by-step curl commands for Git Bash (create → get → patch → 409 → 400 → 404 → delete). | I ran the tests myself against the deployed API. My run left a booking in the remote DB, so a later script run got 409 at G3 — this exposed a bug in the test script (see Quality Gate finding 6). |
| 13 | "Update API_CONTRACT, AI_LOG, QUALITY_GATE_REVIEW with what we did but did not record yet." | Added deployed URL, real error examples, status → test mapping to the contract; rows 7–13 here; final-pass findings 5–8 in the review. | Checked every example error message against `evidence/deployed_results.md`. Re-ran local and deployed tests after the script fix: 18/18. |

## What I did not accept blindly

- The AI suspected `2026-02-30` would be accepted; I confirmed it in Node (`new Date('2026-02-30T09:00:00Z')` → `2026-03-02`) before fixing.
- For the race-condition fix, the before/after test showed **no difference locally** (local D1 is sequential). I kept the fix because the reasoning holds for deployed Workers, and recorded this limitation honestly instead of claiming the test proved it.
- The AI-written test script reported 18/18 PASS, but when my own manual test left a booking behind, the script's evidence showed G3 = 409 while the following cases still "passed". Investigation showed the script took the booking id from the 409 error message (which names the *other* booking), so it tested and even deleted the wrong booking. A green test run is not proof by itself; the script was fixed (finding 6).
- The AI's first guard for that bug did not work (it still read the id from the 409 message); I only accepted the fix after it was re-tested with a leftover booking present and the script stopped with exit code 1 without touching that booking.

## Key decisions I made (and can explain)

- `400` for nonexistent `equipmentId` in the body (invalid data); `404` only when the URL resource is missing; `409` for time conflicts.
- Half-open intervals: back-to-back bookings are allowed.
- Times normalized to UTC ISO strings so SQL string comparison equals time comparison.
- Deploy to Cloudflare Workers + remote D1 in addition to local, so the API can be tested from any machine.
- No CORS, no frontend, no extra routes (e.g. no `GET /api`) — only what the contract requires.
