import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кастомный radial time picker в стиле Material You.
/// 24-часовой формат: два концентрических круга (1-12 внешний, 13-24 внутренний).
/// При переключении на минуты: шаг 5 минут (0, 5, 10... 55).
class RadialTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const RadialTimePicker({
    super.key,
    required this.initialTime,
  });

  @override
  State<RadialTimePicker> createState() => _RadialTimePickerState();
}

class _RadialTimePickerState extends State<RadialTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  bool _isHourMode = true;
  bool _isInnerCircle = false; // true если выбран внутренний круг (13-24)

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isInnerCircle = _selectedHour >= 13;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Дисплей времени
            _buildTimeDisplay(),
            const SizedBox(height: 24),
            // Циферблат
            _buildClockFace(),
            const SizedBox(height: 24),
            // Переключатель часы/минуты
            _buildModeToggle(),
            const SizedBox(height: 16),
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
                  onPressed: () => Navigator.of(context).pop(
                    TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                  ),
                  child: const Text('ОК'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final colorScheme = Theme.of(context).colorScheme;
    final hourStr = _selectedHour.toString().padLeft(2, '0');
    final minuteStr = _selectedMinute.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimePart(hourStr, _isHourMode),
        Text(
          ':',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        _buildTimePart(minuteStr, !_isHourMode),
      ],
    );
  }

  Widget _buildTimePart(String text, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildClockFace() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      height: 280,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        child: CustomPaint(
          painter: _RadialClockPainter(
            selectedHour: _selectedHour,
            selectedMinute: _selectedMinute,
            isHourMode: _isHourMode,
            isInnerCircle: _isInnerCircle,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Часы')),
        ButtonSegment(value: false, label: Text('Минуты')),
      ],
      selected: {_isHourMode},
      onSelectionChanged: (selection) {
        setState(() {
          _isHourMode = selection.first;
        });
      },
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _updateTimeFromPosition(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _updateTimeFromPosition(details.localPosition);
  }

  void _updateTimeFromPosition(Offset position) {
    const centerX = 140.0;
    const centerY = 140.0;
    const outerRadius = 120.0;
    const innerRadius = 80.0;

    final dx = position.dx - centerX;
    final dy = position.dy - centerY;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (_isHourMode) {
      // Режим часов
      final isInner = distance < (outerRadius + innerRadius) / 2;
      final angle = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi);
      var hour = ((angle / (2 * math.pi) * 12).round() % 12);
      
      if (isInner) {
        // Внутренний круг: 13-24 (или 0)
        hour = hour == 0 ? 0 : hour + 12;
        HapticFeedback.lightImpact();
      } else {
        // Внешний круг: 1-12
        hour = hour == 0 ? 12 : hour;
        HapticFeedback.lightImpact();
      }

      if (hour != _selectedHour || isInner != _isInnerCircle) {
        setState(() {
          _selectedHour = hour;
          _isInnerCircle = isInner;
        });
      }
    } else {
      // Режим минут: шаг 5 минут
      final angle = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi);
      final minute = ((angle / (2 * math.pi) * 60).round() ~/ 5) * 5;
      final normalizedMinute = minute % 60;

      if (normalizedMinute != _selectedMinute) {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMinute = normalizedMinute;
        });
      }
    }
  }
}

/// CustomPainter для отрисовки циферблата.
class _RadialClockPainter extends CustomPainter {
  final int selectedHour;
  final int selectedMinute;
  final bool isHourMode;
  final bool isInnerCircle;
  final ColorScheme colorScheme;

  _RadialClockPainter({
    required this.selectedHour,
    required this.selectedMinute,
    required this.isHourMode,
    required this.isInnerCircle,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const outerRadius = 120.0;
    const innerRadius = 80.0;

    // Фон циферблата
    final bgPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), outerRadius, bgPaint);

    if (isHourMode) {
      // Режим часов: два круга
      _drawHourCircle(canvas, centerX, centerY, outerRadius, 1, 12, false);
      _drawHourCircle(canvas, centerX, centerY, innerRadius, 13, 24, true);
      _drawHand(canvas, centerX, centerY, selectedHour, isInnerCircle ? innerRadius : outerRadius);
    } else {
      // Режим минут: один круг с шагом 5 минут
      _drawMinuteCircle(canvas, centerX, centerY, outerRadius);
      _drawHand(canvas, centerX, centerY, selectedMinute ~/ 5, outerRadius);
    }
  }

  void _drawHourCircle(Canvas canvas, double centerX, double centerY, double radius, int start, int end, bool isInner) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = start; i <= end; i++) {
      final hour = i == 24 ? 0 : i;
      final angle = (hour / 12) * 2 * math.pi - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      final isSelected = (isInner && isInnerCircle) || (!isInner && !isInnerCircle)
          ? selectedHour == hour
          : false;

      if (isSelected) {
        final selectedPaint = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 18, selectedPaint);
      }

      final textStyle = TextStyle(
        fontSize: isInner ? 14 : 18,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      );

      textPainter.text = TextSpan(
        text: hour.toString(),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawMinuteCircle(Canvas canvas, double centerX, double centerY, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 60; i += 5) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      final isSelected = selectedMinute == i;

      if (isSelected) {
        final selectedPaint = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 18, selectedPaint);
      }

      final textStyle = TextStyle(
        fontSize: 18,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      );

      textPainter.text = TextSpan(
        text: i.toString().padLeft(2, '0'),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawHand(Canvas canvas, double centerX, double centerY, int value, double radius) {
    final angle = isHourMode
        ? ((value % 12) / 12) * 2 * math.pi - math.pi / 2
        : (value / 12) * 2 * math.pi - math.pi / 2;
    
    final handLength = radius - 10;
    final endX = centerX + handLength * math.cos(angle);
    final endY = centerY + handLength * math.sin(angle);

    final handPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), handPaint);

    // Точка в центре
    final centerPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialClockPainter oldDelegate) {
    return oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute ||
        oldDelegate.isHourMode != isHourMode ||
        oldDelegate.isInnerCircle != isInnerCircle;
  }
}
