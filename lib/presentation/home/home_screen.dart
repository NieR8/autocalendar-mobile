import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../calendar/calendar_screen.dart';
import '../catalog/catalog_screen.dart';
import 'home_dashboard.dart';

/// Главное приложение — 4 таба: Главная / Календарь / Каталоги / Профиль.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  void _navigateToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: [
          HomeDashboard(onNavigateToTab: _navigateToTab),
          const CalendarScreen(),
          const CatalogScreen(),
          const _ProfileScreen(),
        ][_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Каталоги',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Профиль — имя, роль, shop_id, вход/выход, настройки.
class _ProfileScreen extends ConsumerWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final state = auth.valueOrNull;
    final isLoggedIn = state != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Аватар + имя
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (state?.displayName ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state?.displayName ?? 'Гость',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOf(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  state?.role == 'owner' ? 'Владелец' : 'Работник',
                  style: TextStyle(color: AppTheme.textDimOf(context), fontSize: 14),
                ),
                if (state != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${state.shopId.substring(0, 8)}...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Кнопка войти/выйти
          if (isLoggedIn)
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            )
          else
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Войти'),
              onPressed: () {},
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Настройки
          Text('Настройки',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOf(context))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Уведомления'),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Язык'),
            subtitle: const Text('Русский'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Тёмная тема'),
            trailing: Switch(
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                  v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            subtitle: const Text('Версия 0.1.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
