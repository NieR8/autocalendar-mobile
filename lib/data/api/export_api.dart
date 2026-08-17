import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// API-клиент для экспорта записей.
/// GET /api/appointments/export?format=xlsx&from=&to=...
class ExportApi {
  final Dio _dio;
  ExportApi(this._dio);

  /// Скачать .xlsx за период. Возвращает байты файла.
  Future<List<int>> exportXlsx({
    DateTime? from,
    DateTime? to,
    String? bayId,
    String? status,
    String? tagId,
  }) async {
    final params = <String, dynamic>{'format': 'xlsx'};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();
    if (bayId != null && bayId.isNotEmpty) params['bay_id'] = bayId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (tagId != null && tagId.isNotEmpty) params['tag_id'] = tagId;
    final r = await _dio.get<List<int>>(
      '/api/appointments/export',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return r.data ?? [];
  }
}

final exportApiProvider = Provider<ExportApi>((ref) {
  return ExportApi(ref.watch(dioProvider));
});
