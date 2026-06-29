const jwt = require('jsonwebtoken');

/**
 * Verifies the Bearer JWT in the Authorization header.
 * Attaches decoded payload to req.user.
 *
 * MIGRATION NOTE: Replace this file with an OAuth/session strategy later.
 * The rest of the codebase uses req.user and never touches JWT directly.
 */
function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Missing authorisation token' });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/** Only allows users with role 'admin'. */
function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

module.exports = { authenticate, requireAdmin };
