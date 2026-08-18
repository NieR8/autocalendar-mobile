import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_models.dart' as models;

/// Месячный календарь — фиксированная сетка 7×6 (всегда 6 недель).
/// Крупные квадратные ячейки (childAspectRatio: 1.0) — как в классическом
/// мобильном календаре. Листание месяцами через стрелки.
class CalendarMonthView extends StatefulWidget {
  final List<models.Appointment> appointments;
  final DateTime selectedDay;
  final Function(DateTime) onDayChanged;

  const CalendarMonthView({
    super.key,
    required this.appointments,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  State<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends State<CalendarMonthView> {
  late DateTime _monthStart;

  @override
  void initState() {
    super.initState();
    _monthStart = _firstOfMonth(widget.selectedDay);
  }

  @override
  void didUpdateWidget(CalendarMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay.month != widget.selectedDay.month ||
        oldWidget.selectedDay.year != widget.selectedDay.year) {
      _monthStart = _firstOfMonth(widget.selectedDay);
    }
  }

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// Все апты которые пересекаются с этим днём (включая многосуточные).
  /// Апт считается находящимся на дне, если [dayStart, dayEnd) пересекается с [appt.startAt, appt.endAt).
  List<models.Appointment> _appointmentsOnDay(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return widget.appointments.where((a) {
      // Есть пересечение если: a.startAt < dayEnd AND a.endAt > dayStart
      return a.startAt.isBefore(dayEnd) && a.endAt.isAfter(dayStart);
    }).toList();
  }

  Color _dayColor(DateTime date, bool isDark) {
    final appts = _appointmentsOnDay(date);
    if (appts.isEmpty) return Colors.transparent;

    bool hasProgress = appts.any((a) => a.status == 'in_progress');
    bool hasReady = appts.any((a) => a.status == 'ready');
    bool hasPlanned = appts.any((a) => a.status == 'planned');

    if (isDark) {
      if (hasProgress) return const Color(0xFFE8A317).withOpacity(0.25);
      if (hasReady) return const Color(0xFF22C55E).withOpacity(0.25);
      if (hasPlanned) return const Color(0xFF3B82F6).withOpacity(0.25);
    } else {
      if (hasProgress) return AppTheme.statusProgress.withOpacity(0.5);
      if (hasReady) return AppTheme.statusReady.withOpacity(0.5);
      if (hasPlanned) return AppTheme.statusPlanned.withOpacity(0.5);
    }
    return Colors.transparent;
  }

  Color _dayBorderColor(DateTime date, bool isDark) {
    final appts = _appointmentsOnDay(date);
    if (appts.isEmpty) return Colors.transparent;

    bool hasProgress = appts.any((a) => a.status == 'in_progress');
    bool hasReady = appts.any((a) => a.status == 'ready');
    bool hasPlanned = appts.any((a) => a.status == 'planned');

    if (hasProgress) return isDark ? const Color(0xFFE8A317) : AppTheme.statusProgress;
    if (hasReady) return isDark ? const Color(0xFF22C55E) : AppTheme.statusReady;
    if (hasPlanned) return isDark ? const Color(0xFF3B82F6) : AppTheme.statusPlanned;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.text;
    final dimColor = isDark ? AppTheme.darkTextDim : AppTheme.textDim;
    final muteColor = isDark ? AppTheme.darkTextMute : AppTheme.textMute;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.bg;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : AppTheme.surface2;

    return Column(
      children: [
        // Заголовок месяца
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: bgColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () {
                  setState(() {
                    _monthStart = DateTime(_monthStart.year, _monthStart.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy', 'ru_RU').format(_monthStart),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () {
                  setState(() {
                    _monthStart = DateTime(_monthStart.year, _monthStart.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ),
        // Дни недели
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: bgColor,
          child: Row(
            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dimColor),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Сетка дней — 6 недель × 7 дней, квадратные ячейки
        Expanded(
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final date = _dateForCell(index);
                if (date == null) {
                  return const SizedBox.shrink();
                }

                final isToday = _isToday(date);
                final isSelected = _isSelected(date);
                final isCurrentMonth = date.month == _monthStart.month;
                final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                final dayColor = _dayColor(date, isDark);
                final dayBorder = _dayBorderColor(date, isDark);
                final apptCount = _appointmentsOnDay(date).length;
                final apptsForDots = _appointmentsOnDay(date);

                return GestureDetector(
                  onTap: () => widget.onDayChanged(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: dayColor != Colors.transparent
                          ? dayColor
                          : (isSelected ? cardColor : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (dayBorder != Colors.transparent ? dayBorder.withOpacity(0.4) : Colors.transparent),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isCurrentMonth
                                ? (isToday ? AppTheme.primary : (isWeekend ? AppTheme.danger.withOpacity(0.7) : textColor))
                                : muteColor,
                          ),
                        ),
                        if (apptCount > 0) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              apptCount > 3 ? 3 : apptCount,
                              (i) => Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                decoration: BoxDecoration(
                                  color: _dotColor(apptsForDots[i].status, isDark),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Легенда
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: bgColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem('Запланировано', isDark ? const Color(0xFF3B82F6) : AppTheme.statusPlanned, dimColor),
              _legendItem('В работе', isDark ? const Color(0xFFE8A317) : AppTheme.statusProgress, dimColor),
              _legendItem('Готово', isDark ? const Color(0xFF22C55E) : AppTheme.statusReady, dimColor),
            ],
          ),
        ),
      ],
    );
  }

  Color _dotColor(String status, bool isDark) {
    switch (status) {
      case 'in_progress':
        return isDark ? const Color(0xFFE8A317) : AppTheme.statusProgress;
      case 'ready':
        return isDark ? const Color(0xFF22C55E) : AppTheme.statusReady;
      default:
        return isDark ? const Color(0xFF3B82F6) : AppTheme.statusPlanned;
    }
  }

  Widget _legendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textColor)),
      ],
    );
  }

  DateTime? _dateForCell(int index) {
    final firstDayOfMonth = DateTime(_monthStart.year, _monthStart.month, 1);
    final weekday = firstDayOfMonth.weekday;
    final offset = weekday - 1;
    final dayNumber = index - offset + 1;
    if (dayNumber < 1) return null;
    final daysInMonth = DateTime(_monthStart.year, _monthStart.month + 1, 0).day;
    if (dayNumber > daysInMonth) return null;
    return DateTime(_monthStart.year, _monthStart.month, dayNumber);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == widget.selectedDay.year &&
        date.month == widget.selectedDay.month &&
        date.day == widget.selectedDay.day;
  }
}
