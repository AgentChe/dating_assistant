import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';

/// «You’re in»: экран после покупки Cue Plus.
class WelcomePlusViewModel extends ViewModel<Never> {
  WelcomePlusViewModel({ProfileManager? profileManager})
    : _profileManager = profileManager ?? Injector.shared.profileManager;

  final ProfileManager _profileManager;

  String? get name => _profileManager.profile?.name;
}
