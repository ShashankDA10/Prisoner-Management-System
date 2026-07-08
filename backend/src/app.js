require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const path    = require('path');

const { initDb }       = require('./config/database');
const { errorHandler } = require('./middleware/error.middleware');
const authRoutes       = require('./routes/auth.routes');
const prisonerRoutes   = require('./routes/prisoner.routes');
const userRoutes       = require('./routes/user.routes');

// ── Init DB before starting server ───────────────────────────────────────────
initDb();

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Global middleware ─────────────────────────────────────────────────────────
app.use(cors());                           // allow Flutter (any origin) during dev
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth',      authRoutes);
app.use('/api/prisoners', prisonerRoutes);
app.use('/api/users',     userRoutes);

// Root + health check
app.get('/',           (_, res) => res.json({ name: 'PUMS API', status: 'ok' }));
app.get('/api/health', (_, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

// ── Error handler (must be last) ──────────────────────────────────────────────
app.use(errorHandler);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀  PUMS API running on http://0.0.0.0:${PORT}`);
  console.log(`   Health:    GET  /api/health`);
  console.log(`   Login:     POST /api/auth/login`);
  console.log(`   Prisoners: GET  /api/prisoners`);
  console.log(`   Import:    POST /api/prisoners/import\n`);
});

module.exports = app;
