import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';

/// Профиль: показывает ответы с онбординга.
class ProfileViewModel extends ViewModel<Never> {
  ProfileViewModel({ProfileManager? profileManager})
    : _profileManager = profileManager ?? Injector.shared.profileManager;

  final ProfileManager _profileManager;

  Profile? get profile => _profileManager.profile;
}
