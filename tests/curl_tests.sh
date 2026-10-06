#!/usr/bin/env bash
# Runs the curl_test_guide.md cases (G1-G9) plus extra error cases (E1-E8)
# and writes a Markdown evidence file.
# Usage: bash tests/curl_tests.sh <BASE_URL> <output.md>
#   bash tests/curl_tests.sh http://localhost:8787/api evidence/local_results.md
BASE_URL="${1:-http://localhost:8787/api}"
OUT="${2:-evidence/results.md}"
H='Content-Type: application/json'
PASS=0; FAIL=0; SUMMARY=""
TMP=$(mktemp)

{
  echo "# curl test evidence"
  echo
  echo "- Base URL: \`$BASE_URL\`"
  echo "- Run at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
} > "$OUT"

# run_case <id> <title> <expected-status> <curl args...>
run_case() {
  local id="$1" title="$2" expected="$3"; shift 3
  local status
  status=$(curl -s -i -o "$TMP" -w '%{http_code}' "$@")
  local result="PASS"
  if [ "$status" = "$expected" ]; then PASS=$((PASS+1)); else result="FAIL"; FAIL=$((FAIL+1)); fi
  SUMMARY+="| $id | $title | $expected | $status | $result |"$'\n'
  {
    echo "## $id — $title"
    echo
    echo "Expected \`$expected\`, got \`$status\` → **$result**"
    echo
    echo '```bash'
    printf 'curl -i'; for a in "$@"; do printf " '%s'" "$a"; done; echo
    echo '```'
    echo
    echo '```http'
    tr -d '\r' < "$TMP" | grep -viE '^(date|cf-ray|server|report-to|nel|alt-svc|connection|keep-alive):'
    echo
    echo '```'
    echo
  } >> "$OUT"
  LAST_BODY=$(tr -d '\r' < "$TMP" | tail -1)
  LAST_STATUS="$status"
}

# id of the booking just created — only from a 201 (a 409 message also contains a "bk-..." id of the OTHER booking)
created_id() { [ "$LAST_STATUS" = 201 ] && echo "$LAST_BODY" | grep -o '"id":"bk-[0-9a-f-]*"' | grep -o 'bk-[0-9a-f-]*'; }

# ---------- cases from curl_test_guide.md ----------
run_case G1 "List equipment" 200 "$BASE_URL/equipment"
run_case G2 "List bookings" 200 "$BASE_URL/bookings"
run_case G3 "Create a booking" 201 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T09:00:00.000Z","endAt":"2026-10-20T11:00:00.000Z","purpose":"Class presentation"}'
BOOKING_ID=$(created_id)
if [ -z "$BOOKING_ID" ]; then
  # Without an id, G4/G5/G9 would call /bookings/ and could pass by accident — stop instead.
  echo "**STOPPED:** G3 did not create a booking (is a 2026-10-20 eq-1 booking left from an earlier run? delete it and re-run)." >> "$OUT"
  echo "G3 failed (got $(echo "$LAST_BODY")) — stopping. Delete leftover bookings and re-run." >&2
  exit 1
fi
run_case G4 "Get one booking" 200 "$BASE_URL/bookings/$BOOKING_ID"
run_case G5 "Update a booking (PATCH)" 200 -X PATCH "$BASE_URL/bookings/$BOOKING_ID" -H "$H" \
  -d '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-20T12:00:00.000Z","endAt":"2026-10-20T14:00:00.000Z","purpose":"Updated class presentation"}'
run_case G6 "Invalid time range (start after end)" 400 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-1","borrowerName":"Somchai Jaidee","startAt":"2026-10-21T11:00:00.000Z","endAt":"2026-10-21T09:00:00.000Z","purpose":"Invalid time range test"}'
run_case G7 "Overlapping booking (POST)" 409 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T12:30:00.000Z","endAt":"2026-10-20T13:30:00.000Z","purpose":"Conflict test"}'
run_case G8 "Missing booking" 404 "$BASE_URL/bookings/not-found"

# ---------- extra cases ----------
run_case E1 "Back-to-back booking allowed (starts when previous ends)" 201 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-1","borrowerName":"Suda Dee","startAt":"2026-10-20T14:00:00.000Z","endAt":"2026-10-20T15:00:00.000Z","purpose":"Back-to-back test"}'
SECOND_ID=$(created_id)
run_case E2 "Overlapping booking (PATCH into another booking's time)" 409 -X PATCH "$BASE_URL/bookings/$SECOND_ID" -H "$H" \
  -d '{"startAt":"2026-10-20T13:00:00.000Z"}'
run_case E3 "Missing required fields" 400 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-1"}'
run_case E4 "equipmentId does not exist" 400 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-999","borrowerName":"A","startAt":"2026-10-22T09:00:00.000Z","endAt":"2026-10-22T10:00:00.000Z","purpose":"x"}'
run_case E5 "Malformed JSON body" 400 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId": "eq-1",'
run_case E6 "Impossible calendar date (Feb 30)" 400 -X POST "$BASE_URL/bookings" -H "$H" \
  -d '{"equipmentId":"eq-2","borrowerName":"A","startAt":"2026-02-30T09:00:00.000Z","endAt":"2026-02-30T10:00:00.000Z","purpose":"x"}'
run_case E7 "PATCH a booking that does not exist" 404 -X PATCH "$BASE_URL/bookings/not-found" -H "$H" \
  -d '{"purpose":"x"}'

# ---------- delete ----------
run_case G9 "Delete a booking" 204 -X DELETE "$BASE_URL/bookings/$BOOKING_ID"
run_case E8 "Delete the same booking again" 404 -X DELETE "$BASE_URL/bookings/$BOOKING_ID"
run_case E9 "Clean up: delete back-to-back booking" 204 -X DELETE "$BASE_URL/bookings/$SECOND_ID"

{
  echo "## Summary"
  echo
  echo "| Case | Description | Expected | Actual | Result |"
  echo "|---|---|---:|---:|---|"
  printf '%s' "$SUMMARY"
  echo
  echo "**$PASS passed, $FAIL failed**"
} >> "$OUT"

rm -f "$TMP"
echo "$PASS passed, $FAIL failed -> $OUT"
