import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/catalog_api.dart';
import '../../data/models/catalog_models.dart';
import '../auth/auth_controller.dart';

/// Каталог меток.
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});
  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  List<Tag> _list = [];

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
    _list = await ref.read(catalogApiProvider).listTags();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _list.isEmpty
          ? const Center(child: Text('Нет меток. Создайте первую.'))
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (c, i) {
                  final t = _list[i];
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: _parseColor(t.color),
                        child: const Icon(Icons.label_outline, color: Colors.white)),
                    title: Text(t.name),
                    onTap: () => _showEditDialog(t),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(t),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tags',
        onPressed: () => _showEditDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _parseColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    return Colors.blue;
  }

  void _showEditDialog(Tag? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? '#3B82F6');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(isEdit ? 'Изменить метку' : 'Новая метка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Название', floatingLabelBehavior: FloatingLabelBehavior.never),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(hintText: 'Цвет (HEX, напр. #FF0000)', floatingLabelBehavior: FloatingLabelBehavior.never)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final t = Tag(
                id: existing?.id ?? '',
                shopId: existing?.shopId ?? '',
                name: nameCtrl.text.trim(),
                color: colorCtrl.text.trim().isEmpty ? '#3B82F6' : colorCtrl.text.trim(),
              );
              try {
                if (isEdit) {
                  await ref.read(catalogApiProvider).updateTag(t);
                } else {
                  await ref.read(catalogApiProvider).createTag(t);
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
      ),
    );
  }

  Future<void> _delete(Tag t) async {
    try {
      await ref.read(catalogApiProvider).deleteTag(t.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
