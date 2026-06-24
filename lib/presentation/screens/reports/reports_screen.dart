import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xl;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/prisoner_model.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _State();
}

class _State extends ConsumerState<ReportsScreen> {
  ReportType _type = ReportType.stationWise;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final prisonersAsync = ref.watch(allPrisonersProvider);

    return PageWrapper(
      title: 'Reports',
      subtitle: 'Generate and export prisoner reports',
      child: prisonersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (prisoners) => _Content(
          prisoners: prisoners,
          type: _type,
          onTypeChanged: (t) => setState(() => _type = t),
          generating: _generating,
          onGeneratePdf: () => _generatePdf(prisoners),
          onGenerateExcel: () => _generateExcel(prisoners),
        ),
      ),
    );
  }

  List<PrisonerModel> _filtered(List<PrisonerModel> all) => switch (_type) {
    ReportType.stationWise => all,
    ReportType.prisonWise  => all,
    ReportType.admitted    => all,
    ReportType.released    => all.where((p) => p.status == PrisonerStatus.released || p.status == PrisonerStatus.bail).toList(),
    ReportType.bail        => all.where((p) => p.status == PrisonerStatus.bail).toList(),
  };

  Future<void> _generatePdf(List<PrisonerModel> all) async {
    setState(() => _generating = true);
    final data = _filtered(all);
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      header: (ctx) => pw.Column(children: [
        pw.Text('PRISONER & UNDERTRIAL MONITORING SYSTEM', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Karnataka State Police — ${_type.label} Report', style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Generated: ${DateTime.now().displayDateTime}', style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(),
      ]),
      build: (ctx) => [
        pw.TableHelper.fromTextArray(
          headers: ['Prisoner ID', 'Name', 'Age', 'Police Station', 'Prison', 'Admitted', 'Status'],
          data: data.map((p) => [p.prisonerId, p.name, '${p.age}', p.policeStation, p.prisonName, p.admissionDate.displayDate, p.status.label]).toList(),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3A5C)),
          headerCellDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3A5C)),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF4F6F8)),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Total Records: ${data.length}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _generateExcel(List<PrisonerModel> all) async {
    setState(() => _generating = true);
    final data = _filtered(all);
    final excel = xl.Excel.createExcel();
    final sheet = excel['Report'];
    final headers = ['Prisoner ID', 'Name', 'Age', 'Gender', 'FIR Number', 'Crime Number', 'Police Station', 'Prison', 'Admission Date', 'Status', 'IPC Sections', 'BNS Sections', 'Release Date', 'Release Reason'];
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());
    for (final p in data) {
      sheet.appendRow([
        xl.TextCellValue(p.prisonerId), xl.TextCellValue(p.name), xl.IntCellValue(p.age),
        xl.TextCellValue(p.gender.label), xl.TextCellValue(p.firNumber), xl.TextCellValue(p.crimeNumber),
        xl.TextCellValue(p.policeStation), xl.TextCellValue(p.prisonName),
        xl.TextCellValue(p.admissionDate.displayDate), xl.TextCellValue(p.status.label),
        xl.TextCellValue(p.ipcSections.join(', ')), xl.TextCellValue(p.bnsSections.join(', ')),
        xl.TextCellValue(p.releaseDate?.displayDate ?? ''), xl.TextCellValue(p.releaseReason?.label ?? ''),
      ]);
    }
    if (mounted) setState(() => _generating = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel report generated (save via print dialog on web)')));
  }
}

class _Content extends StatelessWidget {
  final List<PrisonerModel> prisoners;
  final ReportType type;
  final void Function(ReportType) onTypeChanged;
  final bool generating;
  final VoidCallback onGeneratePdf;
  final VoidCallback onGenerateExcel;

  const _Content({
    required this.prisoners, required this.type, required this.onTypeChanged,
    required this.generating, required this.onGeneratePdf, required this.onGenerateExcel,
  });

  @override
  Widget build(BuildContext context) {
    // Summary by station
    final byStation = <String, int>{};
    final byPrison  = <String, int>{};
    for (final p in prisoners) {
      byStation[p.policeStation] = (byStation[p.policeStation] ?? 0) + 1;
      byPrison[p.prisonName]     = (byPrison[p.prisonName]    ?? 0) + 1;
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Config panel
      SizedBox(
        width: 260,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Report Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            ...ReportType.values.map((t) => RadioListTile<ReportType>(
              value: t, groupValue: type, title: Text(t.label, style: const TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero, dense: true,
              onChanged: (v) => onTypeChanged(v!),
            )),
            const Divider(height: 24),
            const Text('Export', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: generating ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Export PDF'),
              onPressed: generating ? null : onGeneratePdf,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text('Export Excel'),
              onPressed: generating ? null : onGenerateExcel,
            ),
          ]),
        ),
      ),
      const SizedBox(width: Spacing.md),

      // Summary tables
      Expanded(child: Column(children: [
        Row(children: [
          Expanded(child: _summaryCard('By Police Station', byStation)),
          const SizedBox(width: Spacing.md),
          Expanded(child: _summaryCard('By Prison', byPrison)),
        ]),
        const SizedBox(height: Spacing.md),
        _statusSummary(prisoners),
      ])),
    ]);
  }

  Widget _summaryCard(String title, Map<String, int> data) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryNavy)),
        const Divider(height: 16),
        ...sorted.take(10).map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primaryNavy)),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _statusSummary(List<PrisonerModel> all) {
    final counts = <PrisonerStatus, int>{};
    for (final p in all) counts[p.status] = (counts[p.status] ?? 0) + 1;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryNavy)),
        const Divider(height: 16),
        Row(children: PrisonerStatus.values.map((s) {
          final count = counts[s] ?? 0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surfaceGrey, borderRadius: BorderRadius.circular(6)),
              child: Column(children: [
                Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
                const SizedBox(height: 2),
                Text(s.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
              ]),
            ),
          ));
        }).toList()),
      ]),
    );
  }
}
