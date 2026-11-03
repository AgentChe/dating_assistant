import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';

enum OnboardingAction { finished }

/// Онбординг: собирает пол, возраст и цель знакомств и создаёт профиль.
class OnboardingViewModel extends ViewModel<OnboardingAction> {
  OnboardingViewModel({ProfileManager? profileManager})
    : _profileManager = profileManager ?? Injector.shared.profileManager;

  static const minAge = 18;

  static const maxAge = 80;

  final ProfileManager _profileManager;

  Gender? _gender;

  var _age = 25;

  DatingGoal? _datingGoal;

  Gender? get gender => _gender;

  int get age => _age;

  DatingGoal? get datingGoal => _datingGoal;

  bool get canFinish => _gender != null && _datingGoal != null && !isLoading;

  void selectGender(Gender gender) {
    _gender = gender;
    notifyListeners();
  }

  void selectAge(int age) {
    _age = age;
    notifyListeners();
  }

  void selectDatingGoal(DatingGoal datingGoal) {
    _datingGoal = datingGoal;
    notifyListeners();
  }

  Future<void> finish() async {
    final gender = _gender;
    final datingGoal = _datingGoal;
    if (gender == null || datingGoal == null) return;

    final profile = await perform(() => _profileManager.create(gender: gender, age: _age, datingGoal: datingGoal));
    if (profile != null) emit(OnboardingAction.finished);
  }
}
