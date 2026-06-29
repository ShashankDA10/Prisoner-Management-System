const jwt        = require('jsonwebtoken');
const userRepo   = require('../repositories/user.repository');

class AuthService {
  /**
   * Validate credentials and return a signed JWT + user data.
   * Returns null if credentials are wrong.
   */
  login(username, password) {
    const user = userRepo.authenticate(username, password);
    if (!user) return null;

    const token = jwt.sign(
      { sub: user.id, username: user.username, role: user.role, name: user.name,
        policeStation: user.police_station },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    return { token, user };
  }

  /** Decode a token and return the payload (for /me endpoint). */
  verify(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }
}

module.exports = new AuthService();
