import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';
import 'hybrid_time_picker.dart';
import 'vehicle_search_screen.dart';

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
  Vehicle? _selectedVehicle;
  String _status = 'planned';

  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _vinCtrl;
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
    _plateCtrl = TextEditingController();
    _vinCtrl = TextEditingController();
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
        // Авто уже в каталоге — выбираем его в autocomplete
        _selectedVehicle = widget.vehicles[vIdx];
        _makeCtrl.text = '';
        _modelCtrl.text = '';
        _plateCtrl.text = '';
        _vinCtrl.text = '';
        _clientNameCtrl.text = '';
        _clientPhoneCtrl.text = '';
      } else {
        // Авто не в каталоге (legacy/orphaned) — заполняем поля как "новое"
        _selectedVehicle = null;
        _makeCtrl.text = '';
        _modelCtrl.text = '';
        _plateCtrl.text = '';
        _vinCtrl.text = '';
        _clientNameCtrl.text = '';
        _clientPhoneCtrl.text = '';
      }
    }
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _vinCtrl.dispose();
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
                    Row(
                      children: [
                        Expanded(child: _dateTile(_startAt, isStart: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _timeTile(_startAt, isStart: true)),
                      ],
                    ),
                    const SizedBox(height: _fieldSpacing),

                    _sectionLabel('Конец'),
                    Row(
                      children: [
                        Expanded(child: _dateTile(_endAt, isStart: false)),
                        const SizedBox(width: 8),
                        Expanded(child: _timeTile(_endAt, isStart: false)),
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

                    _sectionLabel('Авто (поиск или создать новое)'),
                    _vehicleAutocomplete(),
                    const SizedBox(height: 8),
                    _textField(_makeCtrl, 'Марка (для нового авто)'),
                    const SizedBox(height: 8),
                    _textField(_modelCtrl, 'Модель'),
                    const SizedBox(height: 8),
                    _textField(_plateCtrl, 'Госномер'),
                    const SizedBox(height: 8),
                    _textField(_vinCtrl, 'VIN номер'),
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

  Widget _vehicleAutocomplete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push<Vehicle>(
          MaterialPageRoute(
            builder: (_) => VehicleSearchScreen(
              vehicles: widget.vehicles,
              selectedVehicle: _selectedVehicle,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _selectedVehicle = result;
            _vehicleId = result.id;
            // Очищаем поля "нового авто"
            _makeCtrl.clear();
            _modelCtrl.clear();
            _plateCtrl.clear();
            _vinCtrl.clear();
            _clientNameCtrl.clear();
            _clientPhoneCtrl.clear();
          });
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface2 : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_car,
              color: AppTheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedVehicle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicle!.displayLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_selectedVehicle!.plate.isNotEmpty) _selectedVehicle!.plate,
                            if (_selectedVehicle!.vin.isNotEmpty) 'VIN: ${_selectedVehicle!.vin}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuteOf(context),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Выберите авто',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuteOf(context),
                      ),
                    ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textMuteOf(context),
            ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: isDark ? AppTheme.darkSurface2 : Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? AppTheme.darkSurface2 : Colors.white,
              surfaceTintColor: Colors.transparent,
              dayStyle: const TextStyle(fontSize: 14),
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Colors.white,
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return null;
              }),
              todayBackgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              todayForegroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 10, bottom: 6, left: 16, right: 16),
              ),
              confirmButtonStyle: FilledButton.styleFrom(
                padding: const EdgeInsets.only(top: 10, bottom: 6, left: 16, right: 16),
              ),
            ),
            dialogTheme: DialogThemeData(
              actionsPadding: const EdgeInsets.only(bottom: 6),
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
        // Если end <= start — авто-сдвигаем
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = DateTime(date.year, date.month, date.day, _endAt.hour, _endAt.minute);
        // Если end стал <= start — авто-сдвигаем end на +1 день
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _endAt.add(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final startTime = isStart ? null : TimeOfDay.fromDateTime(_startAt);
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => HybridTimePicker(
        initialTime: TimeOfDay.fromDateTime(initial),
        startTime: startTime,
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
        // Если end <= start — авто-сдвигаем
        if (!_endAt.isAfter(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        // Авто-сдвиг: если время раньше начала на той же дате — +1 день
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
    // Все посты — подъёмники, одна иконка.
    return Icons.car_repair;
  }

  void _submit() async {
    if (_bayId.isEmpty) {
      _snack('Выберите пост');
      return;
    }
    if (_vehicleId.isEmpty && _makeCtrl.text.trim().isEmpty) {
      _snack('Выберите авто через поиск или введите марку нового');
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
    //   2) Иначе, если выбран авто в autocomplete → используем его ID.
    // Приоритет у поля марки: если и autocomplete выбран, и марка заполнена —
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
            plate: _plateCtrl.text.trim(),
            vin: _vinCtrl.text.trim(),
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
    // Иначе (_makeCtrl пуст) — используем _vehicleId из autocomplete.

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
