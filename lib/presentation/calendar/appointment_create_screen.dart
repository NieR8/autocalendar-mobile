import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';

/// Страница создания/редактирования записи.
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

      // Ищем авто в каталоге. Если найдено — это уже существующее авто,
      // поля "для нового авто" оставляем ПУСТЫМИ (fix: дубликаты в каталоге).
      // Если НЕ найдено (edge case) — заполняем поля из appt.
      final vIdx = widget.vehicles.indexWhere((v) => v.id == a.vehicleId);
      if (vIdx >= 0) {
        // Авто уже в каталоге — ничего не дублируем в поля
        _makeCtrl.text = '';
        _modelCtrl.text = '';
        _clientNameCtrl.text = '';
        _clientPhoneCtrl.text = '';
      } else {
        // Авто не в каталоге (legacy/orphaned) — заполняем поля как "новое"
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
                    _isEdit ? 'Изменить запись' : 'Новая запись',
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
                    _sectionLabel('Начало'),
                    _dateTimeTile(_startAt, isStart: true),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Конец'),
                    _dateTimeTile(_endAt, isStart: false),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Пост'),
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

                    _sectionLabel('Авто'),
                    DropdownMenu<String>(
                      width: 300,
                      initialSelection: _vehicleId.isEmpty ? null : _vehicleId,
                      onSelected: (v) {
                        setState(() {
                          _vehicleId = v ?? '';
                          // FIX: выбирал существующее авто → очистим поля "нового"
                          // (иначе при сохранении могут перезаписаться данные
                          // в каталоге — корень бага дубликатов)
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
                    _textField(_makeCtrl, 'Марка (для нового авто)'),
                    const SizedBox(height: 8),
                    _textField(_modelCtrl, 'Модель'),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Клиент'),
                    _textField(_clientNameCtrl, 'Имя клиента'),
                    const SizedBox(height: 8),
                    _textField(_clientPhoneCtrl, 'Телефон',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Причина обращения'),
                    _textField(_reasonCtrl, 'Что нужно сделать', maxLines: 3),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Статус'),
                    DropdownMenu<String>(
                      width: 300,
                      initialSelection: _status,
                      onSelected: (v) => setState(() => _status = v ?? 'planned'),
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textOf(context),
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'planned', label: 'Запланировано'),
                        DropdownMenuEntry(value: 'in_progress', label: 'В работе'),
                        DropdownMenuEntry(value: 'ready', label: 'Готово'),
                      ],
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Примечание'),
                    _textField(_noteCtrl, 'Доп. комментарии', maxLines: 2),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEdit ? 'Сохранить' : 'Создать запись',
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
                        child: const Text('Удалить запись', style: TextStyle(fontSize: 15)),
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

  Widget _dateTimeTile(DateTime dt, {required bool isStart}) {
    return InkWell(
      onTap: () => _pickDateTime(isStart: isStart),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'ru_RU').format(dt),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textOf(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('H:mm').format(dt),
                  style: TextStyle(fontSize: 13, color: AppTheme.textDimOf(context)),
                ),
              ],
            ),
            Icon(Icons.edit, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
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
        _startAt = newDt;
        // Если end <= start (или не позже часа) — авто-сдвигаем
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        // Авто-сдвиг: если на той же дате end < start — сдвигаем end на +1 день
        if (date.year == _startAt.year &&
            date.month == _startAt.month &&
            date.day == _startAt.day &&
            newDt.isBefore(_startAt)) {
          _endAt = newDt.add(const Duration(days: 1));
        } else {
          _endAt = newDt;
        }
      }
    });
  }

  IconData _bayIcon(int index) {
    // Все посты — подъёмники, одна иконка.
    return Icons.car_repair;
  }

  void _submit() async {
    if (_bayId.isEmpty) {
      _snack('Выберите пост');
      return;
    }
    if (_vehicleId.isEmpty && _makeCtrl.text.trim().isEmpty) {
      _snack('Выберите авто из списка или введите марку нового');
      return;
    }
    if (!_endAt.isAfter(_startAt)) {
      _snack('Конец должен быть позже начала');
      return;
    }
    final duration = _endAt.difference(_startAt);
    if (duration.inDays > 7 || (duration.inDays == 7 && duration.inMinutes % (24 * 60) > 0)) {
      _snack('Максимальная длительность ремонта — 7 дней');
      return;
    }

    String vehicleId = _vehicleId;

    // Логика выбора авто:
    //   1) Если заполнена марка в поле "для нового авто" → ищем совпадение
    //      по марке БЕЗ учёта регистра. Нашли — используем это авто
    //      (не изменяем его данные). Не нашли — создаём новое.
    //   2) Иначе, если выбран авто в dropdown → используем его ID.
    // Приоритет у поля марки: если и dropdown выбран, и марка заполнена —
    // марка побеждает (это явный ввод пользователя "хочу это авто").
    if (_makeCtrl.text.trim().isNotEmpty) {
      final makeToFind = _makeCtrl.text.trim().toLowerCase();
      final existingIdx = widget.vehicles.indexWhere(
        (v) => v.make.toLowerCase() == makeToFind,
      );
      if (existingIdx >= 0) {
        // Есть авто с такой маркой — используем его БЕЗ изменения данных.
        vehicleId = widget.vehicles[existingIdx].id;
      } else {
        // Авто с такой маркой нет — создаём новое.
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
          _snack('Ошибка сохранения авто: $e');
          return;
        }
      }
    }
    // Иначе (_makeCtrl пуст) — используем _vehicleId из dropdown.

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
