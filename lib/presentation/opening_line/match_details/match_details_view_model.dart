import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';

/// «Type it out»: что пользователь знает о мэтче.
class MatchDetailsViewModel extends ViewModel<Never> {
  var _name = '';

  var _age = '';

  var _message = '';

  var _interests = '';

  /// Есть от чего оттолкнуться: имя, сообщение или интересы. Одного возраста мало.
  bool get canContinue => [_name, _message, _interests].any((text) => text.trim().isNotEmpty);

  MatchDetails get match => MatchDetails(
    name: _trimmed(_name),
    age: int.tryParse(_age),
    message: _trimmed(_message),
    interests: _trimmed(_interests),
  );

  void changeName(String name) => _change(() => _name = name);

  void changeAge(String age) => _change(() => _age = age);

  void changeMessage(String message) => _change(() => _message = message);

  void changeInterests(String interests) => _change(() => _interests = interests);

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  static String? _trimmed(String text) => text.trim().isEmpty ? null : text.trim();
}
