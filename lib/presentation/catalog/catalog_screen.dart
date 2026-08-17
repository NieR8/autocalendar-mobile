import 'package:flutter/material.dart';

import 'services_screen.dart';
import 'vehicles_screen.dart';

/// Каталоги: 2 таба — Услуги / Авто.
/// Посты создаются автоматически при регистрации (3 по умолчанию).
/// Метки — опциональны, не нужны в MVP.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Каталоги'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.build_outlined), text: 'Услуги'),
              Tab(icon: Icon(Icons.directions_car_outlined), text: 'Авто'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ServicesScreen(),
            VehiclesScreen(),
          ],
        ),
      ),
    );
  }
}
