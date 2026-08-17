import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/appointment_models.dart';

/// API-клиент для /api/appointments и суб-ресурсов.
class AppointmentApi {
  final Dio _dio;
  AppointmentApi(this._dio);

  /// Список записей в диапазоне дат.
  /// include=tags,services — чтобы получить с relations в одном запросе.
  Future<List<Appointment>> list({
    DateTime? from,
    DateTime? to,
    String? bayId,
    String? status,
    String? tagId,
    bool includeRelations = true,
  }) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();
    if (bayId != null && bayId.isNotEmpty) params['bay_id'] = bayId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (tagId != null && tagId.isNotEmpty) params['tag_id'] = tagId;
    if (includeRelations) params['include'] = 'tags,services';
    final r = await _dio.get('/api/appointments', queryParameters: params);
    final list = (r.data as List?) ?? [];
    return list
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> create(Appointment a) async {
    final r = await _dio.post('/api/appointments', data: a.toJson());
    return Appointment.fromJson(r.data as Map<String, dynamic>);
  }

  /// Patch — обновить часть полей. Используется для drag-reschedule
  /// (меняем bay_id + start_at + end_at) и смены статуса.
  Future<Appointment> update(String id, Map<String, dynamic> patch) async {
    final r = await _dio.patch('/api/appointments/$id', data: patch);
    return Appointment.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async => _dio.delete('/api/appointments/$id');

  /// Отметить услугу выполненной (worker-мутация, идёт в офлайн-очередь).
  Future<void> markServiceCompleted(String apptServiceId) async =>
      _dio.patch('/api/appointments/_/services/$apptServiceId');
}

final appointmentApiProvider = Provider<AppointmentApi>((ref) {
  return AppointmentApi(ref.watch(dioProvider));
});
