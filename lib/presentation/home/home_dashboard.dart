import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../calendar/calendar_screen.dart';
import '../catalog/catalog_screen.dart';

/// Главная — dashboard с theme-aware цветами.
class HomeDashboard extends ConsumerStatefulWidget {
  final Function(int) onNavigateToTab;

  const HomeDashboard({super.key, required this.onNavigateToTab});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Главная',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                  color: AppTheme.textOf(context),
                ),
              ),
              const SizedBox(height: 24),

              _bigButton(
                context: context,
                icon: Icons.add_circle,
                label: 'Запись на ремонт',
                subtitle: 'Создать новую запись в календаре',
                onTap: () => widget.onNavigateToTab(1),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _card(context: context,
                    icon: Icons.people_outline, label: 'Клиенты', subtitle: 'Справочник',
                    onTap: () => widget.onNavigateToTab(2))),
                  const SizedBox(width: 12),
                  Expanded(child: _card(context: context,
                    icon: Icons.search, label: 'Диагностика', subtitle: 'Скоро', onTap: () {})),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _card(context: context,
                    icon: Icons.build_outlined, label: 'Сервис', subtitle: 'Скоро', onTap: () {})),
                  const SizedBox(width: 12),
                  Expanded(child: _card(context: context,
                    icon: Icons.assessment_outlined, label: 'Отчёты', subtitle: 'Скоро', onTap: () {})),
                ],
              ),
              const SizedBox(height: 24),

              _newsSection(context),
            ],
          ),
        ),
      );
    }

  Widget _bigButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textOf(context))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuteOf(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, size: 20, color: AppTheme.textDimOf(context)),
            const SizedBox(width: 8),
            Text('Новости',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textOf(context))),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Все новости')),
          ],
        ),
        const SizedBox(height: 8),
        _newsItem(context,
          title: 'Обновление календаря',
          text: 'Добавлены новые функции: барабанный time picker, недельный скроллер',
          date: 'сегодня'),
        _newsItem(context,
          title: 'Экспорт в Excel',
          text: 'Теперь можно выгрузить все записи за период в .xlsx',
          date: 'вчера'),
        _newsItem(context,
          title: 'Заказ-наряды',
          text: 'Создавайте наряды с позициями, отслеживайте оплату и долг',
          date: '2 дня назад'),
      ],
    );
  }

  Widget _newsItem(BuildContext context, {
    required String title,
    required String text,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textOf(context))),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(fontSize: 12, color: AppTheme.textDimOf(context))),
                const SizedBox(height: 4),
                Text(date,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuteOf(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
