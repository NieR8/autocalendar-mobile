import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/catalog_models.dart';

/// API-клиент для каталогов: bays, services, tags, vehicles.
/// Один класс на все 4 сущности — они однотипные CRUD.
class CatalogApi {
  final Dio _dio;
  CatalogApi(this._dio);

  // --- Bays ---
  Future<List<Bay>> listBays() async {
    final r = await _dio.get('/api/bays');
    return _asList(r.data).map((e) => Bay.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bay> createBay(Bay b) async {
    final r = await _dio.post('/api/bays', data: b.toJson());
    return Bay.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateBay(Bay b) async =>
      _dio.patch('/api/bays/${b.id}', data: b.toJson());

  Future<void> deleteBay(String id) async =>
      _dio.delete('/api/bays/$id');

  // --- Services ---
  Future<List<Service>> listServices() async {
    final r = await _dio.get('/api/services');
    return _asList(r.data).map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Service> createService(Service s) async {
    final r = await _dio.post('/api/services', data: s.toJson());
    return Service.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateService(Service s) async =>
      _dio.patch('/api/services/${s.id}', data: s.toJson());

  Future<void> deleteService(String id) async =>
      _dio.delete('/api/services/$id');

  // --- Tags ---
  Future<List<Tag>> listTags() async {
    final r = await _dio.get('/api/tags');
    return _asList(r.data).map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Tag> createTag(Tag t) async {
    final r = await _dio.post('/api/tags', data: t.toJson());
    return Tag.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateTag(Tag t) async =>
      _dio.patch('/api/tags/${t.id}', data: t.toJson());

  Future<void> deleteTag(String id) async =>
      _dio.delete('/api/tags/$id');

  // --- Vehicles ---
  Future<List<Vehicle>> listVehicles() async {
    final r = await _dio.get('/api/vehicles');
    return _asList(r.data).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> createVehicle(Vehicle v) async {
    final r = await _dio.post('/api/vehicles', data: v.toJson());
    return Vehicle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> updateVehicle(Vehicle v) async =>
      _dio.patch('/api/vehicles/${v.id}', data: v.toJson());

  Future<void> deleteVehicle(String id) async =>
      _dio.delete('/api/vehicles/$id');
}

List<dynamic> _asList(dynamic d) => (d as List?)?.toList() ?? [];

final catalogApiProvider = Provider<CatalogApi>((ref) {
  return CatalogApi(ref.watch(dioProvider));
});
