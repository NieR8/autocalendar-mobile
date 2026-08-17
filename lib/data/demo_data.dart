/// Моковые данные для демо-режима (без backend).
/// Используются когда API_BASE_URL не задан или backend недоступен.
import '../../data/models/appointment_models.dart' as models;
import '../../data/models/catalog_models.dart';

class DemoData {
  static const String shopId = 'demo-shop';
  static const String userId = 'demo-user';

  static List<Bay> bays = [
    Bay(id: 'bay-1', shopId: shopId, name: 'Слесарные работы', position: 1),
    Bay(id: 'bay-2', shopId: shopId, name: 'Диагностика', position: 2),
    Bay(id: 'bay-3', shopId: shopId, name: 'Шиномонтаж', position: 3),
  ];

  static List<Service> services = [
    Service(id: 'svc-1', shopId: shopId, name: 'Замена масла', durationMin: 60, price: 1500),
    Service(id: 'svc-2', shopId: shopId, name: 'Диагностика двигателя', durationMin: 90, price: 2500),
    Service(id: 'svc-3', shopId: shopId, name: 'Шиномонтаж (4 колеса)', durationMin: 45, price: 2000),
    Service(id: 'svc-4', shopId: shopId, name: 'Замена тормозных колодок', durationMin: 120, price: 3500),
  ];

  static List<Vehicle> vehicles = [
    Vehicle(id: 'veh-1', shopId: shopId, make: 'Toyota', model: 'Camry', plate: 'А123БВ77', customerName: 'Иван', customerPhone: '+79991234567'),
    Vehicle(id: 'veh-2', shopId: shopId, make: 'BMW', model: 'X5', plate: 'Х777АВ77', customerName: 'Алексей', customerPhone: '+79997654321'),
    Vehicle(id: 'veh-3', shopId: shopId, make: 'Lada', model: 'Vesta', plate: 'В456ГД77', customerName: 'Сергей', customerPhone: '+79001112233'),
    Vehicle(id: 'veh-4', shopId: shopId, make: 'Kia', model: 'Rio', plate: 'Е789ЖЗ77', customerName: 'Мария', customerPhone: '+79123334455'),
  ];

  static List<Tag> tags = [
    Tag(id: 'tag-1', shopId: shopId, name: 'Срочная', color: '#EF4444'),
    Tag(id: 'tag-2', shopId: shopId, name: 'Гарантия', color: '#10B981'),
  ];

  static List<models.Appointment> appointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      models.Appointment(
        id: 'appt-1', shopId: shopId, bayId: 'bay-1', vehicleId: 'veh-1',
        startAt: today.copyWith(hour: 9, minute: 0),
        endAt: today.copyWith(hour: 11, minute: 0),
        status: 'in_progress', note: 'Замена масла | Проверить фильтры',
      ),
      models.Appointment(
        id: 'appt-2', shopId: shopId, bayId: 'bay-2', vehicleId: 'veh-2',
        startAt: today.copyWith(hour: 10, minute: 0),
        endAt: today.copyWith(hour: 12, minute: 0),
        status: 'planned', note: 'Диагностика двигателя',
      ),
      models.Appointment(
        id: 'appt-3', shopId: shopId, bayId: 'bay-3', vehicleId: 'veh-3',
        startAt: today.copyWith(hour: 13, minute: 0),
        endAt: today.copyWith(hour: 14, minute: 0),
        status: 'ready', note: 'Шиномонтаж завершён',
      ),
      models.Appointment(
        id: 'appt-4', shopId: shopId, bayId: 'bay-1', vehicleId: 'veh-4',
        startAt: today.copyWith(hour: 14, minute: 0),
        endAt: today.copyWith(hour: 16, minute: 0),
        status: 'planned', note: 'Замена тормозных колодок',
      ),
      models.Appointment(
        id: 'appt-5', shopId: shopId, bayId: 'bay-2', vehicleId: 'veh-1',
        startAt: today.copyWith(hour: 16, minute: 0),
        endAt: today.copyWith(hour: 17, minute: 30),
        status: 'planned', note: 'Повторная диагностика',
      ),
      models.Appointment(
        id: 'appt-6', shopId: shopId, bayId: 'bay-3', vehicleId: 'veh-2',
        startAt: today.add(const Duration(days: 1)).copyWith(hour: 9, minute: 0),
        endAt: today.add(const Duration(days: 1)).copyWith(hour: 10, minute: 30),
        status: 'planned', note: 'Балансировка колёс',
      ),
    ];
  }

  static String vehicleLabel(String vehicleId) {
    final v = vehicles.firstWhere(
      (v) => v.id == vehicleId,
      orElse: () => Vehicle(id: vehicleId, shopId: '', make: '?', model: ''),
    );
    return v.displayLabel;
  }
}
