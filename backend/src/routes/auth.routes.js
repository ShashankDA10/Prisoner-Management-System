const router     = require('express').Router();
const { body }   = require('express-validator');
const { authenticate } = require('../middleware/auth.middleware');
const { asyncWrap }    = require('../middleware/error.middleware');
const ctrl       = require('../controllers/auth.controller');

router.post('/login',
  body('username').notEmpty().withMessage('Username is required'),
  body('password').notEmpty().withMessage('Password is required'),
  asyncWrap(ctrl.login.bind(ctrl))
);

router.post('/logout', authenticate, asyncWrap(ctrl.logout.bind(ctrl)));
router.get('/me',      authenticate, asyncWrap(ctrl.me.bind(ctrl)));

module.exports = router;
