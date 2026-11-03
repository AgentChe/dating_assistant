import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/presentation/main/profile/profile_screen.dart';
import 'package:flutter/material.dart';

/// Главный экран: сюда встанет основная фича по макету из Figma.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static Route<void> route() => FadePageRoute(builder: (_) => const MainScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dating Assistant'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(ProfileScreen.route()),
          ),
        ],
      ),
      body: const Center(child: Text('Main feature goes here')),
    );
  }
}
