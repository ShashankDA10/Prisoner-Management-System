const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../config/database');
const TABLE = 'prisoners';

class PrisonerRepository {

  getAll(station = null) {
    if (station) {
      return getDb()
        .prepare(`SELECT * FROM ${TABLE} WHERE LOWER(police_station) = LOWER(?) ORDER BY created_at DESC`)
        .all(station)
        .map(rowToModel);
    }
    return getDb()
      .prepare(`SELECT * FROM ${TABLE} ORDER BY created_at DESC`)
      .all()
      .map(rowToModel);
  }

  getById(id) {
    const row = getDb().prepare(`SELECT * FROM ${TABLE} WHERE id = ?`).get(id);
    return row ? rowToModel(row) : null;
  }

  search(query, station = null) {
    const q = `%${query}%`;
    if (station) {
      return getDb().prepare(`
        SELECT * FROM ${TABLE}
        WHERE (name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ?
            OR crime_number LIKE ? OR police_station LIKE ?
            OR ipc_sections LIKE ? OR bns_sections LIKE ?)
          AND LOWER(police_station) = LOWER(?)
        ORDER BY name ASC
      `).all(q, q, q, q, q, q, q, station).map(rowToModel);
    }
    return getDb().prepare(`
      SELECT * FROM ${TABLE}
      WHERE name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ?
          OR crime_number LIKE ? OR police_station LIKE ?
          OR ipc_sections LIKE ? OR bns_sections LIKE ?
      ORDER BY name ASC
    `).all(q, q, q, q, q, q, q).map(rowToModel);
  }

  getByStatus(status, station = null) {
    if (station) {
      return getDb()
        .prepare(`SELECT * FROM ${TABLE} WHERE status = ? AND LOWER(police_station) = LOWER(?) ORDER BY name ASC`)
        .all(status, station)
        .map(rowToModel);
    }
    return getDb()
      .prepare(`SELECT * FROM ${TABLE} WHERE status = ? ORDER BY name ASC`)
      .all(status)
      .map(rowToModel);
  }

  /**
   * Returns all prisoners from stations other than excludeStation.
   * Used by the cross-station read-only screen.
   */
  searchCrossStation(query, excludeStation = null) {
    const hasQuery = query && query.trim().length > 0;
    const q = `%${query}%`;

    if (excludeStation) {
      if (hasQuery) {
        return getDb().prepare(`
          SELECT * FROM ${TABLE}
          WHERE (name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ?
              OR crime_number LIKE ? OR police_station LIKE ?
              OR ipc_sections LIKE ? OR bns_sections LIKE ?)
            AND LOWER(police_station) != LOWER(?)
          ORDER BY name ASC
        `).all(q, q, q, q, q, q, q, excludeStation).map(rowToModel);
      }
      return getDb()
        .prepare(`SELECT * FROM ${TABLE} WHERE LOWER(police_station) != LOWER(?) ORDER BY name ASC`)
        .all(excludeStation)
        .map(rowToModel);
    }

    return hasQuery ? this.search(query) : this.getAll();
  }

  getByDateFilter(filter, from, to, station = null) {
    const db = getDb();
    const sc = station ? ` AND LOWER(police_station) = LOWER(?)` : '';
    let stmt, params;

    switch (filter) {
      case 'today':
        stmt   = `SELECT * FROM ${TABLE} WHERE DATE(admission_date) = DATE('now')${sc} ORDER BY admission_date DESC`;
        params = station ? [station] : [];
        break;
      case 'thisWeek':
        stmt   = `SELECT * FROM ${TABLE} WHERE admission_date >= DATE('now', 'weekday 0', '-7 days')${sc} ORDER BY admission_date DESC`;
        params = station ? [station] : [];
        break;
      case 'thisMonth':
        stmt   = `SELECT * FROM ${TABLE} WHERE strftime('%Y-%m', admission_date) = strftime('%Y-%m', 'now')${sc} ORDER BY admission_date DESC`;
        params = station ? [station] : [];
        break;
      case 'custom':
        stmt   = `SELECT * FROM ${TABLE} WHERE admission_date >= ? AND admission_date <= ?${sc} ORDER BY admission_date DESC`;
        params = station ? [from, to, station] : [from, to];
        break;
      default:
        stmt   = station
          ? `SELECT * FROM ${TABLE} WHERE LOWER(police_station) = LOWER(?) ORDER BY admission_date DESC`
          : `SELECT * FROM ${TABLE} ORDER BY admission_date DESC`;
        params = station ? [station] : [];
    }

    return db.prepare(stmt).all(...params).map(rowToModel);
  }

  getDashboardStats(station = null) {
    const db = getDb();
    const sc = station ? ' AND LOWER(police_station) = LOWER(?)' : '';
    const sp = station ? [station] : [];

    const count = (cond) =>
      db.prepare(`SELECT COUNT(*) as n FROM ${TABLE} WHERE ${cond}${sc}`).get(...sp).n;

    return {
      total:       count('1=1'),
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
