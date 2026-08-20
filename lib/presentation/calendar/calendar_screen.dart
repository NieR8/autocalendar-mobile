import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/network/ws_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/appointment_api.dart';
import '../../data/api/catalog_api.dart';
import '../../data/api/export_api.dart';
import '../../data/demo_data.dart';
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';
import '../../utils/download_helper.dart';
import '../auth/auth_controller.dart';
import 'appointment_create_screen.dart';
import 'appointment_edit_dialog.dart';
import 'calendar_day_view.dart';
import 'calendar_month_view.dart';

/// Главный экран: календарь записей.
/// Переключение между Day View и Month View.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final PageController _pageController;
  final DateTime _windowStart = DateTime.now().subtract(const Duration(days: 7));
  final DateTime _windowEnd = DateTime.now().add(const Duration(days: 30));
  DateTime _selectedDay = DateTime.now();
  bool _isMonthView = false;

  List<models.Appointment> _appts = [];
  List<Bay> _bays = [];
  List<Vehicle> _vehicles = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _reloadAll();
    _connectWs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  /// Переключение дневной ↔ месячный через PageView slide-анимацию (300ms).
  void _switchToMonthView() {
    if (_isMonthView) return;
    setState(() => _isMonthView = true);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _switchToDayView() {
    if (!_isMonthView) return;
    setState(() => _isMonthView = false);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleView() {
    if (_isMonthView) {
      _switchToDayView();
    } else {
      _switchToMonthView();
    }
  }

  void _connectWs() {
    final ws = ref.read(wsClientProvider);
    ws.connect();
    _wsSub = ws.events.listen((e) {
      if (!mounted) return;
      switch (e.type) {
        case 'appointment.create':
          final newAppt = models.Appointment.fromJson(e.data);
          if (_appts.every((a) => a.id != newAppt.id)) {
            setState(() => _appts.add(newAppt));
          }
          break;
        case 'appointment.update':
          final updated = models.Appointment.fromJson(e.data);
          setState(() {
            final idx = _appts.indexWhere((a) => a.id == updated.id);
            if (idx >= 0) _appts[idx] = updated;
          });
          break;
        case 'appointment.delete':
          final id = e.data['id'] as String? ?? '';
          if (id.isNotEmpty) {
            setState(() => _appts.removeWhere((a) => a.id == id));
          }
          break;
      }
    });
  }

  Future<void> _reloadAll() async {
    // Демо-режим — моковые данные, без API.
    if (AppConfig.isDemoMode) {
      _appts = DemoData.appointments();
      _bays = DemoData.bays;
      _vehicles = DemoData.vehicles;
      _loading = false;
      if (mounted) setState(() {});
      return;
    }

    // Ждём auth state — без токена API запросы упадут с 401.
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading || auth.valueOrNull == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) return _reloadAll();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(appointmentApiProvider);
      final catApi = ref.read(catalogApiProvider);
      final results = await Future.wait([
        api.list(from: _windowStart, to: _windowEnd, includeRelations: true),
        catApi.listBays(),
        catApi.listVehicles(),
      ]);
      _appts = results[0] as List<models.Appointment>;
      _bays = results[1] as List<Bay>;
      _vehicles = results[2] as List<Vehicle>;
      _loading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _loading = false;
      _error = '$e';
      if (mounted) setState(() {});
    }
  }

  String _vehicleLabel(String vehicleId) {
    final v = _vehicles.firstWhere(
      (v) => v.id == vehicleId,
      orElse: () => Vehicle(id: vehicleId, shopId: ''),
    );
    return v.displayLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _toggleView,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('d MMMM, E', 'ru_RU').format(_selectedDay)),
                const SizedBox(width: 4),
                Icon(
                  _isMonthView ? Icons.calendar_month : Icons.view_day,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isMonthView ? Icons.view_day : Icons.calendar_month),
            onPressed: _toggleView,
            tooltip: _isMonthView ? 'Вид: день' : 'Вид: месяц',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => _selectedDay = DateTime.now());
            },
            tooltip: 'Сегодня',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadAll,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _reloadAll, child: const Text('Повторить')),
                    ],
                  ),
                )
              : PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _isMonthView = page == 1),
                  children: [
                    CalendarDayView(
                      bays: _bays,
                      appointments: _appts,
                      selectedDay: _selectedDay,
                      vehicleLabel: _vehicleLabel,
                      onDayChanged: (day) => setState(() => _selectedDay = day),
                      onSlotTap: (time) => _showCreateDialog(initialDate: time),
                      onAppointmentTap: (a) => _showEditDialog(a),
                      onStatusChanged: _changeStatus,
                      onDateHeaderTap: _switchToMonthView,
                    ),
                    CalendarMonthView(
                      appointments: _appts,
                      selectedDay: _selectedDay,
                      onDayChanged: (day) {
                        setState(() => _selectedDay = day);
                        // Тап на день в месячном — возвращаемся в дневной
                        _switchToDayView();
                      },
                    ),
                  ],
                ),
      floatingActionButton: _isMonthView
          ? null
          : FloatingActionButton(
              heroTag: 'fab_calendar',
              onPressed: () => _showCreateDialog(),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _changeStatus(models.Appointment a, String newStatus) async {
    if (AppConfig.isDemoMode) {
      setState(() {
        final idx = _appts.indexWhere((e) => e.id == a.id);
        if (idx >= 0) {
          _appts[idx] = models.Appointment(
            id: a.id, shopId: a.shopId, bayId: a.bayId, vehicleId: a.vehicleId,
            startAt: a.startAt, endAt: a.endAt, status: newStatus, note: a.note,
            createdBy: a.createdBy,
            version: a.version,
          );
        }
      });
      return;
    }
    try {
      final api = ref.read(appointmentApiProvider);
      final updated = await api.update(a.id, {'status': newStatus});
      setState(() {
        final idx = _appts.indexWhere((e) => e.id == a.id);
        if (idx >= 0) _appts[idx] = updated;
      });
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  void _showCreateDialog({DateTime? initialDate}) async {
    final start = initialDate ?? DateTime(
      _selectedDay.year, _selectedDay.month, _selectedDay.day,
      DateTime.now().hour, 0,
    );
    final result = await Navigator.of(context).push<models.Appointment>(
      MaterialPageRoute(
        builder: (c) => AppointmentCreateScreen(
          bays: _bays,
          vehicles: _vehicles,
          initialDate: start,
        ),
      ),
    );
    if (result == null) return;
    if (AppConfig.isDemoMode) {
      // Демо-режим — добавляем локально
      final newAppt = models.Appointment(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        shopId: 'demo-shop', bayId: result.bayId, vehicleId: result.vehicleId,
        startAt: result.startAt, endAt: result.endAt,
        status: 'planned', note: result.note,
      );
      setState(() => _appts.add(newAppt));
      return;
    }
    try {
      final api = ref.read(appointmentApiProvider);
      final created = await api.create(result);
      final catApi = ref.read(catalogApiProvider);
      final newVehicles = await catApi.listVehicles();
      setState(() {
        _appts.add(created);
        _vehicles = newVehicles;
      });
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  void _showEditDialog(models.Appointment a) async {
    // Открываем отдельную страницу для редактирования (как при создании).
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (c) => AppointmentCreateScreen(
          bays: _bays,
          vehicles: _vehicles,
          initialDate: a.startAt,
          existingAppointment: a,
        ),
      ),
    );
    if (result == null) return;
    try {
      final api = ref.read(appointmentApiProvider);
      if (result == 'delete') {
        await api.delete(a.id);
        setState(() => _appts.removeWhere((e) => e.id == a.id));
        return;
      }
      if (result is models.Appointment) {
        final updated = await api.update(a.id, {
          'bay_id': result.bayId,
          'vehicle_id': result.vehicleId,
          'start_at': result.startAt.toUtc().toIso8601String(),
          'end_at': result.endAt.toUtc().toIso8601String(),
          'status': result.status,
          'note': result.note,
        });
        // Перезагружаем vehicles — авто могло быть обновлено
        // (марка/модель/клиент изменены в форме редактирования).
        final catApi = ref.read(catalogApiProvider);
        final newVehicles = await catApi.listVehicles();
        setState(() {
          final idx = _appts.indexWhere((e) => e.id == a.id);
          if (idx >= 0) _appts[idx] = updated;
          _vehicles = newVehicles;
        });
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 409) {
      _snack('Конфликт: на этом посту уже есть запись в этом времени');
    } else {
      _snack('Ошибка ${e.response?.statusCode}: ${e.message}');
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _exportXlsx() async {
    try {
      final api = ref.read(exportApiProvider);
      final bytes = await api.exportXlsx(from: _windowStart, to: _windowEnd);
      final filename = 'appointments_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      saveFileAs(bytes, filename,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      _snack('Экспортировано: $filename');
    } catch (e) {
      _snack('Ошибка экспорта: $e');
    }
  }
}
