import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
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
    _date = a?.startAt ?? widget.initialDate;
    _startTime = TimeOfDay.fromDateTime(a?.startAt ?? widget.initialDate);
    _endTime = TimeOfDay.fromDateTime(
        a?.endAt ?? widget.initialDate.add(const Duration(hours: 1)));
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

  DateTime get _startDateTime => DateTime(
        _date.year, _date.month, _date.day,
        _startTime.hour, _startTime.minute,
      );

  DateTime get _endDateTime => DateTime(
        _date.year, _date.month, _date.day,
        _endTime.hour, _endTime.minute,
      );

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
                    _sectionLabel('Дата'),
                    _dateTile(),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Время'),
                    Row(
                      children: [
                        Expanded(child: _timeTile('Начало', _startTime, true)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              color: AppTheme.textMute, size: 20),
                        ),
                        Expanded(child: _timeTile('Конец', _endTime, false)),
                      ],
                    ),
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

  Widget _dateTile() {
    return InkWell(
      onTap: _pickDate,
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
            Text(
              DateFormat('d MMMM yyyy', 'ru_RU').format(_date),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textOf(context)),
            ),
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _pickWheelTime(isStart),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textDimOf(context))),
            const SizedBox(width: 6),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _bayIcon(int index) {
    const icons = [Icons.build, Icons.search, Icons.tire_repair, Icons.bolt, Icons.car_repair];
    return icons[index % icons.length];
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
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
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickWheelTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    TimeOfDay result = initial;
    final inputCtrl = TextEditingController(
      text: '${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}',
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Container(
        height: 420,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Отмена', style: TextStyle(fontSize: 15)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, result),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Готово', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isStart ? 'Начало' : 'Конец',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.keyboard, size: 18),
                const SizedBox(width: 8),
                const Text('Вручную:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: inputCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9:]'), allow: true),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'ЧЧ:ММ',
                      isDense: true,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (val) => _applyManualTime(val, inputCtrl, (t) {
                      result = t;
                    }, sheetContext),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _applyManualTime(inputCtrl.text, inputCtrl, (t) {
                    result = t;
                  }, sheetContext),
                  child: const Text('Применить'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Рабочее время: 8:00 - 21:00',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuteOf(context)),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                    ),
                  ),
                  primaryColor: AppTheme.primary,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(2020, 1, 1, initial.hour, initial.minute),
                  onDateTimeChanged: (dt) {
                    result = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    inputCtrl.text = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((selected) {
      inputCtrl.dispose();
      if (selected is TimeOfDay) {
        setState(() {
          if (isStart) {
            _startTime = selected;
            final startMins = selected.hour * 60 + selected.minute;
            final endMins = _endTime.hour * 60 + _endTime.minute;
            if (endMins <= startMins) {
              _endTime = TimeOfDay(
                hour: (selected.hour + 1).clamp(8, 21),
                minute: selected.minute,
              );
            }
          } else {
            _endTime = selected;
          }
        });
      }
    });
  }

  void _applyManualTime(String val, TextEditingController ctrl,
      void Function(TimeOfDay) onValid, BuildContext sheetContext) {
    final parts = val.split(':');
    if (parts.length != 2) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Формат: ЧЧ:ММ, например 14:30')),
      );
      return;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Только цифры: ЧЧ:ММ')),
      );
      return;
    }
    if (h < 8 || h > 20 || m < 0 || m >= 60) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Рабочее время: 8:00 - 21:00')),
      );
      return;
    }
    onValid(TimeOfDay(hour: h, minute: m));
    ctrl.text = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
    if (_endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute) {
      _snack('Время окончания должно быть позже начала');
      return;
    }

    String vehicleId = _vehicleId;

    // FIX: две независимые ветки для каталога:
    //   1) Выбран существующий авто в dropdown → используем его ID, каталог не трогаем
    //   2) Dropdown пустой + заполнены поля "для нового авто" → создаём новое авто
    // Раньше было: если _makeCtrl не пустой → всегда update/insert авто в каталоге,
    // что при редактировании апта перезаписывало выбранное авто данными из полей
    // и создавало дубликаты в каталоге (баг: редактирование апта ломает каталог).
    if (_vehicleId.isNotEmpty) {
      // Выбран существующий авто — используем его напрямую, каталог не трогаем.
      // Пользователь должен редактировать авто в Каталогах, а не через форму апта.
    } else if (_makeCtrl.text.trim().isNotEmpty) {
      // Выбран "новый авто" — создаём и используем его ID
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
