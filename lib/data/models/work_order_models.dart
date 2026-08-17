/// Заказ-наряд (1:1 с appointment) + позиции.
class WorkOrder {
  final String id;
  final String shopId;
  final String appointmentId;
  final double totalSum;
  final double paid;
  final double balance;
  final String notes;
  final int version;

  WorkOrder({
    required this.id,
    required this.shopId,
    required this.appointmentId,
    this.totalSum = 0,
    this.paid = 0,
    this.balance = 0,
    this.notes = '',
    this.version = 1,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> j) => WorkOrder(
        id: j['id'] ?? '',
        shopId: j['shop_id'] ?? '',
        appointmentId: j['appointment_id'] ?? '',
        totalSum: (j['total_sum'] as num?)?.toDouble() ?? 0,
        paid: (j['paid'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        notes: j['notes'] ?? '',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  /// isFullyPaid — долг = 0 и total > 0.
  bool get isFullyPaid => totalSum > 0 && balance <= 0;
}

/// Позиция в наряде.
class WorkOrderItem {
  final String id;
  final String workOrderId;
  final String description;
  final int qty;
  final double price;
  final int position;
  final int version;

  WorkOrderItem({
    required this.id,
    required this.workOrderId,
    required this.description,
    this.qty = 1,
    this.price = 0,
    this.position = 0,
    this.version = 1,
  });

  factory WorkOrderItem.fromJson(Map<String, dynamic> j) => WorkOrderItem(
        id: j['id'] ?? '',
        workOrderId: j['work_order_id'] ?? '',
        description: j['description'] ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        position: (j['position'] as num?)?.toInt() ?? 0,
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  double get lineTotal => qty * price;

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'description': description,
        'qty': qty,
        'price': price,
        'position': position,
      };
}
