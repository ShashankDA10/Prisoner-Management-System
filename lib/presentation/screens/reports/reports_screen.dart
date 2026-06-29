import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xl;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
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

  List<PrisonerModel> _forType(List<PrisonerModel> all) => switch (_type) {
    ReportType.stationWise => all,
    ReportType.prisonWise  => all,
    ReportType.admitted    => all.where((p) =>
        p.status == PrisonerStatus.undertrial ||
        p.status == PrisonerStatus.convicted).toList(),
    ReportType.released    => all.where((p) =>
        p.status == PrisonerStatus.released ||
        p.status == PrisonerStatus.bail).toList(),
    ReportType.bail        => all.where((p) => p.status == PrisonerStatus.bail).toList(),
  };

  void _drillStation(String station) {
    ref.read(stationFilterProvider.notifier).state = station;
    ref.read(statusFilterProvider.notifier).state  = null;
    context.go(Routes.prisoners);
  }

  @override
  Widget build(BuildContext context) {
    final prisonersAsync = ref.watch(allPrisonersProvider);

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return PageWrapper(
      title: 'Reports',
      subtitle: 'Generate and export prisoner reports',
      scrollable: isMobile,
      child: prisonersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (all) {
          final filtered = _forType(all);
          return _Content(
            all:       all,
            filtered:  filtered,
            type:      _type,
            onTypeChanged: (t) => setState(() => _type = t),
            generating: _generating,
            onGeneratePdf:   () => _generatePdf(filtered),
            onGenerateExcel: () => _generateExcel(filtered),
            onStationTap:    _drillStation,
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(List<PrisonerModel> data) async {
    setState(() => _generating = true);
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      header: (ctx) => pw.Column(children: [
        pw.Text('PRISONER & UNDERTRIAL MONITORING SYSTEM',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Karnataka State Police — ${_type.label} Report',
            style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Generated: ${DateTime.now().displayDateTime}',
            style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(),
      ]),
      build: (ctx) => [
        pw.TableHelper.fromTextArray(
          headers: ['Prisoner ID', 'Name', 'Age', 'Police Station', 'Prison', 'Admitted', 'Status'],
          data: data.map((p) => [
            p.prisonerId, p.name, '${p.age}', p.policeStation,
            p.prisonName, p.admissionDate.displayDate, p.status.label,
          ]).toList(),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          headerDecoration:     const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3A5C)),
          headerCellDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3A5C)),
          oddRowDecoration:     const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF4F6F8)),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Total Records: ${data.length}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _generateExcel(List<PrisonerModel> data) async {
    setState(() => _generating = true);
    final excel  = xl.Excel.createExcel();
    final sheet  = excel['Report'];
    final headers = [
      'Prisoner ID', 'Name', 'Age', 'Gender', 'FIR Number', 'Crime Number',
      'Police Station', 'Prison', 'Admission Date', 'Status',
      'IPC Sections', 'BNS Sections', 'Release Date', 'Release Reason',
    ];
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel report generated')));
    }
  }
}

// ── Content ──────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  final List<PrisonerModel> all;
  final List<PrisonerModel> filtered;
  final ReportType type;
  final void Function(ReportType) onTypeChanged;
  final bool generating;
  final VoidCallback onGeneratePdf;
  final VoidCallback onGenerateExcel;
  final void Function(String station) onStationTap;

  const _Content({
    required this.all,
    required this.filtered,
    required this.type,
    required this.onTypeChanged,
    required this.generating,
    required this.onGeneratePdf,
    required this.onGenerateExcel,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final byStation = <String, int>{};
    final byPrison  = <String, int>{};
    for (final p in filtered) {
      if (p.policeStation.isNotEmpty) byStation[p.policeStation] = (byStation[p.policeStation] ?? 0) + 1;
      if (p.prisonName.isNotEmpty)    byPrison[p.prisonName]     = (byPrison[p.prisonName]     ?? 0) + 1;
    }

    final configPanel = _ConfigPanel(
      type: type,
      onTypeChanged: onTypeChanged,
      filtered: filtered,
      all: all,
      generating: generating,
      onGeneratePdf: onGeneratePdf,
      onGenerateExcel: onGenerateExcel,
      isMobile: isMobile,
    );

    final summaryPanels = [
      _SummaryCard(
        title: 'By Police Station',
        data: byStation,
        onRowTap: onStationTap,
        tapTooltip: 'Tap to view prisoners from this station',
      ),
      _SummaryCard(title: 'By Prison', data: byPrison),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          configPanel,
          const SizedBox(height: Spacing.md),
          ...summaryPanels.expand((w) => [w, const SizedBox(height: Spacing.md)]),
          _StatusSummary(prisoners: all, isMobile: true),
          const SizedBox(height: Spacing.md),
        ],
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 260, child: configPanel),
      const SizedBox(width: Spacing.md),
      Expanded(
        child: Column(children: [
          Row(children: [
            Expanded(child: summaryPanels[0]),
            const SizedBox(width: Spacing.md),
            Expanded(child: summaryPanels[1]),
          ]),
          const SizedBox(height: Spacing.md),
          _StatusSummary(prisoners: all, isMobile: false),
        ]),
      ),
    ]);
  }
}

// ── Config panel ─────────────────────────────────────────────────────────────

class _ConfigPanel extends StatelessWidget {
  final ReportType type;
  final void Function(ReportType) onTypeChanged;
  final List<PrisonerModel> filtered;
  final List<PrisonerModel> all;
  final bool generating;
  final VoidCallback onGeneratePdf;
  final VoidCallback onGenerateExcel;
  final bool isMobile;

  const _ConfigPanel({
    required this.type,
    required this.onTypeChanged,
    required this.filtered,
    required this.all,
    required this.generating,
    required this.onGeneratePdf,
    required this.onGenerateExcel,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Report Type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),

        // Radio tiles — larger touch targets on mobile (no dense, minimal padding).
        RadioGroup<ReportType>(
          groupValue: type,
          onChanged: (v) { if (v != null) onTypeChanged(v); },
          child: Column(
            children: ReportType.values.map((t) => RadioListTile<ReportType>(
              value: t,
              title: Text(t.label, style: const TextStyle(fontSize: 13)),
              contentPadding: isMobile
                  ? const EdgeInsets.symmetric(horizontal: 4)
                  : EdgeInsets.zero,
              dense: !isMobile,
              visualDensity: isMobile
                  ? VisualDensity.standard
                  : VisualDensity.compact,
            )).toList(),
          ),
        ),

        const SizedBox(height: 4),
        const Text('Showing:',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        Text(
          '${filtered.length} of ${all.length} records',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
        ),

        const Divider(height: 24),
        const Text('Export',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 12),

        // Always stacked vertically — full width is achieved by
        // CrossAxisAlignment.stretch on the parent Column.
        ElevatedButton.icon(
          icon: generating
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf_outlined, size: 16),
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
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final void Function(String)? onRowTap;
  final String? tapTooltip;

  const _SummaryCard({
    required this.title,
    required this.data,
    this.onRowTap,
    this.tapTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryNavy)),
          if (onRowTap != null) ...[
            const SizedBox(width: 6),
            const Tooltip(
              message: 'Tap a row to filter prisoners',
              child: Icon(Icons.touch_app_outlined, size: 13, color: AppTheme.textDisabled),
            ),
          ],
        ]),
        const Divider(height: 16),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No data', style: TextStyle(fontSize: 12, color: AppTheme.textDisabled)),
          )
        else
          ...sorted.take(10).map((e) {
            final row = Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(e.key.isEmpty ? '(unknown)' : e.key,
                    style: const TextStyle(fontSize: 12))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primaryNavy)),
                ),
              ]),
            );

            if (onRowTap == null || e.key.isEmpty) return row;
            return InkWell(
              onTap: () => onRowTap!(e.key),
              borderRadius: BorderRadius.circular(4),
              hoverColor: AppTheme.primaryNavy.withValues(alpha: 0.04),
              child: row,
            );
          }),
      ]),
    );
  }
}

// ── Status summary ────────────────────────────────────────────────────────────

class _StatusSummary extends StatelessWidget {
  final List<PrisonerModel> prisoners;
  final bool isMobile;
  const _StatusSummary({required this.prisoners, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final counts = <PrisonerStatus, int>{};
    for (final p in prisoners) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Summary (all records)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryNavy)),
        const Divider(height: 16),

        if (isMobile)
          // GridView avoids the overflow from manual fixed-width tile calculations.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
            childAspectRatio: 2.2,
            children: PrisonerStatus.values
                .map((s) => _statusTile(s, counts[s] ?? 0))
                .toList(),
          )
        else
          Row(
            children: PrisonerStatus.values.map((s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _statusTile(s, counts[s] ?? 0),
              ),
            )).toList(),
          ),
      ]),
    );
  }

  Widget _statusTile(PrisonerStatus s, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.surfaceGrey, borderRadius: BorderRadius.circular(6)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          '$count',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy),
        ),
        const SizedBox(height: 2),
        Text(
          s.label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }
}
