import 'package:dating_assistant/presentation/splash/splash/splash_screen.dart';
import 'package:flutter/material.dart';

/// Корневой виджет приложения (аналог SceneDelegate): тема и стартовый экран.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating Assistant',
      debugShowCheckedModeBanner: false,
      // Временная тема: заменим цветами и шрифтами из Figma.
      theme: ThemeData(colorSchemeSeed: Colors.pink),
      home: const SplashScreen(),
    );
  }
}
