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
    return Autocomplete<Vehicle>(
      initialValue: _selectedVehicle != null
          ? TextEditingValue(text: _selectedVehicle!.displayLabel)
          : const TextEditingValue(),
      displayStringForOption: (v) => v.displayLabel,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) {
          return widget.vehicles.where((v) => v.id.isNotEmpty);
        }
        return widget.vehicles.where((v) {
          return v.make.toLowerCase().contains(query) ||
              v.model.toLowerCase().contains(query) ||
              v.plate.toLowerCase().contains(query) ||
              v.vin.toLowerCase().contains(query);
        });
      },
      onSelected: (vehicle) {
        setState(() {
          _selectedVehicle = vehicle;
          _vehicleId = vehicle.id;
          // Очищаем поля "нового авто" — выбран существующий
          _makeCtrl.clear();
          _modelCtrl.clear();
          _plateCtrl.clear();
          _vinCtrl.clear();
          _clientNameCtrl.clear();
          _clientPhoneCtrl.clear();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: 'Выберите из списка или введите марку',
            hintText: 'Поиск по марке, модели, госномеру, VIN',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() {
                        _selectedVehicle = null;
                        _vehicleId = '';
                      });
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 260,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final vehicle = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(vehicle),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface2 : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.displayLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.darkText : AppTheme.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (vehicle.plate.isNotEmpty) vehicle.plate,
                                    if (vehicle.vin.isNotEmpty) 'VIN: ${vehicle.vin}',
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
            datePickerTheme: DatePickerThemeData(
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
                padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
              ),
              confirmButtonStyle: FilledButton.styleFrom(
                padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
              ),
            ),
            dialogTheme: DialogThemeData(
              actionsPadding: const EdgeInsets.only(bottom: 8),
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
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => TimeInputDialog(
        initialTime: TimeOfDay.fromDateTime(initial),
        label: isStart ? 'Время начала' : 'Время окончания',
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

/// Диалог ручного ввода времени через TextField.
/// Формат: ЧЧ:ММ (24-часовой формат, HH:MM).
/// Валидация: 00-23:00-59. Enter применяет. Кнопка "Готово" тоже применяет.
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
  late final TextEditingController _hourCtrl;
  late final TextEditingController _minuteCtrl;
  String? _error;
  final _hourFocusNode = FocusNode();
  final _minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hourCtrl = TextEditingController(
      text: widget.initialTime.hour.toString().padLeft(2, '0'),
    );
    _minuteCtrl = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
    // Авто-фокус на часы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourFocusNode.requestFocus();
      _hourCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _hourCtrl.text.length,
      );
    });
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  TimeOfDay? _validate() {
    final hStr = _hourCtrl.text.trim().padLeft(2, '0');
    final mStr = _minuteCtrl.text.trim().padLeft(2, '0');
    final h = int.tryParse(hStr);
    final m = int.tryParse(mStr);
    if (h == null || m == null) {
      setState(() => _error = 'Только цифры');
      return null;
    }
    if (h < 0 || h > 23) {
      setState(() => _error = 'Часы: 00-23');
      return null;
    }
    if (m < 0 || m > 59) {
      setState(() => _error = 'Минуты: 00-59');
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  void _submit() {
    final result = _validate();
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      title: Text(
        widget.label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkText : AppTheme.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Поле для часов
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _hourCtrl,
                  focusNode: _hourFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.text,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ЧЧ',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                      letterSpacing: 2,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface2 : AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSubmitted: (_) {
                    _minuteFocusNode.requestFocus();
                    _minuteCtrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _minuteCtrl.text.length,
                    );
                  },
                  onChanged: (value) {
                    setState(() => _error = null);
                    if (value.length == 2) {
                      _minuteFocusNode.requestFocus();
                      _minuteCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _minuteCtrl.text.length,
                      );
                    }
                  },
                ),
              ),
              // Разделитель ":"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.text,
                  ),
                ),
              ),
              // Поле для минут
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _minuteCtrl,
                  focusNode: _minuteFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.text,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ММ',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                      letterSpacing: 2,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface2 : AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.danger,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Text(
            '24-часовой формат',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(top: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Отмена',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: const Text(
            'Готово',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Formatter: автоматически добавляет ":" между цифрами.
/// Разрешает только цифры и двоеточие. Максимум "HH:MM" (5 символов).
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Удаляем всё кроме цифр и ":"
    var text = newValue.text.replaceAll(RegExp(r'[^0-9:]'), '');

    // Максимум 5 символов (HH:MM)
    if (text.length > 5) text = text.substring(0, 5);

    // Не допускаем больше одного ":"
    final colonCount = ':'.allMatches(text).length;
    if (colonCount > 1) {
      // Берём только первое двоеточие
      final idx = text.indexOf(':');
      text = text.substring(0, idx + 1) + text.substring(idx + 1).replaceAll(':', '');
    }

    // Если уже 2 цифры и нет ":" — добавляем
    if (text.length == 2 && !text.contains(':')) {
      text = '$text:';
    }

    // Валидация часов (0-23)
    final parts = text.split(':');
    if (parts.isNotEmpty && parts[0].length >= 1) {
      final h = int.tryParse(parts[0]);
      if (h != null && h > 23) {
        parts[0] = '23';
      }
    }
    // Валидация минут (0-59)
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
