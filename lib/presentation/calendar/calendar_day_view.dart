import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';

/// Кастомный Day View — таблица с theme-aware цветами (светлая/тёмная).
class CalendarDayView extends StatefulWidget {
  final List<Bay> bays;
  final List<models.Appointment> appointments;
  final DateTime selectedDay;
  final String Function(String) vehicleLabel;
  final Function(DateTime) onDayChanged;
  final Function(DateTime) onSlotTap;
  final Function(models.Appointment) onAppointmentTap;
  final Function(models.Appointment, String)? onStatusChanged;

  const CalendarDayView({
    super.key,
    required this.bays,
    required this.appointments,
    required this.selectedDay,
    required this.vehicleLabel,
    required this.onDayChanged,
    required this.onSlotTap,
    required this.onAppointmentTap,
    this.onStatusChanged,
  });

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  static const int _startHour = 8;
  static const int _endHour = 21;
  static const double _slotHeight = 36.0;
  static const double _timeColWidth = 44.0;
  static const double _dayScrollerHeight = 52.0;
  static const double _bayHeaderHeight = 48.0;
  late PageController _weekPageController;
  static const int _totalWeeks = 104;
  static const int _currentWeekIndex = 52;

  static const List<IconData> _bayIcons = [
    Icons.build, Icons.search, Icons.tire_repair, Icons.bolt, Icons.car_repair,
  ];

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: _currentWeekIndex);
  }

  @override
  void didUpdateWidget(CalendarDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      final weekIndex = _weekIndexOf(widget.selectedDay);
      if (_weekPageController.hasClients &&
          (_weekPageController.page?.round() ?? _currentWeekIndex) != weekIndex) {
        _weekPageController.animateToPage(weekIndex,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _mondayOfWeek(DateTime date) {
    final d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  int _weekIndexOf(DateTime date) {
    final baseMonday = _mondayOfWeek(DateTime.now());
    final origin = baseMonday.subtract(const Duration(days: 7 * 52));
    final originMonday = _mondayOfWeek(origin);
    final dateMonday = _mondayOfWeek(_dateOnly(date));
    return dateMonday.difference(originMonday).inDays ~/ 7;
  }

  int get _totalSlots => (_endHour - _startHour) * 2;

  List<models.Appointment> get _dayAppointments =>
      widget.appointments.where((a) {
        return a.startAt.year == widget.selectedDay.year &&
            a.startAt.month == widget.selectedDay.month &&
            a.startAt.day == widget.selectedDay.day;
      }).toList();

  double _apptTop(models.Appointment a) {
    final mins = a.startAt.hour * 60 + a.startAt.minute - _startHour * 60;
    return (mins / 30) * _slotHeight;
  }

  double _apptHeight(models.Appointment a) {
    final dur = a.endAt.difference(a.startAt);
    return (dur.inMinutes / 30) * _slotHeight - 2;
  }

  IconData _bayIcon(int index) => _bayIcons[index % _bayIcons.length];

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: AppTheme.borderOf(context).withOpacity(0.3), width: 0.5);
    return Column(
      children: [
        // Блок 1: дата — с нижней границей
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            border: Border(bottom: BorderSide(color: AppTheme.borderOf(context).withOpacity(0.3), width: 0.5)),
          ),
          child: _buildDateHeader(context),
        ),
        // Блок 2: скроллер дней — с отступами сверху/снизу + нижняя граница
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            border: Border(bottom: BorderSide(color: AppTheme.borderOf(context).withOpacity(0.3), width: 0.5)),
          ),
          child: _buildWeekScroller(context),
        ),
        // Блок 3: заголовки постов — с нижней границей
        _buildBayHeaders(context),
        // Блок 4: таблица
        Expanded(child: _buildCalendarGrid(context)),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final day = widget.selectedDay;
    final isToday = _isToday(day);
    final dateStr = DateFormat('d MMMM', 'ru_RU').format(day);
    final weekdayStr = DateFormat('EEEE', 'ru_RU').format(day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10.5),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18,
              color: isToday ? AppTheme.primary : AppTheme.textDimOf(context)),
          const SizedBox(width: 8),
          Text(dateStr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isToday ? AppTheme.primary : AppTheme.textOf(context),
              )),
          const SizedBox(width: 8),
          Text(weekdayStr,
              style: TextStyle(fontSize: 13, color: AppTheme.textDimOf(context))),
        ],
      ),
    );
  }

  Widget _buildWeekScroller(BuildContext context) {
    // Базовый понедельник: текущая неделя минус 52 недели назад.
    final baseMonday =
        _mondayOfWeek(DateTime.now()).subtract(const Duration(days: 7 * 52));
    final dayFmt = DateFormat('E', 'ru_RU');
    final numFmt = DateFormat('d');

    return SizedBox(
      height: _dayScrollerHeight,
      child: PageView.builder(
        controller: _weekPageController,
        scrollDirection: Axis.horizontal,
        itemCount: _totalWeeks,
        // physics оставляем дефолтный — свайп между неделями
        itemBuilder: (context, weekIndex) {
          final weekMonday = baseMonday.add(Duration(days: weekIndex * 7));
          return Row(
            children: List.generate(7, (dayIndex) {
              final date = weekMonday.add(Duration(days: dayIndex));
              final isSelected = date.year == widget.selectedDay.year &&
                  date.month == widget.selectedDay.month &&
                  date.day == widget.selectedDay.day;
              final isToday = _isToday(date);
              final isWeekend =
                  date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onDayChanged(date),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : isToday
                              ? AppTheme.primary.withOpacity(0.06)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayFmt.format(date).substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isWeekend
                                    ? AppTheme.danger.withOpacity(0.7)
                                    : AppTheme.textMuteOf(context),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          numFmt.format(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected ? Colors.white : AppTheme.textOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildBayHeaders(BuildContext context) {
    return Container(
      height: _bayHeaderHeight,
      decoration: BoxDecoration(
        color: AppTheme.surface2Of(context),
        border: Border(bottom: BorderSide(color: AppTheme.borderOf(context), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(width: _timeColWidth),
          ...widget.bays.asMap().entries.map((entry) {
            final idx = entry.key;
            final bay = entry.value;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderOf(context), width: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_bayIcon(idx), size: 18, color: AppTheme.primary),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        bay.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDimOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    if (widget.bays.isEmpty) {
      return Center(child: Text('Нет постов', style: TextStyle(color: AppTheme.textDimOf(context))));
    }

    return SingleChildScrollView(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeColumn(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.bays.map((bay) {
                  final bayAppts =
                      _dayAppointments.where((a) => a.bayId == bay.id).toList();
                  return Expanded(child: _buildBayColumn(context, bayAppts));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context) {
    return SizedBox(
      width: _timeColWidth,
      child: Column(
        children: List.generate(_totalSlots, (i) {
          final hour = _startHour + (i ~/ 2);
          final minute = (i % 2) * 30;
          final isHour = minute == 0;
          return Container(
            height: _slotHeight,
            padding: const EdgeInsets.only(right: 4, top: 1),
            alignment: Alignment.topRight,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.borderOf(context), width: 0.5),
                bottom: BorderSide(
                    color: AppTheme.borderOf(context).withOpacity(0.25), width: 0.5),
              ),
            ),
            child: Text(
              isHour ? '$hour:00' : '',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textMuteOf(context),
                fontWeight: isHour ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBayColumn(BuildContext context, List<models.Appointment> appts) {
    return Stack(
      children: [
        Column(
          children: List.generate(_totalSlots, (i) {
            final hour = _startHour + (i ~/ 2);
            final minute = (i % 2) * 30;
            return GestureDetector(
              onTap: () {
                final slotTime = DateTime(
                  widget.selectedDay.year,
                  widget.selectedDay.month,
                  widget.selectedDay.day,
                  hour,
                  minute,
                );
                widget.onSlotTap(slotTime);
              },
              child: Container(
                height: _slotHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppTheme.borderOf(context).withOpacity(0.25),
                        width: 0.5),
                    right: BorderSide(color: AppTheme.borderOf(context), width: 0.5),
                  ),
                ),
              ),
            );
          }),
        ),
        ...appts.map((a) => _buildAppointmentCard(context, a)),
        if (_isToday(widget.selectedDay)) _buildNowLine(context),
      ],
    );
  }

  Widget _buildAppointmentCard(BuildContext context, models.Appointment a) {
    final top = _apptTop(a);
    final height = _apptHeight(a);
    final color = AppTheme.statusColor(a.status);
    final label = widget.vehicleLabel(a.vehicleId);

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height,
      child: GestureDetector(
        onTap: () => widget.onAppointmentTap(a),
        onLongPress: () => _showStatusMenu(context, a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            border: Border(left: BorderSide(color: color, width: 2.5)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (height > 24) ...[
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.darken(),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (height > 44)
                  Text(
                    DateFormat.Hm().format(a.startAt),
                    style: TextStyle(fontSize: 8, color: AppTheme.textMuteOf(context)),
                  ),
              ] else
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.darken(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNowLine(BuildContext context) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute - _startHour * 60;
    if (nowMins < 0 || nowMins > (_endHour - _startHour) * 60) {
      return const SizedBox.shrink();
    }
    final top = (nowMins / 30) * _slotHeight;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.nowLine, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: AppTheme.nowLine)),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showStatusMenu(BuildContext context, models.Appointment a) {
    final color = AppTheme.statusColor(a.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Изменить статус',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textOf(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statusButton(ctx, a, 'planned', 'В планах',
                      a.status == 'planned'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(ctx, a, 'in_progress', 'В работе',
                      a.status == 'in_progress'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(ctx, a, 'ready', 'Готово',
                      a.status == 'ready'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(BuildContext ctx, models.Appointment a, String status,
      String label, bool isActive) {
    final color = AppTheme.statusColor(status);
    return GestureDetector(
      onTap: () {
        if (widget.onStatusChanged != null) {
          widget.onStatusChanged!(a, status);
        }
        Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : AppTheme.borderOf(context),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? color : AppTheme.textDimOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorDarken on Color {
  Color darken([double amount = 0.25]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0, 1)).toColor();
  }
}
