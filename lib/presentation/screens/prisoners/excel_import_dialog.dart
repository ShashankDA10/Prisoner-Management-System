import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/prisoner_model.dart';
import '../../providers/prisoner_provider.dart';

class ExcelImportDialog extends ConsumerStatefulWidget {
  const ExcelImportDialog({super.key});

  @override
  ConsumerState<ExcelImportDialog> createState() => _State();
}

class _State extends ConsumerState<ExcelImportDialog> {
  int _step = 0; // 0=select, 1=preview, 2=result
  List<PrisonerModel> _preview = [];
  Map<String, int>? _result;
  String? _error;
  bool _loading = false;
  bool _updateExisting = false;
  bool _skipDuplicates = true;
  String _fileName = '';

  // ── Column mapping ──────────────────────────────────────────────────────────

  static String _norm(String h) => h
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static String? _mapCol(String n) => const {
    'jid':               'prisoner_id',
    'prisoner_id':       'prisoner_id',
    'id':                'prisoner_id',
    'prisoner_name':     'name',
    'name':              'name',
    'father_name':       'father_name',
    'father':            'father_name',
    'gender':            'gender',
    'age':               'age',
    'fir_case_no':       'fir_number',
    'fir_no':            'fir_number',
    'fir_number':        'fir_number',
    'case_no':           'crime_number',
    'case_number':       'crime_number',
    'ps_name':           'police_station',
    'police_station':    'police_station',
    'ps':                'police_station',
    'permanent_address': 'address',
    'address':           'address',
    'admission_date':         'admission_date',
    'latest_admission_date':  'admission_date',
    'date_of_admission':      'admission_date',
    'admitted_on':            'admission_date',
    'release_date':           'release_date',
    'date_of_release':        'release_date',
    'released_on':            'release_date',
    'act_section':       'act_section',
    'ipc_sections':      'act_section',
    'bns_sections':      'act_section',
    'court_name':        'court_name',
    'court':             'court_name',
    'crime_number':      'crime_number',
    'prison_name':       'prison_name',
    'status':            'status',
    'remarks':           'remarks',
  }[n];

  // ── File parsers ────────────────────────────────────────────────────────────

  /// Parse an xlsx/xls file → rows of string values.
  static List<List<String>> _parseExcel(Uint8List bytes) {
    final wb    = Excel.decodeBytes(bytes);
    final sheet = wb.sheets.values.first;
    return sheet.rows
        .map((r) => r.map((c) => c?.value?.toString().trim() ?? '').toList())
        .toList();
  }

  /// Parse a CSV file → rows of string values (handles quoted fields & BOM).
  static List<List<String>> _parseCSV(Uint8List bytes) {
    // Strip UTF-8 BOM
    final raw = (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF)
        ? bytes.sublist(3)
        : bytes;
    final text  = utf8.decode(raw, allowMalformed: true);
    final lines = text.split(RegExp(r'\r\n|\r|\n'));
    return lines.where((l) => l.trim().isNotEmpty).map(_csvLine).toList();
  }

  static List<String> _csvLine(String line) {
    final cells  = <String>[];
    final buf    = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        cells.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    cells.add(buf.toString().trim());
    return cells;
  }

  // ── Date / gender helpers ───────────────────────────────────────────────────

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    // DD-MM-YYYY or DD/MM/YYYY
    final m = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(s);
    if (m != null) {
      try {
        return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
      } catch (_) {}
    }
    // Excel serial date
    final serial = double.tryParse(s);
    if (serial != null && serial > 1000) {
      return DateTime(1899, 12, 30).add(Duration(days: serial.toInt()));
    }
    return null;
  }

  static Gender _parseGender(String s) {
    final n = s.toLowerCase().trim();
    if (n == 'f' || n == 'female') return Gender.female;
    return Gender.male;
  }

  // ── Main pick & parse ───────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() { _error = null; _loading = true; });

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true, // loads bytes on desktop too
    );

    if (picked == null || picked.files.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    _fileName = picked.files.first.name;

    // Get bytes: prefer withData result, fall back to path on desktop
    Uint8List? bytes = picked.files.first.bytes;
    if (bytes == null && !kIsWeb) {
      final path = picked.files.first.path;
      if (path != null) {
        try {
          bytes = await File(path).readAsBytes();
        } catch (e) {
          setState(() { _loading = false; _error = 'Cannot read file: $e'; });
          return;
        }
      }
    }

    if (bytes == null) {
      setState(() { _loading = false; _error = 'Could not read file. Try copying it to a local folder first.'; });
      return;
    }

    try {
      final isCSV = _fileName.toLowerCase().endsWith('.csv');
      final rows  = isCSV ? _parseCSV(bytes) : _parseExcel(bytes);

      if (rows.isEmpty) {
        setState(() { _loading = false; _error = 'File is empty.'; });
        return;
      }

      // Build header → column-index map
      final rawHeaders = rows.first;
      final fieldIndex = <String, int>{};
      for (int i = 0; i < rawHeaders.length; i++) {
        final key = _mapCol(_norm(rawHeaders[i]));
        if (key != null && !fieldIndex.containsKey(key)) fieldIndex[key] = i;
      }

      // Minimum required columns
      const required = ['prisoner_id', 'name', 'admission_date'];
      final missing  = required.where((f) => !fieldIndex.containsKey(f)).toList();
      if (missing.isNotEmpty) {
        setState(() {
          _loading = false;
          _error = 'Missing required columns: ${missing.join(", ")}.\n'
              'Detected columns: ${rawHeaders.where((h) => h.isNotEmpty).join(", ")}';
        });
        return;
      }

      String cell(String field, List<String> row) {
        final i = fieldIndex[field];
        if (i == null || i >= row.length) return '';
        return row[i];
      }

      final now     = DateTime.now();
      final records = <PrisonerModel>[];

      for (final row in rows.skip(1)) {
        if (row.every((c) => c.isEmpty)) continue;

        final prisonerId = cell('prisoner_id', row);
        final name       = cell('name', row);
        if (prisonerId.isEmpty && name.isEmpty) continue;

        final releaseDate   = _parseDate(cell('release_date', row));
        final statusStr     = cell('status', row).toLowerCase();
        PrisonerStatus status;
        if (statusStr.isNotEmpty) {
          status = PrisonerStatus.values.firstWhere(
              (e) => e.name == statusStr, orElse: () => PrisonerStatus.undertrial);
        } else {
          status = releaseDate != null ? PrisonerStatus.released : PrisonerStatus.undertrial;
        }

        // Merge extra fields into remarks
        final parts      = <String>[];
        final fatherName = cell('father_name', row);
        final address    = cell('address', row);
        final courtName  = cell('court_name', row);
        final extraNote  = cell('remarks', row);
        if (fatherName.isNotEmpty) parts.add('Father: $fatherName');
        if (address.isNotEmpty)    parts.add('Address: $address');
        if (courtName.isNotEmpty)  parts.add('Court: $courtName');
        if (extraNote.isNotEmpty)  parts.add(extraNote);

        final actRaw   = cell('act_section', row);
        final sections = actRaw.isEmpty
            ? <String>[]
            : actRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final firNumber = cell('fir_number', row);

        records.add(PrisonerModel(
          id:            const Uuid().v4(),
          prisonerId:    prisonerId.isNotEmpty ? prisonerId : const Uuid().v4().substring(0, 8),
          name:          name,
          age:           int.tryParse(cell('age', row)) ?? 0,
          gender:        _parseGender(cell('gender', row)),
          firNumber:     firNumber,
          crimeNumber:   cell('crime_number', row).isNotEmpty ? cell('crime_number', row) : firNumber,
          policeStation: cell('police_station', row),
          prisonName:    cell('prison_name', row),
          admissionDate: _parseDate(cell('admission_date', row)) ?? now,
          status:        status,
          ipcSections:   sections,
          releaseDate:   releaseDate,
          remarks:       parts.isEmpty ? null : parts.join(' | '),
          createdAt:     now,
          updatedAt:     now,
        ));
      }

      if (records.isEmpty) {
        setState(() { _loading = false; _error = 'No valid records found in the file.'; });
        return;
      }
      setState(() { _preview = records; _step = 1; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Parse error: $e'; });
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    setState(() => _loading = true);

    // Station-scoped users cannot import records under a different station.
    // Override every record's policeStation with the user's assigned station.
    final scope = ref.read(stationScopeProvider);
    final records = scope != null
        ? _preview.map((p) => p.copyWith(policeStation: scope)).toList()
        : _preview;

    final result = await ref.read(prisonerNotifierProvider.notifier).bulkImport(
      records,
      updateExisting: _updateExisting,
      skipDuplicates: _skipDuplicates,
    );
    setState(() { _result = result; _step = 2; _loading = false; });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.upload_file_outlined, size: 20),
        const SizedBox(width: 8),
        const Text('Import from Excel / CSV'),
        const Spacer(),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ]),
      content: SizedBox(
        width: 640,
        child: switch (_step) {
          0 => _selectStep(),
          1 => _previewStep(),
          _ => _resultStep(),
        },
      ),
      actions: switch (_step) {
        0 => [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Select File'),
            onPressed: _loading ? null : _pickFile,
          ),
        ],
        1 => [
          TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Back')),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload, size: 16),
            label: Text('Import ${_preview.length} Records'),
            onPressed: _loading ? null : _import,
          ),
        ],
        _ => [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      },
    );
  }

  Widget _selectStep() => Column(mainAxisSize: MainAxisSize.min, children: [
    if (_error != null) ...[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 16),
    ],
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Column(children: [
        Icon(Icons.table_chart_outlined, size: 40, color: AppTheme.textSecondary),
        SizedBox(height: 12),
        Text('Select an Excel (.xlsx) or CSV file',
            style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 10),
        Text('Supported column names (case-insensitive):',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        SizedBox(height: 6),
        Text(
          'JID · Prisoner Name · Father Name · Gender · Age\n'
          'FIR/Case No · PS Name · Permanent Address\n'
          'Admission Date · Release Date · Act Section · Court Name',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text('Required: JID, Prisoner Name, Admission Date',
            style: TextStyle(fontSize: 11, color: AppTheme.textDisabled)),
        SizedBox(height: 4),
        Text('Date format: DD-MM-YYYY or YYYY-MM-DD',
            style: TextStyle(fontSize: 11, color: AppTheme.textDisabled)),
      ]),
    ),
    const SizedBox(height: 16),
    Row(children: [
      Checkbox(value: _updateExisting, onChanged: (v) => setState(() => _updateExisting = v ?? false)),
      const Text('Update existing records'),
      const SizedBox(width: 16),
      Checkbox(value: _skipDuplicates, onChanged: (v) => setState(() => _skipDuplicates = v ?? true)),
      const Text('Skip duplicates'),
    ]),
  ]);

  Widget _previewStep() {
    final scope = ref.read(stationScopeProvider);
    return Column(mainAxisSize: MainAxisSize.min, children: [
    Text('Preview — ${_preview.length} records from $_fileName',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    if (scope != null)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 14, color: AppTheme.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Police station will be set to "$scope" for all imported records.',
              style: const TextStyle(fontSize: 12, color: AppTheme.info),
            ),
          ),
        ]),
      ),
    const SizedBox(height: 12),
    SizedBox(
      height: 320,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('JID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('PS')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Admitted')),
              DataColumn(label: Text('Released')),
            ],
            rows: _preview.take(50).map((p) => DataRow(cells: [
              DataCell(Text(p.prisonerId, style: const TextStyle(fontSize: 11))),
              DataCell(Text(p.name)),
              DataCell(Text(p.policeStation)),
              DataCell(Text(p.status.label)),
              DataCell(Text('${p.admissionDate.day}/${p.admissionDate.month}/${p.admissionDate.year}')),
              DataCell(Text(p.releaseDate != null
                  ? '${p.releaseDate!.day}/${p.releaseDate!.month}/${p.releaseDate!.year}'
                  : '—')),
            ])).toList(),
          ),
        ),
      ),
    ),
    if (_preview.length > 50)
      Text('(showing first 50 of ${_preview.length})',
          style: const TextStyle(fontSize: 11, color: AppTheme.textDisabled)),
    ]);
  }

  Widget _resultStep() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.success),
    const SizedBox(height: 12),
    const Text('Import Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 20),
    _resultRow('Inserted', _result?['inserted'] ?? 0, AppTheme.success),
    _resultRow('Updated',  _result?['updated']  ?? 0, AppTheme.info),
    _resultRow('Skipped',  _result?['skipped']  ?? 0, AppTheme.warning),
  ]);

  Widget _resultRow(String label, int count, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]),
  );
}
