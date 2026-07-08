const router   = require('express').Router();
const multer   = require('multer');
const { body } = require('express-validator');
const { authenticate, attachStationScope } = require('../middleware/auth.middleware');
const { asyncWrap }     = require('../middleware/error.middleware');
const ctrl = require('../controllers/prisoner.controller');

const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 20 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const ok = /\.(xlsx|xls|csv)$/i.test(file.originalname);
    cb(ok ? null : new Error('Only .xlsx / .xls / .csv files allowed'), ok);
  },
});

const prisonerValidation = [
  body('prisonerId').notEmpty().withMessage('prisonerId is required'),
  body('name').notEmpty().withMessage('name is required'),
  body('admissionDate').notEmpty().withMessage('admissionDate is required'),
];

// All prisoner routes require a valid JWT + station scope derived from it
router.use(authenticate);
router.use(attachStationScope);

// /cross-station must be registered before /:id to avoid route collision
router.get('/cross-station', asyncWrap(ctrl.getCrossStation.bind(ctrl)));
router.get('/',              asyncWrap(ctrl.getAll.bind(ctrl)));
router.get('/stats',         asyncWrap(ctrl.getStats.bind(ctrl)));
router.get('/by-date',       asyncWrap(ctrl.getByDateFilter.bind(ctrl)));
router.get('/:id',           asyncWrap(ctrl.getById.bind(ctrl)));

router.post('/',             prisonerValidation, asyncWrap(ctrl.create.bind(ctrl)));
router.post('/bulk',         asyncWrap(ctrl.bulkImport.bind(ctrl)));
router.post('/import',       upload.single('file'), asyncWrap(ctrl.importExcel.bind(ctrl)));
router.put('/:id',           asyncWrap(ctrl.update.bind(ctrl)));
router.delete('/:id',        asyncWrap(ctrl.delete.bind(ctrl)));

module.exports = router;
