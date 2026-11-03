import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
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
  void initState() {
    super.initState();
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Временная вёрстка: экран соберём по макету из Figma.
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final profile = _viewModel.profile;
          if (profile == null) {
            return Center(child: _viewModel.isLoading ? const CircularProgressIndicator() : null);
          }

          return ListView(
            children: [
              ListTile(title: const Text('Gender'), trailing: Text(profile.gender.title)),
              ListTile(title: const Text('Age'), trailing: Text('${profile.age}')),
              ListTile(title: const Text('Dating goal'), trailing: Text(profile.datingGoal.title)),
            ],
          );
        },
      ),
    );
  }
}
