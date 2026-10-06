import { Hono } from 'hono'

type Bindings = { DB: D1Database }

type BookingRow = {
  id: string
  equipment_id: string
  borrower_name: string
  start_at: string
  end_at: string
  purpose: string
  created_at: string
  updated_at: string
}

type BookingInput = {
  equipmentId: string
  borrowerName: string
  startAt: string
  endAt: string
  purpose: string
}

const app = new Hono<{ Bindings: Bindings }>().basePath('/api')

// ---------- helpers ----------

// DB row (snake_case) -> API response (camelCase)
const toBooking = (r: BookingRow) => ({
  id: r.id,
  equipmentId: r.equipment_id,
  borrowerName: r.borrower_name,
  startAt: r.start_at,
  endAt: r.end_at,
  purpose: r.purpose,
  createdAt: r.created_at,
  updatedAt: r.updated_at,
})

// ISO 8601 with time and timezone, e.g. 2026-10-20T09:00:00.000Z or 2026-10-20T16:00:00+07:00
const ISO_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/

// Returns normalized UTC ISO string, or null if invalid
function parseTime(v: unknown): string | null {
  if (typeof v !== 'string' || !ISO_RE.test(v)) return null
  const d = new Date(v)
  return Number.isNaN(d.getTime()) ? null : d.toISOString()
}

const FIELDS = ['equipmentId', 'borrowerName', 'startAt', 'endAt', 'purpose'] as const

// partial = true for PATCH (only validate fields that are present)
function validate(body: unknown, partial: boolean): { error: string } | { data: Partial<BookingInput> } {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { error: 'Request body must be a JSON object' }
  }
  const b = body as Record<string, unknown>
  const errors: string[] = []
  const data: Partial<BookingInput> = {}

  const unknown = Object.keys(b).filter((k) => !(FIELDS as readonly string[]).includes(k))
  if (unknown.length) errors.push(`Unknown field(s): ${unknown.join(', ')}`)
  if (partial && !FIELDS.some((f) => b[f] !== undefined)) errors.push('At least one field is required')

  const text = (field: 'equipmentId' | 'borrowerName' | 'purpose', max: number) => {
    if (b[field] === undefined) {
      if (!partial) errors.push(`${field} is required`)
      return
    }
    const v = b[field]
    if (typeof v !== 'string' || v.trim() === '') errors.push(`${field} must be a non-empty string`)
    else if (v.trim().length > max) errors.push(`${field} must be at most ${max} characters`)
    else data[field] = v.trim()
  }
  text('equipmentId', 50)
  text('borrowerName', 100)
  text('purpose', 200)

  for (const field of ['startAt', 'endAt'] as const) {
    if (b[field] === undefined) {
      if (!partial) errors.push(`${field} is required`)
      continue
    }
    const t = parseTime(b[field])
    if (t === null) errors.push(`${field} must be an ISO 8601 date-time with timezone, e.g. 2026-10-20T09:00:00.000Z`)
    else data[field] = t
  }

  return errors.length ? { error: errors.join('; ') } : { data }
}

// Business rules shared by POST and PATCH. Returns [status, message] on failure, null if OK.
async function checkRules(db: D1Database, b: BookingInput, excludeId: string | null): Promise<[400 | 409, string] | null> {
  if (b.startAt >= b.endAt) return [400, 'startAt must be before endAt']

  const eq = await db.prepare('SELECT id FROM equipment WHERE id = ?').bind(b.equipmentId).first()
  if (!eq) return [400, `equipmentId '${b.equipmentId}' does not exist`]

  // Overlap: existing.start < new.end AND new.start < existing.end (touching end/start is allowed)
  const clash = await db
    .prepare('SELECT id FROM bookings WHERE equipment_id = ? AND start_at < ? AND end_at > ? AND id != ? LIMIT 1')
    .bind(b.equipmentId, b.endAt, b.startAt, excludeId ?? '')
    .first<{ id: string }>()
  if (clash) return [409, `Equipment '${b.equipmentId}' is already booked in this time range (booking ${clash.id})`]

  return null
}

async function readJson(c: { req: { json: () => Promise<unknown> } }): Promise<unknown> {
  try {
    return await c.req.json()
  } catch {
    return undefined // invalid JSON -> validate() rejects it with 400
  }
}

// ---------- routes ----------

app.get('/health', (c) => c.json({ status: 'ok' }))

app.get('/equipment', async (c) => {
  const { results } = await c.env.DB.prepare('SELECT id, name, location FROM equipment ORDER BY id').all()
  return c.json(results)
})

app.get('/bookings', async (c) => {
  const equipmentId = c.req.query('equipmentId')
  const stmt = equipmentId
    ? c.env.DB.prepare('SELECT * FROM bookings WHERE equipment_id = ? ORDER BY start_at').bind(equipmentId)
    : c.env.DB.prepare('SELECT * FROM bookings ORDER BY start_at')
  const { results } = await stmt.all<BookingRow>()
  return c.json(results.map(toBooking))
})

app.get('/bookings/:id', async (c) => {
  const row = await c.env.DB.prepare('SELECT * FROM bookings WHERE id = ?').bind(c.req.param('id')).first<BookingRow>()
  if (!row) return c.json({ error: 'Booking not found' }, 404)
  return c.json(toBooking(row))
})

app.post('/bookings', async (c) => {
  const v = validate(await readJson(c), false)
  if ('error' in v) return c.json({ error: v.error }, 400)
  const b = v.data as BookingInput

  const fail = await checkRules(c.env.DB, b, null)
  if (fail) return c.json({ error: fail[1] }, fail[0])

  const id = `bk-${crypto.randomUUID()}`
  const now = new Date().toISOString()
  await c.env.DB.prepare(
    'INSERT INTO bookings (id, equipment_id, borrower_name, start_at, end_at, purpose, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(id, b.equipmentId, b.borrowerName, b.startAt, b.endAt, b.purpose, now, now)
    .run()

  const row = await c.env.DB.prepare('SELECT * FROM bookings WHERE id = ?').bind(id).first<BookingRow>()
  return c.json(toBooking(row!), 201)
})

app.patch('/bookings/:id', async (c) => {
  const id = c.req.param('id')
  const existing = await c.env.DB.prepare('SELECT * FROM bookings WHERE id = ?').bind(id).first<BookingRow>()
  if (!existing) return c.json({ error: 'Booking not found' }, 404)

  const v = validate(await readJson(c), true)
  if ('error' in v) return c.json({ error: v.error }, 400)

  // merge partial update onto current values, then re-check all rules on the result
  const current = toBooking(existing)
  const merged: BookingInput = {
    equipmentId: v.data.equipmentId ?? current.equipmentId,
    borrowerName: v.data.borrowerName ?? current.borrowerName,
    startAt: v.data.startAt ?? current.startAt,
    endAt: v.data.endAt ?? current.endAt,
    purpose: v.data.purpose ?? current.purpose,
  }
  const fail = await checkRules(c.env.DB, merged, id)
  if (fail) return c.json({ error: fail[1] }, fail[0])

  await c.env.DB.prepare(
    'UPDATE bookings SET equipment_id = ?, borrower_name = ?, start_at = ?, end_at = ?, purpose = ?, updated_at = ? WHERE id = ?'
  )
    .bind(merged.equipmentId, merged.borrowerName, merged.startAt, merged.endAt, merged.purpose, new Date().toISOString(), id)
    .run()

  const row = await c.env.DB.prepare('SELECT * FROM bookings WHERE id = ?').bind(id).first<BookingRow>()
  return c.json(toBooking(row!))
})

app.delete('/bookings/:id', async (c) => {
  const res = await c.env.DB.prepare('DELETE FROM bookings WHERE id = ?').bind(c.req.param('id')).run()
  if (res.meta.changes === 0) return c.json({ error: 'Booking not found' }, 404)
  return c.body(null, 204)
})

// ---------- fallbacks: every error is JSON { error } ----------

app.notFound((c) => c.json({ error: `Route ${c.req.method} ${c.req.path} not found` }, 404))

app.onError((err, c) => {
  console.error(err) // keep details in server log, not in the response
  return c.json({ error: 'Internal server error' }, 500)
})

export default app
