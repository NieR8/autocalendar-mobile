import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/catalog_models.dart';

/// Страница поиска авто с анимацией.
/// Возвращает выбранное авто или null если отмена.
class VehicleSearchScreen extends ConsumerStatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;

  const VehicleSearchScreen({
    super.key,
    required this.vehicles,
    this.selectedVehicle,
  });

  @override
  ConsumerState<VehicleSearchScreen> createState() => _VehicleSearchScreenState();
}

class _VehicleSearchScreenState extends ConsumerState<VehicleSearchScreen> {
  late TextEditingController _searchCtrl;
  List<Vehicle> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(_filterVehicles);
    _filteredVehicles = widget.vehicles;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterVehicles() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = widget.vehicles;
      } else {
        _filteredVehicles = widget.vehicles.where((v) {
          return v.make.toLowerCase().contains(query) ||
              v.model.toLowerCase().contains(query) ||
              v.plate.toLowerCase().contains(query) ||
              v.vin.toLowerCase().contains(query) ||
              v.customerName.toLowerCase().contains(query) ||
              v.customerPhone.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор авто'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderOf(context),
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Поиск по марке, модели, госномеру, VIN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filterVehicles();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface2 : AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(color: AppTheme.borderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(color: AppTheme.borderOf(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Список авто
          Expanded(
            child: _filteredVehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textMuteOf(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Авто не найдено',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuteOf(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _filteredVehicles[index];
                      final isSelected = widget.selectedVehicle?.id == vehicle.id;

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(vehicle),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withOpacity(0.1)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.borderOf(context),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: AppTheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.displayLabel,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textOf(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (vehicle.plate.isNotEmpty) vehicle.plate,
                                        if (vehicle.vin.isNotEmpty) 'VIN: ${vehicle.vin}',
                                      ].join(' • '),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textMuteOf(context),
                                      ),
                                    ),
                                    if (vehicle.customerName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Клиент: ${vehicle.customerName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuteOf(context),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: открыть создание нового авто
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
