-- Campus Equipment Booking API schema (D1 / SQLite)
-- Times are stored as ISO 8601 UTC strings (toISOString format), so string comparison = time comparison.

CREATE TABLE IF NOT EXISTS equipment (
  id       TEXT PRIMARY KEY,          -- e.g. 'eq-1'
  name     TEXT NOT NULL,
  location TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings (
  id            TEXT PRIMARY KEY,     -- 'bk-<uuid>'
  equipment_id  TEXT NOT NULL REFERENCES equipment(id),
  borrower_name TEXT NOT NULL,
  start_at      TEXT NOT NULL,
  end_at        TEXT NOT NULL,
  purpose       TEXT NOT NULL,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  CHECK (start_at < end_at)
);

-- speeds up the overlap check (WHERE equipment_id = ? AND start_at < ? AND end_at > ?)
CREATE INDEX IF NOT EXISTS idx_bookings_equipment_time ON bookings (equipment_id, start_at);

INSERT OR IGNORE INTO equipment (id, name, location) VALUES
  ('eq-1', 'Projector A', 'Building 1'),
  ('eq-2', 'Camera B', 'Building 2'),
  ('eq-3', 'Meeting Room C', 'Building 3');
