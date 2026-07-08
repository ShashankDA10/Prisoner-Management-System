const jwt = require('jsonwebtoken');

const STATION_LOCKED_ROLES = new Set(['inspector', 'si', 'prisonOfficer']);

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

/**
 * Derives station scope from the JWT — never from request params.
 * Station-locked roles get req.stationScope = their assigned station.
 * Global-access roles (admin, commissioner, dcpSp, acpDySp) get null.
 */
function attachStationScope(req, res, next) {
  const locked = STATION_LOCKED_ROLES.has(req.user?.role);

  if (locked) {
    const station = req.user.policeStation;
    if (!station) {
      return res.status(403).json({
        error: 'Your account has no police station assigned. Contact your administrator.',
      });
    }
    req.stationScope = station;
  } else {
    req.stationScope = null;
  }

  next();
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

module.exports = { authenticate, attachStationScope, requireAdmin };
