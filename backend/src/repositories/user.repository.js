/**
 * User repository — SQLite implementation.
 *
 * MIGRATION NOTE: To switch database, implement the same methods using your
 * new ORM/driver and update the binding in auth.service.js.
 */

const bcrypt  = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../config/database');

class UserRepository {
  /** Verify username + password. Returns user row (without hash) or null. */
  authenticate(username, password) {
    const row = getDb()
      .prepare('SELECT * FROM users WHERE username = ? AND is_active = 1')
      .get(username.trim().toLowerCase());

    if (!row) return null;
    if (!bcrypt.compareSync(password, row.password_hash)) return null;

    const { password_hash, ...safe } = row;
    return safe;
  }

  getById(id) {
    const row = getDb().prepare('SELECT * FROM users WHERE id = ?').get(id);
    if (!row) return null;
    const { password_hash, ...safe } = row;
    return safe;
  }

  getAll() {
    return getDb()
      .prepare("SELECT id, username, name, role, police_station, is_active, created_at FROM users ORDER BY name")
      .all();
  }

  create({ username, password, name, role = 'si', policeStation = '' }) {
    const now  = new Date().toISOString();
    const id   = uuidv4();
    const hash = bcrypt.hashSync(password, 12);
    getDb().prepare(`
      INSERT INTO users (id, username, password_hash, name, role, police_station, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(id, username.trim().toLowerCase(), hash, name, role, policeStation, now, now);
    return this.getById(id);
  }

  updatePassword(id, newPassword) {
    const hash = bcrypt.hashSync(newPassword, 12);
    getDb().prepare('UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?')
      .run(hash, new Date().toISOString(), id);
  }

  setActive(id, isActive) {
    getDb().prepare('UPDATE users SET is_active = ?, updated_at = ? WHERE id = ?')
      .run(isActive ? 1 : 0, new Date().toISOString(), id);
  }
}

module.exports = new UserRepository();
