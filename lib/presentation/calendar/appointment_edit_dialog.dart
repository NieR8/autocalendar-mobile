import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';
import '../work_order/work_order_screen.dart';

/// Диалог создания/редактирования записи.
/// Отступы между всеми полями — 12px. 24-часовой формат времени.
/// Стилизованные dropdowns через DropdownButtonFormField с декорацией.
class AppointmentEditDialog extends ConsumerStatefulWidget {
  final models.Appointment? appointment;
  final List<Bay> bays;
  final List<Vehicle> vehicles;
  final DateTime initialStart;

  const AppointmentEditDialog({
    super.key,
    required this.appointment,
    required this.bays,
    required this.vehicles,
    required this.initialStart,
  });

  @override
  ConsumerState<AppointmentEditDialog> createState() => _AppointmentEditDialogState();
}

class _AppointmentEditDialogState extends ConsumerState<AppointmentEditDialog> {
  late DateTime _start;
  late DateTime _end;
  String _bayId = '';
  String _vehicleId = '';
  String _status = 'planned';
  late final TextEditingController _noteCtrl;

  bool _isInlineVehicle = false;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;

  static const _fieldSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _start = a?.startAt ?? widget.initialStart;
    _end = a?.endAt ?? _start.add(const Duration(hours: 1));
    _bayId = a?.bayId ?? (widget.bays.isNotEmpty ? widget.bays.first.id : '');
    _vehicleId = a?.vehicleId ?? (widget.vehicles.isNotEmpty ? widget.vehicles.first.id : '');
    _status = a?.status ?? 'planned';
    _noteCtrl = TextEditingController(text: a?.note ?? '');
    _isInlineVehicle = widget.vehicles.isEmpty;
    _makeCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _plateCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;
    return AlertDialog(
      title: Text(isEdit ? 'Изменить запись' : 'Новая запись'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Пост
            _styledDropdown(
              label: 'Пост',
              value: _bayId.isEmpty ? null : _bayId,
              items: widget.bays
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (v) => setState(() => _bayId = v ?? ''),
            ),
            const SizedBox(height: _fieldSpacing),

            // Авто — inline или dropdown
            if (_isInlineVehicle) ...[
              TextField(
                controller: _makeCtrl,
                decoration: const InputDecoration(labelText: 'Марка авто *'),
                autofocus: true,
              ),
              const SizedBox(height: _fieldSpacing),
              TextField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: 'Модель'),
              ),
              const SizedBox(height: _fieldSpacing),
              TextField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'Госномер *'),
                textCapitalization: TextCapitalization.characters,
              ),
              if (widget.vehicles.isNotEmpty) ...[
                const SizedBox(height: _fieldSpacing),
                TextButton.icon(
                  icon: const Icon(Icons.list, size: 18),
                  label: const Text('Выбрать из каталога'),
                  onPressed: () => setState(() => _isInlineVehicle = false),
                ),
              ],
            ] else ...[
              _styledDropdown(
                label: 'Авто',
                value: _vehicleId.isEmpty ? null : _vehicleId,
                items: widget.vehicles
                    .map((v) => DropdownMenuItem(value: v.id, child: Text(v.displayLabel)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleId = v ?? ''),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Новое авто'),
                onPressed: () => setState(() => _isInlineVehicle = true),
              ),
            ],
            const SizedBox(height: _fieldSpacing),

            // Время старта
            _timeTile('Старт', _start, true),
            const SizedBox(height: _fieldSpacing),

            // Время конца
            _timeTile('Конец', _end, false),
            const SizedBox(height: _fieldSpacing),

            // Статус
            _styledDropdown(
              label: 'Статус',
              value: _status,
              items: const [
                DropdownMenuItem(value: 'planned', child: Text('Запланировано')),
                DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
                DropdownMenuItem(value: 'ready', child: Text('Готово')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'planned'),
            ),
            const SizedBox(height: _fieldSpacing),

            // Заметка
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Заметка'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        if (isEdit) ...[
          TextButton.icon(
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            label: const Text('Наряд'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WorkOrderScreen(
                  appointmentId: widget.appointment!.id,
                  appointmentLabel:
                      'Запись ${DateFormat('dd.MM H:mm').format(widget.appointment!.startAt)}',
                ),
              ));
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(
                context,
                models.Appointment(
                  id: 'delete',
                  shopId: '', bayId: '', vehicleId: '',
                  startAt: DateTime.now(), endAt: DateTime.now(),
                )),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Удалить'),
          ),
        ],
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: Text(isEdit ? 'Сохранить' : 'Создать')),
      ],
    );
  }

  /// Стилизованный dropdown с consistent декорацией.
  Widget _styledDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more, color: AppTheme.textDim),
      dropdownColor: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      menuMaxHeight: 300,
    );
  }

  /// Плитка выбора времени с 24-часовым форматом.
  Widget _timeTile(String label, DateTime dt, bool isStart) {
    return InkWell(
      onTap: () => _pickDateTime(isStart: isStart),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 14)),
            Text(
              DateFormat('dd.MM.yyyy, H:mm').format(dt),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMute, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('ru', 'RU'),
    );
    if (date == null) return;
    if (!mounted) return;
    // 24-часовой формат — TimePicker с builder для русского.
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = newDt;
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = newDt;
      }
    });
  }

  void _submit() async {
    if (_bayId.isEmpty) {
      _snack('Выберите пост');
      return;
    }
    if (_isInlineVehicle) {
      if (_makeCtrl.text.trim().isEmpty && _plateCtrl.text.trim().isEmpty) {
        _snack('Введите марку или госномер авто');
        return;
      }
    } else if (_vehicleId.isEmpty) {
      _snack('Выберите авто');
      return;
    }
    if (!_end.isAfter(_start)) {
      _snack('Конец должен быть позже старта');
      return;
    }

    String vehicleId = _vehicleId;

    if (_isInlineVehicle) {
      try {
        final catApi = ref.read(catalogApiProvider);
        final newV = await catApi.createVehicle(Vehicle(
          id: '',
          shopId: '',
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          plate: _plateCtrl.text.trim().toUpperCase(),
        ));
        vehicleId = newV.id;
      } catch (e) {
        _snack('Ошибка создания авто: $e');
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      models.Appointment(
        id: widget.appointment?.id ?? '',
        shopId: widget.appointment?.shopId ?? '',
        bayId: _bayId,
        vehicleId: vehicleId,
        startAt: _start,
        endAt: _end,
        status: _status,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
