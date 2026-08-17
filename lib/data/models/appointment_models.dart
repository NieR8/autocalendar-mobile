import 'package:intl/intl.dart';

/// Запись на ремонт.
class Appointment {
  final String id;
  final String shopId;
  final String bayId;
  final String vehicleId;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String note;
  final String createdBy;
  final int version;

  /// Опциональные relations (когда include=tags,services в запросе).
  final List<AppointmentService>? services;
  final List<TagRef>? tags;
  final WorkOrderRef? workOrder;

  /// Опционально — для UI: данные авто и поста (подтягиваются отдельно).
  final String? bayName;
  final String? vehicleLabel;

  Appointment({
    required this.id,
    required this.shopId,
    required this.bayId,
    required this.vehicleId,
    required this.startAt,
    required this.endAt,
    this.status = 'planned',
    this.note = '',
    this.createdBy = '',
    this.version = 1,
    this.services,
    this.tags,
    this.workOrder,
    this.bayName,
    this.vehicleLabel,
  });

  factory Appointment.fromJson(Map<String, dynamic> j) {
    return Appointment(
      id: j['id'] ?? '',
      shopId: j['shop_id'] ?? '',
      bayId: j['bay_id'] ?? '',
      vehicleId: j['vehicle_id'] ?? '',
      startAt: DateTime.parse(j['start_at'] as String).toLocal(),
      endAt: DateTime.parse(j['end_at'] as String).toLocal(),
      status: j['status'] ?? 'planned',
      note: j['note'] ?? '',
      createdBy: j['created_by'] ?? '',
      version: (j['version'] as num?)?.toInt() ?? 1,
      services: (j['services'] as List?)
          ?.map((e) => AppointmentService.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (j['tags'] as List?)
          ?.map((e) => TagRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      workOrder: j['work_order'] != null
          ? WorkOrderRef.fromJson(j['work_order'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'bay_id': bayId,
        'vehicle_id': vehicleId,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'status': status,
        'note': note,
      };

  /// Краткая подпись для карточки в календаре.
  String get shortLabel => vehicleLabel ?? vehicleId.substring(0, 8);

  /// Цвет по статусу (Warm Workshop палитра).
  int get colorValue {
    switch (status) {
      case 'in_progress':
        return 0xFFD4A14B; // янтарный
      case 'ready':
        return 0xFF5A7D3A; // оливковый
      default:
        return 0xFF6B8DB5; // мягкий синий (planned)
    }
  }

  /// Форматированный диапазон времени (24-часовой формат) для tooltip.
  String get timeRange =>
      '${DateFormat.Hm().format(startAt)}–${DateFormat.Hm().format(endAt)}';
}

/// Услуга в записи (чек-лист).
class AppointmentService {
  final String id;
  final String appointmentId;
  final String serviceId;
  final int qty;
  final bool isCompleted;
  final int version;

  AppointmentService({
    required this.id,
    required this.appointmentId,
    required this.serviceId,
    this.qty = 1,
    this.isCompleted = false,
    this.version = 1,
  });

  factory AppointmentService.fromJson(Map<String, dynamic> j) =>
      AppointmentService(
        id: j['id'] ?? '',
        appointmentId: j['appointment_id'] ?? '',
        serviceId: j['service_id'] ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        isCompleted: j['is_completed'] ?? false,
        version: (j['version'] as num?)?.toInt() ?? 1,
      );
}

/// Метка (краткая, для отображения в записи).
class TagRef {
  final String id;
  final String name;
  final String color;
  TagRef({required this.id, required this.name, this.color = '#3B82F6'});

  factory TagRef.fromJson(Map<String, dynamic> j) => TagRef(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        color: j['color'] ?? '#3B82F6',
      );
}

/// Заказ-наряд (краткая форма для списка записей).
class WorkOrderRef {
  final String id;
  final double totalSum;
  final double paid;
  final double balance;

  WorkOrderRef({
    required this.id,
    this.totalSum = 0,
    this.paid = 0,
    this.balance = 0,
  });

  factory WorkOrderRef.fromJson(Map<String, dynamic> j) => WorkOrderRef(
        id: j['id'] ?? '',
        totalSum: (j['total_sum'] as num?)?.toDouble() ?? 0,
        paid: (j['paid'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
      );
}
