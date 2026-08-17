import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/catalog_api.dart';
import '../../data/models/catalog_models.dart';
import '../auth/auth_controller.dart';

/// Список постов (bays) + add/edit/delete.
class BaysScreen extends ConsumerStatefulWidget {
  const BaysScreen({super.key});

  @override
  ConsumerState<BaysScreen> createState() => _BaysScreenState();
}

class _BaysScreenState extends ConsumerState<BaysScreen> {
  List<Bay> _list = [];

  @override
  void initState() {
    super.initState();
    _loadWithAuth();
  }

  void _loadWithAuth() async {
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading || auth.valueOrNull == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) return _loadWithAuth();
      return;
    }
    _reload();
  }

  void _reload() async {
    _list = await ref.read(catalogApiProvider).listBays();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _list.isEmpty
          ? const Center(child: Text('Нет постов. Создайте первый.'))
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (c, i) {
                  final b = _list[i];
                  return ListTile(
                    leading: const Icon(Icons.garage_outlined),
                    title: Text(b.name),
                    subtitle: Text('Позиция: ${b.position} • ${b.isActive ? "Активен" : "Скрыт"}'),
                    onTap: () => _showEditDialog(b),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(b),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_bays',
        onPressed: () => _showEditDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(Bay? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final posCtrl = TextEditingController(text: '${existing?.position ?? 0}');
    bool isActive = existing?.isActive ?? true;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Изменить пост' : 'Новый пост'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'Название', floatingLabelBehavior: FloatingLabelBehavior.never),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: posCtrl,
                  decoration: const InputDecoration(hintText: 'Порядок (позиция)', floatingLabelBehavior: FloatingLabelBehavior.never),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Активен'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
              FilledButton(
                onPressed: () async {
                  final api = ref.read(catalogApiProvider);
                  final b = Bay(
                    id: existing?.id ?? '',
                    shopId: existing?.shopId ?? '',
                    name: nameCtrl.text.trim(),
                    position: int.tryParse(posCtrl.text) ?? 0,
                    isActive: isActive,
                  );
                  try {
                    if (isEdit) {
                      await api.updateBay(b);
                    } else {
                      await api.createBay(b);
                    }
                    if (c.mounted) Navigator.pop(c);
                    _reload();
                  } catch (e) {
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                    }
                  }
                },
                child: Text(isEdit ? 'Сохранить' : 'Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(Bay b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить пост?'),
        content: Text('"${b.name}" будет скрыт.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(catalogApiProvider).deleteBay(b.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
