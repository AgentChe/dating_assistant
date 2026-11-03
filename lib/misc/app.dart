import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Корневой виджет приложения (аналог SceneDelegate): тема и стартовый экран.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: Fonts.family,
        scaffoldBackgroundColor: Appearance.black,
        colorScheme: const ColorScheme.dark(primary: Appearance.accent, surface: Appearance.black),
        splashFactory: NoSplash.splashFactory,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Appearance.accent,
          selectionColor: Color(0x66FF7D56),
          selectionHandleColor: Appearance.accent,
        ),
      ),
      // Интерфейс тёмный — светлые значки в статус-баре и тёмная навигация Android.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Appearance.black,
        ),
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
