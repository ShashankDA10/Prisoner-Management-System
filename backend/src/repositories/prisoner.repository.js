/**
 * Prisoner repository — SQLite implementation.
 *
 * MIGRATION NOTE: To switch to PostgreSQL/MySQL, implement the same methods
 * with pg/mysql2/Sequelize and update the binding in prisoner.service.js.
 * No other file needs to change.
 *
 * All methods are synchronous at the DB level (better-sqlite3) but return
 * values directly — the service layer may wrap them in async if needed.
 */

const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../config/database');
const TABLE = 'prisoners';

class PrisonerRepository {

  getAll() {
    return getDb()
      .prepare(`SELECT * FROM ${TABLE} ORDER BY created_at DESC`)
      .all()
      .map(rowToModel);
  }

  getById(id) {
    const row = getDb().prepare(`SELECT * FROM ${TABLE} WHERE id = ?`).get(id);
    return row ? rowToModel(row) : null;
  }

  search(query) {
    const q = `%${query}%`;
    return getDb().prepare(`
      SELECT * FROM ${TABLE}
      WHERE  name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ?
          OR crime_number LIKE ? OR police_station LIKE ?
          OR ipc_sections LIKE ? OR bns_sections LIKE ?
      ORDER BY name ASC
    `).all(q, q, q, q, q, q, q).map(rowToModel);
  }

  getByStatus(status) {
    return getDb()
      .prepare(`SELECT * FROM ${TABLE} WHERE status = ? ORDER BY name ASC`)
      .all(status)
      .map(rowToModel);
  }

  /**
   * filter: 'today' | 'thisWeek' | 'thisMonth' | 'custom'
   * from / to: ISO strings (for custom range)
   */
  getByDateFilter(filter, from, to) {
    let stmt, params = [];
    const db = getDb();

    switch (filter) {
      case 'today':
        stmt = `SELECT * FROM ${TABLE} WHERE DATE(admission_date) = DATE('now') ORDER BY admission_date DESC`;
        break;
      case 'thisWeek':
        stmt = `SELECT * FROM ${TABLE} WHERE admission_date >= DATE('now', 'weekday 0', '-7 days') ORDER BY admission_date DESC`;
        break;
      case 'thisMonth':
        stmt = `SELECT * FROM ${TABLE} WHERE strftime('%Y-%m', admission_date) = strftime('%Y-%m', 'now') ORDER BY admission_date DESC`;
        break;
      case 'custom':
        stmt   = `SELECT * FROM ${TABLE} WHERE admission_date >= ? AND admission_date <= ? ORDER BY admission_date DESC`;
        params = [from, to];
        break;
      default:
        stmt = `SELECT * FROM ${TABLE} ORDER BY admission_date DESC`;
    }

    return db.prepare(stmt).all(...params).map(rowToModel);
  }

  getDashboardStats() {
    const db = getDb();
    const count = (where) =>
      db.prepare(`SELECT COUNT(*) as n FROM ${TABLE}${where ? ` WHERE ${where}` : ''}`).get().n;

    return {
      total:       count(null),
      undertrial:  count("status = 'undertrial'"),
      convicted:   count("status = 'convicted'"),
      admitted:    count("DATE(admission_date) = DATE('now')"),
      released:    count("status = 'released'"),
      bail:        count("status = 'bail'"),
      transferred: count("status = 'transferred'"),
    };
  }

  insert(model) {
    const id  = model.id || uuidv4();
    const now = new Date().toISOString();
    const row = modelToRow({ ...model, id, createdAt: now, updatedAt: now });
    getDb().prepare(`
      INSERT INTO ${TABLE}
        (id, prisoner_id, name, age, gender, fir_number, crime_number,
         police_station, prison_name, admission_date, status, ipc_sections,
         bns_sections, release_date, release_reason, remarks, created_at,
         updated_at, created_by)
      VALUES
        (@id, @prisoner_id, @name, @age, @gender, @fir_number, @crime_number,
         @police_station, @prison_name, @admission_date, @status, @ipc_sections,
         @bns_sections, @release_date, @release_reason, @remarks, @created_at,
         @updated_at, @created_by)
    `).run(row);
    return id;
  }

  update(model) {
    const row = modelToRow({ ...model, updatedAt: new Date().toISOString() });
    getDb().prepare(`
      UPDATE ${TABLE} SET
        prisoner_id = @prisoner_id, name = @name, age = @age,
        gender = @gender, fir_number = @fir_number, crime_number = @crime_number,
        police_station = @police_station, prison_name = @prison_name,
        admission_date = @admission_date, status = @status,
        ipc_sections = @ipc_sections, bns_sections = @bns_sections,
        release_date = @release_date, release_reason = @release_reason,
        remarks = @remarks, updated_at = @updated_at
      WHERE id = @id
    `).run(row);
  }

  delete(id) {
    getDb().prepare(`DELETE FROM ${TABLE} WHERE id = ?`).run(id);
  }

  /**
   * Bulk import — returns { inserted, updated, skipped }.
   * updateExisting: overwrite if prisoner_id already exists
   * skipDuplicates: silently skip if prisoner_id exists
   */
  bulkImport(models, { updateExisting = false, skipDuplicates = true } = {}) {
    const db = getDb();
    let inserted = 0, updated = 0, skipped = 0;

    const insertOne = db.prepare(`
      INSERT OR IGNORE INTO ${TABLE}
        (id, prisoner_id, name, age, gender, fir_number, crime_number,
         police_station, prison_name, admission_date, status, ipc_sections,
         bns_sections, release_date, release_reason, remarks,
         created_at, updated_at, created_by)
      VALUES
        (@id, @prisoner_id, @name, @age, @gender, @fir_number, @crime_number,
         @police_station, @prison_name, @admission_date, @status, @ipc_sections,
         @bns_sections, @release_date, @release_reason, @remarks,
         @created_at, @updated_at, @created_by)
    `);

    const updateOne = db.prepare(`
      UPDATE ${TABLE} SET
        name = @name, age = @age, gender = @gender, fir_number = @fir_number,
        crime_number = @crime_number, police_station = @police_station,
        prison_name = @prison_name, admission_date = @admission_date,
        status = @status, ipc_sections = @ipc_sections,
        bns_sections = @bns_sections, release_date = @release_date,
        release_reason = @release_reason, remarks = @remarks,
        updated_at = @updated_at
      WHERE prisoner_id = @prisoner_id
    `);

    const findByPrisonerId = db.prepare(`SELECT id FROM ${TABLE} WHERE prisoner_id = ?`);

    const run = db.transaction((rows) => {
      for (const model of rows) {
        const now      = new Date().toISOString();
        const existing = findByPrisonerId.get(model.prisonerId);

        if (existing) {
          if (updateExisting) {
            updateOne.run(modelToRow({ ...model, updatedAt: now }));
            updated++;
          } else if (skipDuplicates) {
            skipped++;
          }
        } else {
          insertOne.run(modelToRow({ ...model, id: uuidv4(), createdAt: now, updatedAt: now }));
          inserted++;
        }
      }
    });

    run(models);
    return { inserted, updated, skipped };
  }
}

// ── Row ↔ Model mappers ───────────────────────────────────────────────────────

function rowToModel(row) {
  return {
    id:            row.id,
    prisonerId:    row.prisoner_id,
    name:          row.name,
    age:           row.age,
    gender:        row.gender,
    firNumber:     row.fir_number,
    crimeNumber:   row.crime_number,
    policeStation: row.police_station,
    prisonName:    row.prison_name,
    admissionDate: row.admission_date,
    status:        row.status,
    ipcSections:   row.ipc_sections ? row.ipc_sections.split(',').filter(Boolean) : [],
    bnsSections:   row.bns_sections ? row.bns_sections.split(',').filter(Boolean) : [],
    releaseDate:   row.release_date   || null,
    releaseReason: row.release_reason || null,
    remarks:       row.remarks        || null,
    createdAt:     row.created_at,
    updatedAt:     row.updated_at,
    createdBy:     row.created_by     || null,
  };
}

function modelToRow(m) {
  return {
    id:             m.id            || null,
    prisoner_id:    m.prisonerId    || '',
    name:           m.name          || '',
    age:            m.age           || 0,
    gender:         m.gender        || 'male',
    fir_number:     m.firNumber     || '',
    crime_number:   m.crimeNumber   || '',
    police_station: m.policeStation || '',
    prison_name:    m.prisonName    || '',
    admission_date: m.admissionDate || new Date().toISOString(),
    status:         m.status        || 'undertrial',
    ipc_sections:   Array.isArray(m.ipcSections) ? m.ipcSections.join(',') : (m.ipcSections || ''),
    bns_sections:   Array.isArray(m.bnsSections) ? m.bnsSections.join(',') : (m.bnsSections || ''),
    release_date:   m.releaseDate   || null,
    release_reason: m.releaseReason || null,
    remarks:        m.remarks       || null,
    created_at:     m.createdAt     || new Date().toISOString(),
    updated_at:     m.updatedAt     || new Date().toISOString(),
    created_by:     m.createdBy     || null,
  };
}

module.exports = new PrisonerRepository();
