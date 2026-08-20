import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';

/// РЎС‚СЂР°РЅРёС†Р° СЃРѕР·РґР°РЅРёСЏ/СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ Р·Р°РїРёСЃРё.
class AppointmentCreateScreen extends ConsumerStatefulWidget {
  final List<Bay> bays;
  final List<Vehicle> vehicles;
  final DateTime initialDate;
  final models.Appointment? existingAppointment;

  const AppointmentCreateScreen({
    super.key,
    required this.bays,
    required this.vehicles,
    required this.initialDate,
    this.existingAppointment,
  });

  @override
  ConsumerState<AppointmentCreateScreen> createState() =>
      _AppointmentCreateScreenState();
}

class _AppointmentCreateScreenState
    extends ConsumerState<AppointmentCreateScreen> {
  late DateTime _startAt;
  late DateTime _endAt;
  String _bayId = '';
  String _vehicleId = '';
  String _status = 'planned';

  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _clientNameCtrl;
  late final TextEditingController _clientPhoneCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _noteCtrl;

  bool get _isEdit => widget.existingAppointment != null;

  static const _fieldSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAppointment;
    _startAt = a?.startAt ?? widget.initialDate;
    _endAt = a?.endAt ?? widget.initialDate.add(const Duration(hours: 1));
    _bayId = a?.bayId ?? (widget.bays.isNotEmpty ? widget.bays.first.id : '');
    _vehicleId = a?.vehicleId ?? '';
    _status = a?.status ?? 'planned';

    _makeCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _clientNameCtrl = TextEditingController();
    _clientPhoneCtrl = TextEditingController();
    _reasonCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    if (a != null) {
      final noteParts = a.note.split(' | ');
      if (noteParts.isNotEmpty) _reasonCtrl.text = noteParts[0];
      if (noteParts.length > 1) _noteCtrl.text = noteParts.sublist(1).join(' | ');

      // РС‰РµРј Р°РІС‚Рѕ РІ РєР°С‚Р°Р»РѕРіРµ. Р•СЃР»Рё РЅР°Р№РґРµРЅРѕ вЂ” СЌС‚Рѕ СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РµРµ Р°РІС‚Рѕ,
      // РїРѕР»СЏ "РґР»СЏ РЅРѕРІРѕРіРѕ Р°РІС‚Рѕ" РѕСЃС‚Р°РІР»СЏРµРј РџРЈРЎРўР«РњР (fix: РґСѓР±Р»РёРєР°С‚С‹ РІ РєР°С‚Р°Р»РѕРіРµ).
      // Р•СЃР»Рё РќР• РЅР°Р№РґРµРЅРѕ (edge case) вЂ” Р·Р°РїРѕР»РЅСЏРµРј РїРѕР»СЏ РёР· appt.
      final vIdx = widget.vehicles.indexWhere((v) => v.id == a.vehicleId);
      if (vIdx >= 0) {
        // РђРІС‚Рѕ СѓР¶Рµ РІ РєР°С‚Р°Р»РѕРіРµ вЂ” РЅРёС‡РµРіРѕ РЅРµ РґСѓР±Р»РёСЂСѓРµРј РІ РїРѕР»СЏ
        _makeCtrl.text = '';
        _modelCtrl.text = '';
        _clientNameCtrl.text = '';
        _clientPhoneCtrl.text = '';
      } else {
        // РђРІС‚Рѕ РЅРµ РІ РєР°С‚Р°Р»РѕРіРµ (legacy/orphaned) вЂ” Р·Р°РїРѕР»РЅСЏРµРј РїРѕР»СЏ РєР°Рє "РЅРѕРІРѕРµ"
        _makeCtrl.text = '';
        _modelCtrl.text = '';
        _clientNameCtrl.text = '';
        _clientPhoneCtrl.text = '';
      }
    }
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _reasonCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDateTime => _startAt;

  DateTime get _endDateTime => _endAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit : Icons.add_circle,
                    size: 22,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit ? 'РР·РјРµРЅРёС‚СЊ Р·Р°РїРёСЃСЊ' : 'РќРѕРІР°СЏ Р·Р°РїРёСЃСЊ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOf(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, size: 18, color: AppTheme.primary),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('РќР°С‡Р°Р»Рѕ'),
                    Row(
                      children: [
                        Expanded(child: _dateTile(_startAt, isStart: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _timeTile(_startAt, isStart: true)),
                      ],
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РљРѕРЅРµС†'),
                    Row(
                      children: [
                        Expanded(child: _dateTile(_endAt, isStart: false)),
                        const SizedBox(width: 8),
                        Expanded(child: _timeTile(_endAt, isStart: false)),
                      ],
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РџРѕСЃС‚'),
                    DropdownMenu<String>(
                      width: 300,
                      initialSelection: _bayId.isEmpty ? null : _bayId,
                      onSelected: (v) => setState(() => _bayId = v ?? ''),
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textOf(context),
                      ),
                      dropdownMenuEntries: widget.bays.asMap().entries.map((entry) {
                        return DropdownMenuEntry<String>(
                          value: entry.value.id,
                          label: entry.value.name,
                          leadingIcon: Icon(_bayIcon(entry.key),
                              size: 18, color: AppTheme.primary),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РђРІС‚Рѕ'),
                    DropdownMenu<String>(
                      width: 300,
                      initialSelection: _vehicleId.isEmpty ? null : _vehicleId,
                      onSelected: (v) {
                        setState(() {
                          _vehicleId = v ?? '';
                          // FIX: РІС‹Р±РёСЂР°Р» СЃСѓС‰РµСЃС‚РІСѓСЋС‰РµРµ Р°РІС‚Рѕ в†’ РѕС‡РёСЃС‚РёРј РїРѕР»СЏ "РЅРѕРІРѕРіРѕ"
                          // (РёРЅР°С‡Рµ РїСЂРё СЃРѕС…СЂР°РЅРµРЅРёРё РјРѕРіСѓС‚ РїРµСЂРµР·Р°РїРёСЃР°С‚СЊСЃСЏ РґР°РЅРЅС‹Рµ
                          // РІ РєР°С‚Р°Р»РѕРіРµ вЂ” РєРѕСЂРµРЅСЊ Р±Р°РіР° РґСѓР±Р»РёРєР°С‚РѕРІ)
                          if (v != null && v.isNotEmpty) {
                            _makeCtrl.clear();
                            _modelCtrl.clear();
                            _clientNameCtrl.clear();
                            _clientPhoneCtrl.clear();
                          }
                        });
                      },
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textOf(context),
                      ),
                      dropdownMenuEntries: widget.vehicles
                          .map((v) => DropdownMenuEntry<String>(
                                value: v.id,
                                label: v.displayLabel,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _textField(_makeCtrl, 'РњР°СЂРєР° (РґР»СЏ РЅРѕРІРѕРіРѕ Р°РІС‚Рѕ)'),
                    const SizedBox(height: 8),
                    _textField(_modelCtrl, 'РњРѕРґРµР»СЊ'),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РљР»РёРµРЅС‚'),
                    _textField(_clientNameCtrl, 'РРјСЏ РєР»РёРµРЅС‚Р°'),
                    const SizedBox(height: 8),
                    _textField(_clientPhoneCtrl, 'РўРµР»РµС„РѕРЅ',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РџСЂРёС‡РёРЅР° РѕР±СЂР°С‰РµРЅРёСЏ'),
                    _textField(_reasonCtrl, 'Р§С‚Рѕ РЅСѓР¶РЅРѕ СЃРґРµР»Р°С‚СЊ', maxLines: 3),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РЎС‚Р°С‚СѓСЃ'),
                    DropdownMenu<String>(
                      width: 300,
                      initialSelection: _status,
                      onSelected: (v) => setState(() => _status = v ?? 'planned'),
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textOf(context),
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'planned', label: 'Р—Р°РїР»Р°РЅРёСЂРѕРІР°РЅРѕ'),
                        DropdownMenuEntry(value: 'in_progress', label: 'Р’ СЂР°Р±РѕС‚Рµ'),
                        DropdownMenuEntry(value: 'ready', label: 'Р“РѕС‚РѕРІРѕ'),
                      ],
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('РџСЂРёРјРµС‡Р°РЅРёРµ'),
                    _textField(_noteCtrl, 'Р”РѕРї. РєРѕРјРјРµРЅС‚Р°СЂРёРё', maxLines: 2),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEdit ? 'РЎРѕС…СЂР°РЅРёС‚СЊ' : 'РЎРѕР·РґР°С‚СЊ Р·Р°РїРёСЃСЊ',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('РЈРґР°Р»РёС‚СЊ Р·Р°РїРёСЃСЊ', style: TextStyle(fontSize: 15)),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDim,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _dateTile(DateTime dt, {required bool isStart}) {
    return InkWell(
      onTap: () => _pickDate(isStart: isStart),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                DateFormat('d MMM yyyy', 'ru_RU').format(dt),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textOf(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(DateTime dt, {required bool isStart}) {
    return InkWell(
      onTap: () => _pickTime(isStart: isStart),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('HH:mm').format(dt),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textOf(context)),
            ),
            Icon(Icons.schedule, size: 16, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              surfaceTintColor: Colors.transparent,
              dayStyle: TextStyle(fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    if (!mounted) return;

    setState(() {
      if (isStart) {
        _startAt = DateTime(date.year, date.month, date.day, _startAt.hour, _startAt.minute);
        // Р•СЃР»Рё end <= start вЂ” Р°РІС‚Рѕ-СЃРґРІРёРіР°РµРј
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = DateTime(date.year, date.month, date.day, _endAt.hour, _endAt.minute);
        // Р•СЃР»Рё end СЃС‚Р°Р» <= start вЂ” Р°РІС‚Рѕ-СЃРґРІРёРіР°РµРј end РЅР° +1 РґРµРЅСЊ
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _endAt.add(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => TimeInputDialog(
        initialTime: TimeOfDay.fromDateTime(initial),
        label: isStart ? 'Р’СЂРµРјСЏ РЅР°С‡Р°Р»Р°' : 'Р’СЂРµРјСЏ РѕРєРѕРЅС‡Р°РЅРёСЏ',
      ),
    );
    if (result == null) return;
    if (!mounted) return;

    final newDt = DateTime(
      initial.year, initial.month, initial.day,
      result.hour, result.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = newDt;
        // Р•СЃР»Рё end <= start вЂ” Р°РІС‚Рѕ-СЃРґРІРёРіР°РµРј
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        // РђРІС‚Рѕ-СЃРґРІРёРі: РµСЃР»Рё РІСЂРµРјСЏ СЂР°РЅСЊС€Рµ РЅР°С‡Р°Р»Р° РЅР° С‚РѕР№ Р¶Рµ РґР°С‚Рµ вЂ” +1 РґРµРЅСЊ
        if (initial.year == _startAt.year &&
            initial.month == _startAt.month &&
            initial.day == _startAt.day &&
            newDt.isBefore(_startAt)) {
          _endAt = newDt.add(const Duration(days: 1));
        } else {
          _endAt = newDt;
        }
      }
    });
  }

  IconData _bayIcon(int index) {
    // Р’СЃРµ РїРѕСЃС‚С‹ вЂ” РїРѕРґСЉС‘РјРЅРёРєРё, РѕРґРЅР° РёРєРѕРЅРєР°.
    return Icons.car_repair;
  }

  void _submit() async {
    if (_bayId.isEmpty) {
      _snack('Р’С‹Р±РµСЂРёС‚Рµ РїРѕСЃС‚');
      return;
    }
    if (_vehicleId.isEmpty && _makeCtrl.text.trim().isEmpty) {
      _snack('Р’С‹Р±РµСЂРёС‚Рµ Р°РІС‚Рѕ РёР· СЃРїРёСЃРєР° РёР»Рё РІРІРµРґРёС‚Рµ РјР°СЂРєСѓ РЅРѕРІРѕРіРѕ');
      return;
    }
    if (!_endAt.isAfter(_startAt)) {
      _snack('РљРѕРЅРµС† РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РїРѕР·Р¶Рµ РЅР°С‡Р°Р»Р°');
      return;
    }
    final duration = _endAt.difference(_startAt);
    if (duration.inDays > 7 || (duration.inDays == 7 && duration.inMinutes % (24 * 60) > 0)) {
      _snack('РњР°РєСЃРёРјР°Р»СЊРЅР°СЏ РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ СЂРµРјРѕРЅС‚Р° вЂ” 7 РґРЅРµР№');
      return;
    }

    String vehicleId = _vehicleId;

    // Р›РѕРіРёРєР° РІС‹Р±РѕСЂР° Р°РІС‚Рѕ:
    //   1) Р•СЃР»Рё Р·Р°РїРѕР»РЅРµРЅР° РјР°СЂРєР° РІ РїРѕР»Рµ "РґР»СЏ РЅРѕРІРѕРіРѕ Р°РІС‚Рѕ" в†’ РёС‰РµРј СЃРѕРІРїР°РґРµРЅРёРµ
    //      РїРѕ РјР°СЂРєРµ Р‘Р•Р— СѓС‡С‘С‚Р° СЂРµРіРёСЃС‚СЂР°. РќР°С€Р»Рё вЂ” РёСЃРїРѕР»СЊР·СѓРµРј СЌС‚Рѕ Р°РІС‚Рѕ
    //      (РЅРµ РёР·РјРµРЅСЏРµРј РµРіРѕ РґР°РЅРЅС‹Рµ). РќРµ РЅР°С€Р»Рё вЂ” СЃРѕР·РґР°С‘Рј РЅРѕРІРѕРµ.
    //   2) РРЅР°С‡Рµ, РµСЃР»Рё РІС‹Р±СЂР°РЅ Р°РІС‚Рѕ РІ dropdown в†’ РёСЃРїРѕР»СЊР·СѓРµРј РµРіРѕ ID.
    // РџСЂРёРѕСЂРёС‚РµС‚ Сѓ РїРѕР»СЏ РјР°СЂРєРё: РµСЃР»Рё Рё dropdown РІС‹Р±СЂР°РЅ, Рё РјР°СЂРєР° Р·Р°РїРѕР»РЅРµРЅР° вЂ”
    // РјР°СЂРєР° РїРѕР±РµР¶РґР°РµС‚ (СЌС‚Рѕ СЏРІРЅС‹Р№ РІРІРѕРґ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ "С…РѕС‡Сѓ СЌС‚Рѕ Р°РІС‚Рѕ").
    if (_makeCtrl.text.trim().isNotEmpty) {
      final makeToFind = _makeCtrl.text.trim().toLowerCase();
      final existingIdx = widget.vehicles.indexWhere(
        (v) => v.make.toLowerCase() == makeToFind,
      );
      if (existingIdx >= 0) {
        // Р•СЃС‚СЊ Р°РІС‚Рѕ СЃ С‚Р°РєРѕР№ РјР°СЂРєРѕР№ вЂ” РёСЃРїРѕР»СЊР·СѓРµРј РµРіРѕ Р‘Р•Р— РёР·РјРµРЅРµРЅРёСЏ РґР°РЅРЅС‹С….
        vehicleId = widget.vehicles[existingIdx].id;
      } else {
        // РђРІС‚Рѕ СЃ С‚Р°РєРѕР№ РјР°СЂРєРѕР№ РЅРµС‚ вЂ” СЃРѕР·РґР°С‘Рј РЅРѕРІРѕРµ.
        try {
          final catApi = ref.read(catalogApiProvider);
          final newV = await catApi.createVehicle(Vehicle(
            id: '',
            shopId: widget.existingAppointment?.shopId ?? '',
            make: _makeCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            customerName: _clientNameCtrl.text.trim(),
            customerPhone: _clientPhoneCtrl.text.trim(),
          ));
          vehicleId = newV.id;
        } catch (e) {
          _snack('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ Р°РІС‚Рѕ: $e');
          return;
        }
      }
    }
    // РРЅР°С‡Рµ (_makeCtrl РїСѓСЃС‚) вЂ” РёСЃРїРѕР»СЊР·СѓРµРј _vehicleId РёР· dropdown.

    if (!mounted) return;

    final note = [
      if (_reasonCtrl.text.trim().isNotEmpty) _reasonCtrl.text.trim(),
      if (_noteCtrl.text.trim().isNotEmpty) _noteCtrl.text.trim(),
    ].join(' | ');

    Navigator.pop(
      context,
      models.Appointment(
        id: widget.existingAppointment?.id ?? '',
        shopId: widget.existingAppointment?.shopId ?? '',
        bayId: _bayId,
        vehicleId: vehicleId,
        startAt: _startDateTime,
        endAt: _endDateTime,
        status: _status,
        note: note,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Р”РёР°Р»РѕРі СЂСѓС‡РЅРѕРіРѕ РІРІРѕРґР° РІСЂРµРјРµРЅРё С‡РµСЂРµР· TextField.
/// Р¤РѕСЂРјР°С‚: Р§Р§:РњРњ (24-С‡Р°СЃРѕРІРѕР№ С„РѕСЂРјР°С‚, HH:MM).
/// Р’Р°Р»РёРґР°С†РёСЏ: 00-23:00-59. Enter РїСЂРёРјРµРЅСЏРµС‚. РљРЅРѕРїРєР° "Р“РѕС‚РѕРІРѕ" С‚РѕР¶Рµ РїСЂРёРјРµРЅСЏРµС‚.
class TimeInputDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String label;

  const TimeInputDialog({
    required this.initialTime,
    required this.label,
  });

  @override
  State<TimeInputDialog> createState() => TimeInputDialogState();
}

class TimeInputDialogState extends State<TimeInputDialog> {
  late final TextEditingController _ctrl;
  String? _error;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour.toString().padLeft(2, '0');
    final m = widget.initialTime.minute.toString().padLeft(2, '0');
    _ctrl = TextEditingController(text: '$h:$m');
    // РђРІС‚Рѕ-С„РѕРєСѓСЃ + РІС‹РґРµР»РµРЅРёРµ С‚РµРєСЃС‚Р°
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _ctrl.text.length,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  TimeOfDay? _validate(String value) {
    final trimmed = value.trim();
    // Р Р°Р·СЂРµС€Р°РµРј "9:30" в†’ РґРѕРїРѕР»РЅСЏРµРј РґРѕ "09:30"
    final parts = trimmed.split(':');
    if (parts.length != 2) {
      setState(() => _error = 'Р¤РѕСЂРјР°С‚: Р§Р§:РњРњ (РЅР°РїСЂРёРјРµСЂ 14:30)');
      return null;
    }
    final hStr = parts[0].padLeft(2, '0');
    final mStr = parts[1].padLeft(2, '0');
    final h = int.tryParse(hStr);
    final m = int.tryParse(mStr);
    if (h == null || m == null) {
      setState(() => _error = 'РўРѕР»СЊРєРѕ С†РёС„СЂС‹');
      return null;
    }
    if (h < 0 || h > 23) {
      setState(() => _error = 'Р§Р°СЃС‹: 00-23');
      return null;
    }
    if (m < 0 || m > 59) {
      setState(() => _error = 'РњРёРЅСѓС‚С‹: 00-59');
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  void _submit() {
    final result = _validate(_ctrl.text);
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            keyboardType: TextInputType.datetime,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Р§Р§:РњРњ',
              errorText: _error,
              counterText: '',
            ),
            maxLength: 5,
            inputFormatters: [
              TimeInputFormatter(),
            ],
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          Text(
            '24-С‡Р°СЃРѕРІРѕР№ С„РѕСЂРјР°С‚ (00:00 вЂ“ 23:59)',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuteOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('РћС‚РјРµРЅР°'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Р“РѕС‚РѕРІРѕ'),
        ),
      ],
    );
  }
}

/// Formatter: Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РґРѕР±Р°РІР»СЏРµС‚ ":" РјРµР¶РґСѓ С†РёС„СЂР°РјРё.
/// Р Р°Р·СЂРµС€Р°РµС‚ С‚РѕР»СЊРєРѕ С†РёС„СЂС‹ Рё РґРІРѕРµС‚РѕС‡РёРµ. РњР°РєСЃРёРјСѓРј "HH:MM" (5 СЃРёРјРІРѕР»РѕРІ).
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // РЈРґР°Р»СЏРµРј РІСЃС‘ РєСЂРѕРјРµ С†РёС„СЂ Рё ":"
    var text = newValue.text.replaceAll(RegExp(r'[^0-9:]'), '');

    // РњР°РєСЃРёРјСѓРј 5 СЃРёРјРІРѕР»РѕРІ (HH:MM)
    if (text.length > 5) text = text.substring(0, 5);

    // РќРµ РґРѕРїСѓСЃРєР°РµРј Р±РѕР»СЊС€Рµ РѕРґРЅРѕРіРѕ ":"
    final colonCount = ':'.allMatches(text).length;
    if (colonCount > 1) {
      // Р‘РµСЂС‘Рј С‚РѕР»СЊРєРѕ РїРµСЂРІРѕРµ РґРІРѕРµС‚РѕС‡РёРµ
      final idx = text.indexOf(':');
      text = text.substring(0, idx + 1) + text.substring(idx + 1).replaceAll(':', '');
    }

    // Р•СЃР»Рё СѓР¶Рµ 2 С†РёС„СЂС‹ Рё РЅРµС‚ ":" вЂ” РґРѕР±Р°РІР»СЏРµРј
    if (text.length == 2 && !text.contains(':')) {
      text = '$text:';
    }

    // Р’Р°Р»РёРґР°С†РёСЏ С‡Р°СЃРѕРІ (0-23)
    final parts = text.split(':');
    if (parts.isNotEmpty && parts[0].length >= 1) {
      final h = int.tryParse(parts[0]);
      if (h != null && h > 23) {
        parts[0] = '23';
      }
    }
    // Р’Р°Р»РёРґР°С†РёСЏ РјРёРЅСѓС‚ (0-59)
    if (parts.length >= 2 && parts[1].length >= 1) {
      final m = int.tryParse(parts[1]);
      if (m != null && m > 59) {
        parts[1] = '59';
      }
    }
    text = parts.join(':');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
