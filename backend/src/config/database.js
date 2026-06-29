/**
 * Database configuration and schema initialisation.
 *
 * MIGRATION NOTE: To swap SQLite for PostgreSQL/MySQL later, replace only
 * this file and the two repository files (user.repository.js,
 * prisoner.repository.js). Everything above the repository layer stays
 * the same.
 */

const Database = require('better-sqlite3');
const path     = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const DB_PATH = process.env.DB_PATH || './pums.db';
const dbFile  = path.resolve(__dirname, '../../', DB_PATH);

let db;

function getDb() {
  if (!db) throw new Error('Database not initialised — call initDb() first');
  return db;
}

function initDb() {
  db = new Database(dbFile);
  db.pragma('journal_mode = WAL');   // better concurrent read performance
  db.pragma('foreign_keys = ON');

  createSchema();
  seedAdmin();

  console.log(`[DB] SQLite ready at ${dbFile}`);
  return db;
}

// ── Schema ────────────────────────────────────────────────────────────────────

function createSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id              TEXT PRIMARY KEY,
      username        TEXT UNIQUE NOT NULL,
      password_hash   TEXT NOT NULL,
      name            TEXT NOT NULL,
      role            TEXT NOT NULL DEFAULT 'si',
      police_station  TEXT NOT NULL DEFAULT '',
      is_active       INTEGER NOT NULL DEFAULT 1,
      created_at      TEXT NOT NULL,
      updated_at      TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS prisoners (
      id              TEXT PRIMARY KEY,
      prisoner_id     TEXT UNIQUE NOT NULL,
      name            TEXT NOT NULL,
      age             INTEGER NOT NULL DEFAULT 0,
      gender          TEXT NOT NULL DEFAULT 'male',
      fir_number      TEXT NOT NULL DEFAULT '',
      crime_number    TEXT NOT NULL DEFAULT '',
      police_station  TEXT NOT NULL DEFAULT '',
      prison_name     TEXT NOT NULL DEFAULT '',
      admission_date  TEXT NOT NULL,
      status          TEXT NOT NULL DEFAULT 'undertrial',
      ipc_sections    TEXT NOT NULL DEFAULT '',
      bns_sections    TEXT NOT NULL DEFAULT '',
      release_date    TEXT,
      release_reason  TEXT,
      remarks         TEXT,
      created_at      TEXT NOT NULL,
      updated_at      TEXT NOT NULL,
      created_by      TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_prisoners_status     ON prisoners(status);
    CREATE INDEX IF NOT EXISTS idx_prisoners_station    ON prisoners(police_station);
    CREATE INDEX IF NOT EXISTS idx_prisoners_admission  ON prisoners(admission_date);
    CREATE INDEX IF NOT EXISTS idx_prisoners_prisoner_id ON prisoners(prisoner_id);
  `);
}

// ── Seed default admin on first run ──────────────────────────────────────────

function seedAdmin() {
  const bcrypt = require('bcryptjs');
  const { v4: uuidv4 } = require('uuid');

  const existing = db.prepare('SELECT id FROM users WHERE username = ?')
    .get(process.env.SEED_ADMIN_USERNAME || 'admin');

  if (!existing) {
    const now  = new Date().toISOString();
    const hash = bcrypt.hashSync(process.env.SEED_ADMIN_PASSWORD || 'Admin@1234', 12);
    db.prepare(`
      INSERT INTO users (id, username, password_hash, name, role, police_station, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'admin', '', 1, ?, ?)
    `).run(uuidv4(), process.env.SEED_ADMIN_USERNAME || 'admin', hash,
           process.env.SEED_ADMIN_NAME || 'System Administrator', now, now);

    console.log(`[DB] Admin user seeded: ${process.env.SEED_ADMIN_USERNAME || 'admin'}`);
  }
}

module.exports = { initDb, getDb };
