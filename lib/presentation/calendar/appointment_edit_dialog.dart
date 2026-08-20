import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';
import '../work_order/work_order_screen.dart';
import 'appointment_create_screen.dart' show TimeInputDialog;

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
  Vehicle? _selectedVehicle;
  String _status = 'planned';
  late final TextEditingController _noteCtrl;

  bool _isInlineVehicle = false;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _vinCtrl;

  static const _fieldSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _start = a?.startAt ?? widget.initialStart;
    _end = a?.endAt ?? _start.add(const Duration(hours: 1));
    _bayId = a?.bayId ?? (widget.bays.isNotEmpty ? widget.bays.first.id : '');
    _vehicleId = a?.vehicleId ?? '';
    _status = a?.status ?? 'planned';
    _noteCtrl = TextEditingController(text: a?.note ?? '');
    _isInlineVehicle = widget.vehicles.isEmpty;
    _makeCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _plateCtrl = TextEditingController();
    _vinCtrl = TextEditingController();

    // Если авто найдено в каталоге — выбираем его
    if (a != null && a.vehicleId.isNotEmpty) {
      final vIdx = widget.vehicles.indexWhere((v) => v.id == a.vehicleId);
      if (vIdx >= 0) {
        _selectedVehicle = widget.vehicles[vIdx];
        _vehicleId = _selectedVehicle!.id;
        _isInlineVehicle = false;
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _vinCtrl.dispose();
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

            // Авто — autocomplete (поиск) или inline (создание)
            if (_isInlineVehicle) ...[
              _sectionLabel('Новое авто'),
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
                decoration: const InputDecoration(labelText: 'Госномер'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: _fieldSpacing),
              TextField(
                controller: _vinCtrl,
                decoration: const InputDecoration(labelText: 'VIN номер'),
                textCapitalization: TextCapitalization.characters,
              ),
              if (widget.vehicles.isNotEmpty) ...[
                const SizedBox(height: _fieldSpacing),
                TextButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Выбрать из каталога'),
                  onPressed: () => setState(() => _isInlineVehicle = false),
                ),
              ],
            ] else ...[
              _sectionLabel('Авто (поиск или создать новое)'),
              _vehicleAutocomplete(),
              const SizedBox(height: 8),
              TextField(
                controller: _makeCtrl,
                decoration: const InputDecoration(labelText: 'Марка (для нового авто)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: 'Модель'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'Госномер'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _vinCtrl,
                decoration: const InputDecoration(labelText: 'VIN номер'),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
            const SizedBox(height: _fieldSpacing),

            // Дата и время старта
            _sectionLabel('Начало'),
            Row(
              children: [
                Expanded(child: _dateTile(_start, 'Дата', true)),
                const SizedBox(width: 8),
                Expanded(child: _timeTile(_start, 'Время', true)),
              ],
            ),
            const SizedBox(height: _fieldSpacing),

            // Дата и время конца
            _sectionLabel('Конец'),
            Row(
              children: [
                Expanded(child: _dateTile(_end, 'Дата', false)),
                const SizedBox(width: 8),
                Expanded(child: _timeTile(_end, 'Время', false)),
              ],
            ),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDimOf(context),
        ),
      ),
    );
  }

  /// Плитка выбора даты.
  Widget _dateTile(DateTime dt, String label, bool isStart) {
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textOf(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  /// Плитка выбора времени (ручной ввод через TextField).
  Widget _timeTile(DateTime dt, String label, bool isStart) {
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textOf(context),
              ),
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
    final initial = isStart ? _start : _end;
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
        _start = DateTime(date.year, date.month, date.day, _start.hour, _start.minute);
        // Если end <= start — авто-сдвигаем
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = DateTime(date.year, date.month, date.day, _end.hour, _end.minute);
        // Если end стал <= start — авто-сдвигаем end на +1 день
        if (!_end.isAfter(_start)) {
          _end = _end.add(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
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
        _start = newDt;
        // Если end <= start — авто-сдвигаем
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        // Авто-сдвиг: если время раньше начала на той же дате — +1 день
        if (initial.year == _start.year &&
            initial.month == _start.month &&
            initial.day == _start.day &&
            newDt.isBefore(_start)) {
          _end = newDt.add(const Duration(days: 1));
        } else {
          _end = newDt;
        }
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
    } else if (_vehicleId.isEmpty && _makeCtrl.text.trim().isEmpty) {
      _snack('Выберите авто через поиск или введите марку нового');
      return;
    }
    if (!_end.isAfter(_start)) {
      _snack('Конец должен быть позже старта');
      return;
    }
    final duration = _end.difference(_start);
    if (duration.inDays > 7 || (duration.inDays == 7 && duration.inMinutes % (24 * 60) > 0)) {
      _snack('Максимальная длительность ремонта — 7 дней');
      return;
    }

    String vehicleId = _vehicleId;

    // Если заполнена марка — создаём новое авто (приоритет над autocomplete)
    if (_makeCtrl.text.trim().isNotEmpty) {
      try {
        final catApi = ref.read(catalogApiProvider);
        final newV = await catApi.createVehicle(Vehicle(
          id: '',
          shopId: '',
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          plate: _plateCtrl.text.trim().toUpperCase(),
          vin: _vinCtrl.text.trim().toUpperCase(),
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
