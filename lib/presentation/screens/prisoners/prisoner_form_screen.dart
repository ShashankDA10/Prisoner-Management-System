import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/prisoner_model.dart';
import '../../../data/repositories/prisoner_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prisoner_provider.dart';
import '../../providers/section_provider.dart';
import '../../widgets/common/page_wrapper.dart';
import 'widgets/section_picker.dart';

class PrisonerFormScreen extends ConsumerStatefulWidget {
  final String? prisonerId;
  const PrisonerFormScreen({super.key, this.prisonerId});

  @override
  ConsumerState<PrisonerFormScreen> createState() => _PrisonerFormScreenState();
}

class _PrisonerFormScreenState extends ConsumerState<PrisonerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  PrisonerModel? _existing;

  // controllers
  final _pidCtrl    = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController();
  final _firCtrl    = TextEditingController();
  final _crimeCtrl  = TextEditingController();
  final _psCtrl     = TextEditingController();
  final _prisonCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  Gender _gender = Gender.male;
  PrisonerStatus _status = PrisonerStatus.undertrial;
  DateTime _admissionDate = DateTime.now();
  DateTime? _releaseDate;
  ReleaseReason? _releaseReason;
  List<String> _ipcSections = [];
  List<String> _bnsSections = [];

  bool get _isEdit => widget.prisonerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final repo = ref.read(prisonerRepositoryProvider);
    final p = await repo.getById(widget.prisonerId!);
    if (p == null || !mounted) { setState(() => _loading = false); return; }
    _existing = p;
    _pidCtrl.text    = p.prisonerId;
    _nameCtrl.text   = p.name;
    _ageCtrl.text    = p.age.toString();
    _firCtrl.text    = p.firNumber;
    _crimeCtrl.text  = p.crimeNumber;
    _psCtrl.text     = p.policeStation;
    _prisonCtrl.text = p.prisonName;
    _remarkCtrl.text = p.remarks ?? '';
    _gender          = p.gender;
    _status          = p.status;
    _admissionDate   = p.admissionDate;
    _releaseDate     = p.releaseDate;
    _releaseReason   = p.releaseReason;
    _ipcSections     = List.from(p.ipcSections);
    _bnsSections     = List.from(p.bnsSections);
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_pidCtrl, _nameCtrl, _ageCtrl, _firCtrl, _crimeCtrl, _psCtrl, _prisonCtrl, _remarkCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = ref.read(authProvider);
    final now = DateTime.now();

    final model = PrisonerModel(
      id:            _existing?.id ?? const Uuid().v4(),
      prisonerId:    _pidCtrl.text.trim(),
      name:          _nameCtrl.text.trim(),
      age:           int.tryParse(_ageCtrl.text.trim()) ?? 0,
      gender:        _gender,
      firNumber:     _firCtrl.text.trim(),
      crimeNumber:   _crimeCtrl.text.trim(),
      policeStation: _psCtrl.text.trim(),
      prisonName:    _prisonCtrl.text.trim(),
      admissionDate: _admissionDate,
      status:        _status,
      ipcSections:   _ipcSections,
      bnsSections:   _bnsSections,
      releaseDate:   _releaseDate,
      releaseReason: _releaseReason,
      remarks:       _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
      createdAt:     _existing?.createdAt ?? now,
      updatedAt:     now,
      createdBy:     _existing?.createdBy ?? user.value?.id ?? '',
    );

    final notifier = ref.read(prisonerNotifierProvider.notifier);
    if (_isEdit) {
      await notifier.updatePrisoner(model);
    } else {
      await notifier.addPrisoner(model);
    }

    if (mounted) context.go(Routes.prisoners);
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: _isEdit ? 'Edit Prisoner' : 'Add New Prisoner',
      subtitle: _isEdit ? 'Update prisoner information' : 'Enter prisoner details',
      scrollable: true,
      actions: [
        OutlinedButton(onPressed: () => context.go(Routes.prisoners), child: const Text('Cancel')),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: _loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined, size: 16),
          label: Text(_isEdit ? 'Update' : 'Save'),
          onPressed: _loading ? null : _save,
        ),
      ],
      child: _loading && _isEdit
          ? const LoadingState()
          : Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Section('Identification', children: [
                  _row([
                    _field('Prisoner ID *', _pidCtrl, hint: 'KSP/BLR/2024/001'),
                    _field('Full Name *', _nameCtrl),
                    _field('Age *', _ageCtrl, numeric: true),
                    _dropdown('Gender *', Gender.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                        _gender, (v) => setState(() => _gender = v!)),
                  ]),
                ]),
                const SizedBox(height: 20),
                _Section('Case Information', children: [
                  _row([
                    _field('FIR Number *', _firCtrl, hint: 'CR No. 45/2024'),
                    _field('Crime Number *', _crimeCtrl, hint: 'SC No. 112/2024'),
                    _field('Police Station *', _psCtrl, hint: 'Cubbon Park PS'),
                    _field('Prison Name *', _prisonCtrl, hint: 'Parappana Agrahara Central Prison'),
                  ]),
                ]),
                const SizedBox(height: 20),
                _Section('Admission & Status', children: [
                  _row([
                    _datePicker('Admission Date *', _admissionDate, (d) => setState(() => _admissionDate = d)),
                    _dropdown('Current Status *', PrisonerStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                        _status, (v) => setState(() => _status = v!)),
                    if (_status == PrisonerStatus.released || _status == PrisonerStatus.bail) ...[
                      _datePicker('Release Date', _releaseDate, (d) => setState(() => _releaseDate = d), required: false),
                      _dropdown('Release Reason', ReleaseReason.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                          _releaseReason, (v) => setState(() => _releaseReason = v), required: false),
                    ],
                  ]),
                ]),
                const SizedBox(height: 20),
                _Section('IPC / BNS Sections', children: [
                  SectionPicker(
                    selectedIpc: _ipcSections,
                    selectedBns: _bnsSections,
                    onChanged: (ipc, bns) => setState(() { _ipcSections = ipc; _bnsSections = bns; }),
                  ),
                ]),
                const SizedBox(height: 20),
                _Section('Remarks', children: [
                  TextFormField(
                    controller: _remarkCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Any additional remarks or notes...'),
                  ),
                ]),
              ]),
            ),
    );
  }

  Widget _Section(String title, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
        const SizedBox(height: 4),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(builder: (_, constraints) {
      if (constraints.maxWidth > 800) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
        );
      }
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    });
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, bool numeric = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required ? (v) => v?.trim().isEmpty == true ? '$label is required' : null : null,
      ),
    );
  }

  Widget _dropdown<T>(String label, List<DropdownMenuItem<T>> items, T value, void Function(T?) onChanged, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null ? '$label is required' : null : null,
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, void Function(DateTime) onChanged, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(text: value?.displayDate ?? ''),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(d);
        },
        validator: required ? (v) => v?.isEmpty == true ? '$label is required' : null : null,
      ),
    );
  }
}
