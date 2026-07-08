const jwt        = require('jsonwebtoken');
const userRepo   = require('../repositories/user.repository');

class AuthService {
  login(username, password) {
    const user = userRepo.authenticate(username, password);
    if (!user) return null;

    // Build the payload once — JWT and login response share the same shape
    const payload = {
      sub:           user.id,
      username:      user.username,
      role:          user.role,
      name:          user.name,
      policeStation: user.police_station,
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '8h',
    });

    return { token, user: payload };
  }

  verify(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }
}

module.exports = new AuthService();
