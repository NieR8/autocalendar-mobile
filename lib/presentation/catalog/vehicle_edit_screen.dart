import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/catalog_api.dart';
import '../../data/models/catalog_models.dart';

/// Страница создания/редактирования авто.
class VehicleEditScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const VehicleEditScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;
  bool get _isEdit => widget.vehicle != null;

  static const _spacing = 16.0;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _plateCtrl = TextEditingController(text: v?.plate ?? '');
    _vinCtrl = TextEditingController(text: v?.vin ?? '');
    _nameCtrl = TextEditingController(text: v?.customerName ?? '');
    _phoneCtrl = TextEditingController(text: v?.customerPhone ?? '');
    _notesCtrl = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _vinCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Марка'),
                    TextField(
                      controller: _makeCtrl,
                      decoration: const InputDecoration(hintText: 'Марка', floatingLabelBehavior: FloatingLabelBehavior.never),
                      autofocus: true,
                    ),
                    const SizedBox(height: _spacing),
                    _label('Модель'),
                    TextField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(hintText: 'Модель', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('Госномер'),
                    TextField(
                      controller: _plateCtrl,
                      decoration: const InputDecoration(hintText: 'Госномер', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('VIN'),
                    TextField(
                      controller: _vinCtrl,
                      decoration: const InputDecoration(hintText: 'VIN', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('Имя владельца'),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Имя', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('Телефон владельца'),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Телефон', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: _spacing),
                    _label('Заметки'),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Заметки', floatingLabelBehavior: FloatingLabelBehavior.never),
                    ),
                    const SizedBox(height: 24),
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
          Icon(Icons.directions_car, size: 22, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(_isEdit ? 'Изменить авто' : 'Новое авто',
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
    if (_makeCtrl.text.trim().isEmpty && _plateCtrl.text.trim().isEmpty) {
      _snack('Введите марку или госномер');
      return;
    }
    final v = Vehicle(
      id: widget.vehicle?.id ?? '',
      shopId: widget.vehicle?.shopId ?? '',
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      plate: _plateCtrl.text.trim(),
      vin: _vinCtrl.text.trim(),
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    try {
      final api = ref.read(catalogApiProvider);
      if (_isEdit) await api.updateVehicle(v);
      else await api.createVehicle(v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
