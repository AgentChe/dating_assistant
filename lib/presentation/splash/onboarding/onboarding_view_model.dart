import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';

/// Шаги онбординга в порядке показа.
enum OnboardingStep {
  welcome,
  name,
  goal,
  aboutYou,
  hardestPart,
  insight,
  voice,
  yourVoice,
  tryIt,
  reveal,
  building,
  plan
  ;

  /// Шапка с кнопкой «назад» и прогрессом по главам.
  bool get hasHeader => switch (this) {
    OnboardingStep.welcome || OnboardingStep.building || OnboardingStep.plan => false,
    _ => true,
  };
}

/// Куда вести после онбординга: с подпиской — на главный, без неё — на пейгейт.
enum OnboardingAction { openMain, openPaygate }

/// Онбординг: знакомство, калибровка голоса и пример — в конце сохраняет профиль.
class OnboardingViewModel extends ViewModel<OnboardingAction> {
  OnboardingViewModel({ProfileManager? profileManager, SessionManager? sessionManager})
    : _profileManager = profileManager ?? Injector.shared.profileManager,
      _sessionManager = sessionManager ?? Injector.shared.sessionManager;

  final ProfileManager _profileManager;

  final SessionManager _sessionManager;

  var _step = OnboardingStep.welcome;

  var _isMovingBack = false;

  var _name = '';

  DatingGoal? _goal;

  Gender? _gender;

  AgeRange? _ageRange;

  final _hardestParts = <HardestPart>{};

  /// Ответы на карточки голоса по порядку: true — «That’s me».
  final _voiceAnswers = <bool>[];

  TryItAnswer? _tryItAnswer;

  OnboardingStep get step => _step;

  /// Последний переход был назад — для направления анимации.
  bool get isMovingBack => _isMovingBack;

  /// null — имя не ввели или шаг пропустили.
  String? get name {
    final name = _name.trim();
    return name.isEmpty ? null : name;
  }

  DatingGoal? get goal => _goal;

  Gender? get gender => _gender;

  AgeRange? get ageRange => _ageRange;

  /// Выбранные трудности в порядке вариантов на экране.
  List<HardestPart> get hardestParts => [
    for (final part in HardestPart.values)
      if (_hardestParts.contains(part)) part,
  ];

  /// Номер текущей карточки голоса.
  int get voiceSampleIndex => _voiceAnswers.length;

  TryItAnswer? get tryItAnswer => _tryItAnswer;

  /// Заполненность трёх глав — About you, Your voice, Try it: от 0 до 3.
  double get progress => switch (_step) {
    OnboardingStep.welcome => 0,
    OnboardingStep.name => 1 / 6,
    OnboardingStep.goal => 2 / 6,
    OnboardingStep.aboutYou => 3 / 6,
    OnboardingStep.hardestPart => 5 / 6,
    OnboardingStep.insight => 1,
    OnboardingStep.voice => 1 + (voiceSampleIndex + 1) / (OnboardingContent.voiceSamples.length + 1),
    OnboardingStep.yourVoice => 2,
    OnboardingStep.tryIt => 2.5,
    OnboardingStep.reveal || OnboardingStep.building || OnboardingStep.plan => 3,
  };

  bool get canContinue => switch (_step) {
    OnboardingStep.name => name != null,
    OnboardingStep.goal => _goal != null,
    OnboardingStep.aboutYou => _gender != null && _ageRange != null,
    OnboardingStep.hardestPart => _hardestParts.isNotEmpty,
    OnboardingStep.tryIt => _tryItAnswer != null,
    _ => true,
  };

  Voice get voice => Voice({
    for (final (index, isMe) in _voiceAnswers.indexed)
      if (isMe) OnboardingContent.voiceSamples[index].trait,
  });

  SpiceLevel get spice => SpiceLevel.defaultFor(_goal ?? DatingGoal.unsure);

  /// Самая важная из выбранных трудностей — по ней предлагаем, с чего начать.
  HardestPart get mainHardestPart => OnboardingContent.hardestPartPriority.firstWhere(
    _hardestParts.contains,
    orElse: () => HardestPart.keepingItGoing,
  );

  StartingPoint get startingPoint => OnboardingContent.startingPoint(mainHardestPart);

  void next() {
    if (!canContinue) return;

    switch (_step) {
      case OnboardingStep.voice:
        return;
      case OnboardingStep.plan:
        _finish();
      default:
        _go(OnboardingStep.values[_step.index + 1]);
    }
  }

  void back() {
    switch (_step) {
      case OnboardingStep.welcome || OnboardingStep.building || OnboardingStep.plan:
        return;
      case OnboardingStep.voice when _voiceAnswers.isNotEmpty:
        _voiceAnswers.removeLast();
        notifyListeners();
      case OnboardingStep.yourVoice:
        _voiceAnswers.removeLast();
        _go(OnboardingStep.voice, isBack: true);
      default:
        _go(OnboardingStep.values[_step.index - 1], isBack: true);
    }
  }

  void changeName(String name) {
    _name = name;
    notifyListeners();
  }

  void skipName() {
    _name = '';
    _go(OnboardingStep.goal);
  }

  void selectGoal(DatingGoal goal) {
    _goal = goal;
    notifyListeners();
  }

  void selectGender(Gender gender) {
    _gender = gender;
    notifyListeners();
  }

  void selectAgeRange(AgeRange ageRange) {
    _ageRange = ageRange;
    notifyListeners();
  }

  void toggleHardestPart(HardestPart part) {
    if (!_hardestParts.remove(part)) _hardestParts.add(part);
    notifyListeners();
  }

  /// Ответ на текущую карточку голоса; после последней — экран с результатом.
  void answerVoice({required bool isMe}) {
    if (_step != OnboardingStep.voice) return;

    _voiceAnswers.add(isMe);
    if (_voiceAnswers.length == OnboardingContent.voiceSamples.length) {
      _go(OnboardingStep.yourVoice);
    } else {
      notifyListeners();
    }
  }

  void selectTryItAnswer(TryItAnswer answer) {
    _tryItAnswer = answer;
    notifyListeners();
  }

  /// Сохраняет профиль, когда экран «Tuning Cue to you» доиграл анимацию.
  Future<void> completeBuilding() async {
    if (_step != OnboardingStep.building) return;

    await _profileManager.save(
      Profile(
        name: name,
        goal: _goal!,
        gender: _gender!,
        ageRange: _ageRange!,
        hardestParts: hardestParts,
        voice: voice,
        spice: spice,
      ),
    );
    _go(OnboardingStep.plan);
  }

  /// Как в Swift-проектах: без подписки после онбординга показываем пейгейт.
  Future<void> _finish() async {
    final hasSubscription = await _sessionManager.hasActiveSubscriptions();
    emit(hasSubscription ? OnboardingAction.openMain : OnboardingAction.openPaygate);
  }

  void _go(OnboardingStep step, {bool isBack = false}) {
    _isMovingBack = isBack;
    _step = step;
    notifyListeners();
  }
}
