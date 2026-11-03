import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';

/// Профиль: показывает ответы с онбординга.
class ProfileViewModel extends ViewModel<Never> {
  ProfileViewModel({ProfileManager? profileManager})
    : _profileManager = profileManager ?? Injector.shared.profileManager;

  final ProfileManager _profileManager;

  Profile? _profile;

  Profile? get profile => _profile;

  Future<void> load() async {
    final profile = await perform(_profileManager.obtain);
    if (profile == null) return;

    _profile = profile;
    notifyListeners();
  }
}
