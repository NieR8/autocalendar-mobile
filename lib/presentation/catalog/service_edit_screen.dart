import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/catalog_models.dart';

/// Страница создания/редактирования услуги.
class ServiceEditScreen extends ConsumerStatefulWidget {
  final Service? service;

  const ServiceEditScreen({super.key, this.service});

  @override
  ConsumerState<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends ConsumerState<ServiceEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _durCtrl;
  late final TextEditingController _priceCtrl;
  bool _isActive = true;
  bool get _isEdit => widget.service != null;

  static const _spacing = 16.0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _durCtrl = TextEditingController(text: '${widget.service?.durationMin ?? 60}');
    _priceCtrl = TextEditingController(text: '${widget.service?.price ?? 0}');
    _isActive = widget.service?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Название'),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Название услуги', floatingLabelBehavior: FloatingLabelBehavior.never),
                      autofocus: true,
                    ),
                    const SizedBox(height: _spacing),
                    _label('Длительность (мин)'),
                    TextField(
                      controller: _durCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Минуты', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('Цена (руб)'),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Рубли', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    SwitchListTile(title: const Text('Активна'), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                    const Spacer(),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(_isEdit ? 'Сохранить' : 'Создать', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.build, size: 22, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(_isEdit ? 'Изменить услугу' : 'Новая услуга',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textOf(context))),
          const Spacer(),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 18, color: AppTheme.primary),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDimOf(context))),
    );
  }

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Введите название');
      return;
    }
    final s = Service(
      id: widget.service?.id ?? '',
      shopId: widget.service?.shopId ?? '',
      name: _nameCtrl.text.trim(),
      durationMin: int.tryParse(_durCtrl.text) ?? 60,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      isActive: _isActive,
    );
    try {
      final api = ref.read(catalogApiProvider);
      if (_isEdit) await api.updateService(s);
      else await api.createService(s);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
