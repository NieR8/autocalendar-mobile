import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/api/work_order_api.dart';
import '../../data/models/work_order_models.dart';

/// Экран заказ-наряда: сумма/оплата/долг + позиции.
class WorkOrderScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String appointmentLabel;

  const WorkOrderScreen({
    super.key,
    required this.appointmentId,
    this.appointmentLabel = '',
  });

  @override
  ConsumerState<WorkOrderScreen> createState() => _WorkOrderScreenState();
}

class _WorkOrderScreenState extends ConsumerState<WorkOrderScreen> {
  WorkOrder? _wo;
  List<WorkOrderItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(workOrderApiProvider);
      final wo = await api.getByAppointment(widget.appointmentId);
      if (wo == null) {
        _wo = null;
        _items = [];
      } else {
        _wo = wo;
        _items = await api.listItems(wo.id);
      }
      _loading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _loading = false;
      _error = '$e';
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заказ-наряд')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _wo == null
                  ? _emptyState()
                  : _body(),
      floatingActionButton: _wo != null
          ? FloatingActionButton.extended(
              heroTag: 'fab_work_order',
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Позиция'),
            )
          : null,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Заказ-наряд ещё не создан'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Создать заказ-наряд'),
            onPressed: _create,
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final wo = _wo!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.appointmentLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(widget.appointmentLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        _summaryCard(wo),
        const SizedBox(height: 16),
        const Text('Позиции',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          const ListTile(title: Text('Нет позиций'))
        else
          ..._items.map(_itemTile),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _summaryCard(WorkOrder wo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сумма:'),
                Text('${wo.totalSum.toStringAsFixed(0)} руб',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Оплачено:'),
                Text('${wo.paid.toStringAsFixed(0)} руб',
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Долг:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${wo.balance.toStringAsFixed(0)} руб',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: wo.balance > 0 ? Colors.red : Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Отметить оплату'),
                    onPressed: () => _addPayment(wo),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'Заметка',
                  onPressed: () => _editNotes(wo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(WorkOrderItem item) {
    return ListTile(
      leading: CircleAvatar(child: Text('${item.qty}x')),
      title: Text(item.description),
      subtitle: Text(
          '${item.price.toStringAsFixed(0)} руб/шт • Итого: ${item.lineTotal.toStringAsFixed(0)} руб'),
      onTap: () => _editItem(item),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _deleteItem(item),
      ),
    );
  }

  Future<void> _create() async {
    try {
      await ref.read(workOrderApiProvider).createForAppointment(widget.appointmentId);
      _load();
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  Future<void> _addItem() async {
    final item = await _showItemDialog(null);
    if (item == null) return;
    try {
      await ref.read(workOrderApiProvider).addItem(_wo!.id, item);
      _load();
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  Future<void> _editItem(WorkOrderItem item) async {
    final updated = await _showItemDialog(item);
    if (updated == null) return;
    try {
      await ref.read(workOrderApiProvider).updateItem(_wo!.id, updated);
      _load();
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  Future<void> _deleteItem(WorkOrderItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('"${item.description}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(workOrderApiProvider).deleteItem(_wo!.id, item.id);
      _load();
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  Future<WorkOrderItem?> _showItemDialog(WorkOrderItem? existing) async {
    final isEdit = existing != null;
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final qtyCtrl = TextEditingController(text: '${existing?.qty ?? 1}');
    final priceCtrl = TextEditingController(text: '${existing?.price ?? 0}');
    return showDialog<WorkOrderItem>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(isEdit ? 'Изменить позицию' : 'Новая позиция'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Описание', floatingLabelBehavior: FloatingLabelBehavior.never), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(hintText: 'Количество', floatingLabelBehavior: FloatingLabelBehavior.never), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, decoration: const InputDecoration(hintText: 'Цена за единицу', floatingLabelBehavior: FloatingLabelBehavior.never), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                c,
                WorkOrderItem(
                  id: existing?.id ?? '',
                  workOrderId: existing?.workOrderId ?? _wo!.id,
                  description: descCtrl.text.trim(),
                  qty: int.tryParse(qtyCtrl.text) ?? 1,
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  position: existing?.position ?? _items.length,
                ),
              );
            },
            child: Text(isEdit ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(WorkOrder wo) async {
    final amountCtrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Отметить оплату'),
        content: TextField(
          controller: amountCtrl,
          decoration: InputDecoration(
              labelText: 'Сумма оплаты (долг: ${wo.balance.toStringAsFixed(0)} руб)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(c, double.tryParse(amountCtrl.text) ?? 0),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      final newPaid = wo.paid + amount;
      await ref.read(workOrderApiProvider).update(wo.id, paid: newPaid);
      _load();
      _snack('Оплата ${amount.toStringAsFixed(0)} руб принята');
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  Future<void> _editNotes(WorkOrder wo) async {
    final notesCtrl = TextEditingController(text: wo.notes);
    final notes = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Заметка по наряду'),
        content: TextField(controller: notesCtrl, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(c, notesCtrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (notes == null) return;
    try {
      await ref.read(workOrderApiProvider).update(wo.id, notes: notes);
      _load();
    } catch (e) {
      _snack('Ошибка: $e');
    }
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
