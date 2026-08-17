import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../data/api/catalog_api.dart';
import '../../data/demo_data.dart';
import '../../data/models/catalog_models.dart';
import '../auth/auth_controller.dart';
import 'service_edit_screen.dart';

/// Каталог услуг.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});
  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  List<Service> _list = [];

  @override
  void initState() {
    super.initState();
    _loadWithAuth();
  }

  void _loadWithAuth() async {
    if (AppConfig.isDemoMode) {
      _list = DemoData.services;
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
      _list = DemoData.services;
    } else {
      _list = await ref.read(catalogApiProvider).listServices();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _list.isEmpty
          ? const Center(child: Text('Нет услуг. Создайте первую.'))
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (c, i) {
                  final s = _list[i];
                  return ListTile(
                    leading: const Icon(Icons.build_outlined),
                    title: Text(s.name),
                    subtitle: Text('${s.durationMin} мин • ${s.price.toStringAsFixed(0)} руб'),
                    onTap: () async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => ServiceEditScreen(service: s)),
                      );
                      _reload();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(s),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_services',
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ServiceEditScreen()),
          );
          _reload();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(Service s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить услугу?'),
        content: Text('"${s.name}" будет скрыта.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(catalogApiProvider).deleteService(s.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
