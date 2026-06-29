/**
 * Excel / CSV import service.
 *
 * Designed to be flexible: if column names change slightly, only the
 * COLUMN_MAP constant needs updating.
 */

const XLSX = require('xlsx');

// Maps human-readable headers → internal field names
// Add aliases here whenever the Excel format changes.
const COLUMN_MAP = {
  'jid':                    'prisonerId',
  'prisoner_id':            'prisonerId',
  'prisoner name':          'name',
  'name':                   'name',
  'father name':            'fatherName',
  'gender':                 'gender',
  'age':                    'age',
  'fir/case no':            'firNumber',
  'fir no':                 'firNumber',
  'case no':                'crimeNumber',
  'case no.':               'crimeNumber',
  'ps name':                'policeStation',
  'police station':         'policeStation',
  'permanent address':      'address',
  'address':                'address',
  'admission date':         'admissionDate',
  'latest admission date':  'admissionDate',
  'date of admission':      'admissionDate',
  'act section':            'actSection',
  'sections':               'actSection',
  'court name':             'courtName',
  'release date':           'releaseDate',
  'prison name':            'prisonName',
  'prison':                 'prisonName',
  'status':                 'status',
  'remarks':                'remarks',
};

const REQUIRED_FIELDS = ['prisonerId', 'name', 'admissionDate'];

/**
 * Parse an xlsx/csv buffer and return an array of prisoner model objects.
 * Throws on fatal errors, collects per-row errors into result.errors[].
 */
function parseExcel(buffer) {
  const workbook = XLSX.read(buffer, { type: 'buffer', cellDates: true });
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  // Convert to array-of-arrays (raw) to detect header row ourselves
  const raw = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });

  if (raw.length < 2) throw new Error('Sheet is empty or has no data rows');

  // Find header row (first row that contains at least 3 known columns)
  let headerRowIdx = 0;
  let colMap = {};
  for (let i = 0; i < Math.min(5, raw.length); i++) {
    const candidate = buildColMap(raw[i]);
    if (Object.keys(candidate).length >= 3) {
      colMap = candidate;
      headerRowIdx = i;
      break;
    }
  }

  if (Object.keys(colMap).length === 0) {
    throw new Error('Could not detect header row in the sheet');
  }

  const models  = [];
  const errors  = [];

  for (let r = headerRowIdx + 1; r < raw.length; r++) {
    const row = raw[r];
    // Skip truly empty rows
    if (row.every(cell => cell === '' || cell == null)) continue;

    try {
      const model = mapRow(row, colMap, r + 1);
      models.push(model);
    } catch (e) {
      errors.push({ row: r + 1, error: e.message });
    }
  }

  return { models, errors, sheetName, totalRows: raw.length - headerRowIdx - 1 };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function buildColMap(headerRow) {
  const map = {};
  headerRow.forEach((cell, idx) => {
    const key = String(cell).trim().toLowerCase();
    const field = COLUMN_MAP[key];
    if (field && !(field in map)) map[field] = idx;
  });
  return map;
}

function mapRow(row, colMap, rowNum) {
  const get = (field) => {
    const idx = colMap[field];
    return idx !== undefined ? row[idx] : undefined;
  };

  // Validate required fields
  for (const f of REQUIRED_FIELDS) {
    const val = get(f);
    if (val === undefined || val === '') {
      throw new Error(`Missing required field "${f}"`);
    }
  }

  const admissionDate = parseDate(get('admissionDate'));
  if (!admissionDate) throw new Error(`Invalid admission date: "${get('admissionDate')}"`);

  const releaseRaw  = get('releaseDate');
  const releaseDate = releaseRaw ? parseDate(releaseRaw) : null;

  // Build remarks from supplementary columns
  const remarkParts = [];
  const fatherName  = get('fatherName');
  const address     = get('address');
  const courtName   = get('courtName');
  const actSection  = get('actSection');
  if (fatherName)  remarkParts.push(`Father: ${fatherName}`);
  if (address)     remarkParts.push(`Address: ${address}`);
  if (courtName)   remarkParts.push(`Court: ${courtName}`);

  // Sections from actSection column
  const sections = actSection
    ? String(actSection).split(/[,;/]+/).map(s => s.trim()).filter(Boolean)
    : [];

  const rawStatus = (get('status') || '').toLowerCase();
  let status = 'undertrial';
  if      (rawStatus.includes('convict'))   status = 'convicted';
  else if (rawStatus.includes('release'))   status = 'released';
  else if (rawStatus.includes('bail'))      status = 'bail';
  else if (rawStatus.includes('transfer'))  status = 'transferred';
  else if (rawStatus.includes('acquit'))    status = 'acquitted';
  else if (releaseDate)                     status = 'released';

  const rawGender = String(get('gender') || '').trim().toUpperCase();
  const gender = rawGender === 'F' || rawGender === 'FEMALE' ? 'female'
               : rawGender === 'M' || rawGender === 'MALE'   ? 'male'
               : 'other';

  const age = parseInt(get('age'), 10) || 0;

  return {
    prisonerId:    String(get('prisonerId')).trim(),
    name:          String(get('name')).trim(),
    age,
    gender,
    firNumber:     String(get('firNumber') || '').trim(),
    crimeNumber:   String(get('crimeNumber') || '').trim(),
    policeStation: String(get('policeStation') || '').trim(),
    prisonName:    String(get('prisonName') || '').trim(),
    admissionDate: admissionDate.toISOString(),
    status,
    ipcSections:   sections,
    bnsSections:   [],
    releaseDate:   releaseDate ? releaseDate.toISOString() : null,
    releaseReason: releaseDate ? 'other' : null,
    remarks:       remarkParts.join(' | ') || null,
  };
}

function parseDate(val) {
  if (!val) return null;
  if (val instanceof Date) return isNaN(val) ? null : val;

  const s = String(val).trim();
  if (!s) return null;

  // DD-MM-YYYY or DD/MM/YYYY
  const dmy = s.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$/);
  if (dmy) return new Date(`${dmy[3]}-${dmy[2].padStart(2,'0')}-${dmy[1].padStart(2,'0')}T00:00:00Z`);

  // ISO
  const d = new Date(s);
  if (!isNaN(d)) return d;

  // Excel serial number
  const n = Number(s);
  if (!isNaN(n) && n > 10000) {
    return new Date(Math.round((n - 25569) * 86400 * 1000));
  }

  return null;
}

module.exports = { parseExcel };
