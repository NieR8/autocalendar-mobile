import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/work_order_models.dart';

/// API-клиент для заказ-нарядов.
class WorkOrderApi {
  final Dio _dio;
  WorkOrderApi(this._dio);

  /// Получить наряд по appointment id.
  Future<WorkOrder?> getByAppointment(String apptId) async {
    try {
      final r = await _dio.get('/api/appointments/$apptId/work-order');
      return WorkOrder.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Создать наряд для записи (если уже есть — возвращает существующий).
  Future<WorkOrder> createForAppointment(String apptId) async {
    final r = await _dio.post('/api/appointments/$apptId/work-order');
    return WorkOrder.fromJson(r.data as Map<String, dynamic>);
  }

  /// Обновить наряд (total/paid/notes — patch).
  Future<WorkOrder> update(String woId,
      {double? totalSum, double? paid, String? notes}) async {
    final patch = <String, dynamic>{};
    if (totalSum != null) patch['total_sum'] = totalSum;
    if (paid != null) patch['paid'] = paid;
    if (notes != null) patch['notes'] = notes;
    final r = await _dio.patch('/api/work-orders/$woId', data: patch);
    return WorkOrder.fromJson(r.data as Map<String, dynamic>);
  }

  /// Список позиций наряда.
  Future<List<WorkOrderItem>> listItems(String woId) async {
    final r = await _dio.get('/api/work-orders/$woId/items');
    final list = (r.data as List?) ?? [];
    return list
        .map((e) => WorkOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Добавить позицию.
  Future<WorkOrderItem> addItem(String woId, WorkOrderItem item) async {
    final r = await _dio.post('/api/work-orders/$woId/items', data: item.toJson());
    return WorkOrderItem.fromJson(r.data as Map<String, dynamic>);
  }

  /// Обновить позицию.
  Future<void> updateItem(String woId, WorkOrderItem item) async =>
      _dio.patch('/api/work-orders/$woId/items/${item.id}', data: item.toJson());

  /// Удалить позицию.
  Future<void> deleteItem(String woId, String itemId) async =>
      _dio.delete('/api/work-orders/$woId/items/$itemId');
}

final workOrderApiProvider = Provider<WorkOrderApi>((ref) {
  return WorkOrderApi(ref.watch(dioProvider));
});
