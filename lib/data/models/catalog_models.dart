/// Модели каталога: Bay, Service, Tag, Vehicle.
/// Все сущности в одном файле для компактности MVP.

class Bay {
  final String id;
  final String shopId;
  final String name;
  final int position;
  final bool isActive;
  final int version;

  Bay({
    required this.id,
    required this.shopId,
    required this.name,
    this.position = 0,
    this.isActive = true,
    this.version = 1,
  });

  factory Bay.fromJson(Map<String, dynamic> j) => Bay(
        id: j['id'] ?? '',
        shopId: j['shop_id'] ?? '',
        name: j['name'] ?? '',
        position: (j['position'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] ?? true,
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'position': position,
        'is_active': isActive,
      };
}

class Service {
  final String id;
  final String shopId;
  final String name;
  final int durationMin;
  final double price;
  final bool isActive;
  final int version;

  Service({
    required this.id,
    required this.shopId,
    required this.name,
    this.durationMin = 60,
    this.price = 0,
    this.isActive = true,
    this.version = 1,
  });

  factory Service.fromJson(Map<String, dynamic> j) => Service(
        id: j['id'] ?? '',
        shopId: j['shop_id'] ?? '',
        name: j['name'] ?? '',
        durationMin: (j['duration_min'] as num?)?.toInt() ?? 60,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        isActive: j['is_active'] ?? true,
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'duration_min': durationMin,
        'price': price,
        'is_active': isActive,
      };
}

class Tag {
  final String id;
  final String shopId;
  final String name;
  final String color;
  final int version;

  Tag({
    required this.id,
    required this.shopId,
    required this.name,
    this.color = '#3B82F6',
    this.version = 1,
  });

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
        id: j['id'] ?? '',
        shopId: j['shop_id'] ?? '',
        name: j['name'] ?? '',
        color: j['color'] ?? '#3B82F6',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'color': color,
      };
}

class Vehicle {
  final String id;
  final String shopId;
  final String make;
  final String model;
  final String plate;
  final String vin;
  final String customerName;
  final String customerPhone;
  final String notes;
  final int version;

  Vehicle({
    required this.id,
    required this.shopId,
    this.make = '',
    this.model = '',
    this.plate = '',
    this.vin = '',
    this.customerName = '',
    this.customerPhone = '',
    this.notes = '',
    this.version = 1,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] ?? '',
        shopId: j['shop_id'] ?? '',
        make: j['make'] ?? '',
        model: j['model'] ?? '',
        plate: j['plate'] ?? '',
        vin: j['vin'] ?? '',
        customerName: j['customer_name'] ?? '',
        customerPhone: j['customer_phone'] ?? '',
        notes: j['notes'] ?? '',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'make': make,
        'model': model,
        'plate': plate,
        'vin': vin,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'notes': notes,
      };

  String get displayLabel {
    final parts = [make, model, plate].where((s) => s.isNotEmpty);
    return parts.isEmpty ? '(без данных)' : parts.join(' ');
  }
}
