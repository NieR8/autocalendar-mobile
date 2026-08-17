import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../data/api/catalog_api.dart';
import '../../data/demo_data.dart';
import '../../data/models/catalog_models.dart';
import '../auth/auth_controller.dart';
import 'vehicle_edit_screen.dart';

/// Каталог авто.
class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});
  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  List<Vehicle> _list = [];

  @override
  void initState() {
    super.initState();
    _loadWithAuth();
  }

  void _loadWithAuth() async {
    if (AppConfig.isDemoMode) {
      _list = DemoData.vehicles;
      if (mounted) setState(() {});
      return;
    }
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading || auth.valueOrNull == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) return _loadWithAuth();
      return;
    }
    _reload();
  }

  void _reload() async {
    if (AppConfig.isDemoMode) {
      _list = DemoData.vehicles;
    } else {
      _list = await ref.read(catalogApiProvider).listVehicles();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_list.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('Нет авто. Создайте первое.')),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_vehicles',
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const VehicleEditScreen()),
            );
            _reload();
          },
          child: const Icon(Icons.add),
        ),
      );
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView.builder(
          itemCount: _list.length,
          itemBuilder: (c, i) {
            final v = _list[i];
            return ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(v.displayLabel),
              subtitle: Text([
                if (v.customerName.isNotEmpty) 'Владелец: ${v.customerName}',
                if (v.customerPhone.isNotEmpty) v.customerPhone,
              ].join(' • ')),
              onTap: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => VehicleEditScreen(vehicle: v)),
                );
                _reload();
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(v),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_vehicles',
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const VehicleEditScreen()),
          );
          _reload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(Vehicle v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить авто?'),
        content: Text('"${v.displayLabel}" будет удалён из каталога.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(catalogApiProvider).deleteVehicle(v.id);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить авто (возможно, оно используется в записях): $e')),
        );
      }
    }
  }
}
