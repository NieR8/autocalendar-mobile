import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Гибридный time picker: переключение между барабаном и ручным вводом.
/// Поддерживает предпросмотр длительности.
class HybridTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final TimeOfDay? startTime; // Для предпросмотра длительности (только для end time)

  const HybridTimePicker({
    super.key,
    required this.initialTime,
    this.startTime,
  });

  @override
  State<HybridTimePicker> createState() => _HybridTimePickerState();
}

class _HybridTimePickerState extends State<HybridTimePicker> {
  late TimeOfDay _selectedTime;
  bool _isDrumMode = true;
  late TextEditingController _hourCtrl;
  late TextEditingController _minuteCtrl;
  String? _error;
  final _hourFocusNode = FocusNode();
  final _minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _hourCtrl = TextEditingController(
      text: widget.initialTime.hour.toString().padLeft(2, '0'),
    );
    _minuteCtrl = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  String? _validateTime() {
    final hStr = _hourCtrl.text.trim().padLeft(2, '0');
    final mStr = _minuteCtrl.text.trim().padLeft(2, '0');
    final h = int.tryParse(hStr);
    final m = int.tryParse(mStr);

    if (h == null || m == null) {
      return 'Только цифры';
    }
    if (h < 0 || h > 23) {
      return 'Часы: 00-23';
    }
    if (m < 0 || m > 59) {
      return 'Минуты: 00-59';
    }
    return null;
  }

  TimeOfDay? _getTimeFromInputs() {
    final hStr = _hourCtrl.text.trim().padLeft(2, '0');
    final mStr = _minuteCtrl.text.trim().padLeft(2, '0');
    final h = int.tryParse(hStr);
    final m = int.tryParse(mStr);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours ч ${minutes} мин';
    } else if (hours > 0) {
      return '$hours ч';
    } else {
      return '$minutes мин';
    }
  }

  String? _getDurationPreview() {
    if (widget.startTime == null) return null;
    final currentTime = _isDrumMode ? _selectedTime : _getTimeFromInputs();
    if (currentTime == null) return null;

    final startMinutes = widget.startTime!.hour * 60 + widget.startTime!.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    var diff = currentMinutes - startMinutes;

    // Если время меньше начала — значит переход через полночь
    if (diff < 0) {
      diff += 24 * 60;
    }

    if (diff > 0) {
      return 'Длительность: ${_formatDuration(Duration(minutes: diff))}';
    }
    return null;
  }

  void _submit() {
    if (_isDrumMode) {
      Navigator.of(context).pop(_selectedTime);
    } else {
      final error = _validateTime();
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      final time = _getTimeFromInputs();
      if (time != null) {
        Navigator.of(context).pop(time);
      }
    }
  }

  Future<void> _openDrumPicker() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface2
                  : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedTime = result;
        _hourCtrl.text = result.hour.toString().padLeft(2, '0');
        _minuteCtrl.text = result.minute.toString().padLeft(2, '0');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.darkSurface2 : Colors.white;
    final durationPreview = _getDurationPreview();

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Переключатель режима
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Барабан'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Ручной ввод'),
                  icon: Icon(Icons.keyboard),
                ),
              ],
              selected: {_isDrumMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _isDrumMode = selection.first;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // Режим барабана
            if (_isDrumMode) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOf(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openDrumPicker,
                icon: const Icon(Icons.schedule),
                label: const Text('Выбрать время'),
              ),
            ] else ...[
              // Режим ручного ввода
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Часы
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
                        color: AppTheme.textOf(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'ЧЧ',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: BorderSide(
                            color: _error != null && _error!.contains('Часы')
                                ? AppTheme.danger
                                : AppTheme.borderOf(context),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: BorderSide(
                            color: _error != null && _error!.contains('Часы')
                                ? AppTheme.danger
                                : AppTheme.borderOf(context),
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
                      onChanged: (value) {
                        setState(() => _error = null);
                        if (value.length == 2) {
                          _minuteFocusNode.requestFocus();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textOf(context),
                      ),
                    ),
                  ),
                  // Минуты
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
                        color: AppTheme.textOf(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'ММ',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: BorderSide(
                            color: _error != null && _error!.contains('Минуты')
                                ? AppTheme.danger
                                : AppTheme.borderOf(context),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: BorderSide(
                            color: _error != null && _error!.contains('Минуты')
                                ? AppTheme.danger
                                : AppTheme.borderOf(context),
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
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '24-часовой формат',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextMute : AppTheme.textMute,
                  ),
                ),
              ),
            ],

            // Предпросмотр длительности
            if (durationPreview != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    durationPreview,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('ОК'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
