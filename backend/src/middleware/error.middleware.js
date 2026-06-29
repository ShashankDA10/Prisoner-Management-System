/**
 * Global error handler. All unhandled errors land here.
 * Returns a consistent JSON shape so the Flutter client can
 * always parse { error: string }.
 */
function errorHandler(err, req, res, next) {
  console.error(`[ERROR] ${req.method} ${req.path}`, err.message);

  if (err.type === 'validation') {
    return res.status(400).json({ error: err.message, details: err.details });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'File too large (max 20 MB)' });
  }

  const status = err.status || 500;
  res.status(status).json({ error: err.message || 'Internal server error' });
}

/** Wrap async route handlers so errors propagate to errorHandler. */
function asyncWrap(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

module.exports = { errorHandler, asyncWrap };
