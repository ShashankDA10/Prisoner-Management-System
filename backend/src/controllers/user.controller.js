const { validationResult } = require('express-validator');
const userRepo = require('../repositories/user.repository');

class UserController {
  getAll(req, res) {
    const users = userRepo.getAll();
    res.json({ data: users, total: users.length });
  }

  getById(req, res) {
    const user = userRepo.getById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  }

  create(req, res) {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ error: errs.array()[0].msg });

    const { username, password, name, role, policeStation = '', email = null, phone = null } = req.body;
    const user = userRepo.create({ username, password, name, role, policeStation, email, phone });
    res.status(201).json(user);
  }

  update(req, res) {
    const existing = userRepo.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'User not found' });

    const { name, role, policeStation = '', email = null, phone = null, isActive = true, password } = req.body;

    const updated = userRepo.update({ id: req.params.id, name, role, policeStation, email, phone, isActive });

    if (password) {
      userRepo.updatePassword(req.params.id, password);
    }

    res.json(updated);
  }

  delete(req, res) {
    const existing = userRepo.getById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'User not found' });

    const adminUsername = process.env.SEED_ADMIN_USERNAME || 'admin';
    if (existing.username === adminUsername) {
      return res.status(403).json({ error: 'Cannot delete the primary admin account' });
    }
    if (req.user.sub === req.params.id) {
      return res.status(403).json({ error: 'Cannot delete your own account' });
    }

    userRepo.delete(req.params.id);
    res.json({ message: 'User deleted successfully' });
  }
}

module.exports = new UserController();
