B=http://localhost:8787/api; H='Content-Type: application/json'
echo "[A] invalid JSON:"; curl -s -w ' -> %{http_code}\n' -H "$H" -d '{"equipmentId": "eq-1",' $B/bookings
echo "[B] impossible date 2026-02-30:"; curl -s -w ' -> %{http_code}\n' -H "$H" -d '{"equipmentId":"eq-2","borrowerName":"A","startAt":"2026-02-30T09:00:00.000Z","endAt":"2026-02-30T10:00:00.000Z","purpose":"x"}' $B/bookings
echo "[C] 10 concurrent POSTs for the same eq-3 slot (status codes):"
for i in $(seq 1 10); do curl -s -o /dev/null -w '%{http_code}\n' -H "$H" -d "{\"equipmentId\":\"eq-3\",\"borrowerName\":\"Racer $i\",\"startAt\":\"2026-11-01T09:00:00.000Z\",\"endAt\":\"2026-11-01T10:00:00.000Z\",\"purpose\":\"race\"}" $B/bookings & done; wait
echo "[C] eq-3 bookings stored for that slot:"; curl -s "$B/bookings?equipmentId=eq-3" | grep -o '"borrowerName":"[^"]*"' | wc -l
