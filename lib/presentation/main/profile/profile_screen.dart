import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const ProfileScreen());

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _viewModel = ProfileViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _viewModel.profile;

    // Временная вёрстка: экран соберём по макету из Figma.
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile == null
          ? null
          : ListView(
              children: [
                ListTile(title: const Text('Name'), trailing: Text(profile.name ?? '—')),
                ListTile(title: const Text('Gender'), trailing: Text(profile.gender.title)),
                ListTile(title: const Text('Age'), trailing: Text(profile.ageRange.title)),
                ListTile(title: const Text('Looking for'), trailing: Text(profile.goal.title)),
                ListTile(title: const Text('Voice'), trailing: Text(profile.voice.summary)),
                ListTile(title: const Text('Default spice'), trailing: Text(profile.spice.title)),
              ],
            ),
    );
  }
}
