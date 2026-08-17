import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'core/theme/app_theme.dart';
import 'router.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // AnnotatedRegion пересоздаётся при смене темы — статус бар красится заново.
    // Светлая: #F0F4F8 + светлые иконки (невидимы)
    // Тёмная:  #1C1C1E + тёмные иконки (невидимы)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? AppTheme.darkBg : AppTheme.bg,
        statusBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
        systemNavigationBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'AutoCalendar',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru', 'RU')],
        locale: const Locale('ru', 'RU'),
      ),
    );
  }
}
