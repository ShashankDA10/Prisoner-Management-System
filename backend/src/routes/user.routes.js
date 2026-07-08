const router     = require('express').Router();
const { body }   = require('express-validator');
const { authenticate, requireAdmin } = require('../middleware/auth.middleware');
const { asyncWrap }    = require('../middleware/error.middleware');
const ctrl       = require('../controllers/user.controller');

const createValidation = [
  body('username').notEmpty().withMessage('username is required'),
  body('password').notEmpty().withMessage('password is required'),
  body('name').notEmpty().withMessage('name is required'),
  body('role').notEmpty().withMessage('role is required'),
];

// All user management routes require authentication + admin role
router.use(authenticate);
router.use(requireAdmin);

router.get('/',       asyncWrap(ctrl.getAll.bind(ctrl)));
router.get('/:id',    asyncWrap(ctrl.getById.bind(ctrl)));
router.post('/',      createValidation, asyncWrap(ctrl.create.bind(ctrl)));
router.put('/:id',    asyncWrap(ctrl.update.bind(ctrl)));
router.delete('/:id', asyncWrap(ctrl.delete.bind(ctrl)));

module.exports = router;
