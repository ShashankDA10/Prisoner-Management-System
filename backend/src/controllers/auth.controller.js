const { validationResult } = require('express-validator');
const authService = require('../services/auth.service');

class AuthController {
  login(req, res) {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ error: errs.array()[0].msg });

    const result = authService.login(req.body.username, req.body.password);
    if (!result) return res.status(401).json({ error: 'Invalid username or password' });

    res.json({ token: result.token, user: result.user });
  }

  logout(req, res) {
    // Stateless JWT — client simply discards the token.
    // If you add a token blacklist later, invalidate it here.
    res.json({ message: 'Logged out successfully' });
  }

  me(req, res) {
    // req.user is set by authenticate() middleware
    res.json({ user: req.user });
  }
}

module.exports = new AuthController();
