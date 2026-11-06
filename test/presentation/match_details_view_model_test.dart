import 'package:dating_assistant/presentation/opening_line/match_details/match_details_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Continue needs something to work with besides the age', () {
    final viewModel = MatchDetailsViewModel();
    expect(viewModel.canContinue, isFalse);

    viewModel.changeAge('28');
    expect(viewModel.canContinue, isFalse);

    viewModel.changeName('   ');
    expect(viewModel.canContinue, isFalse);

    viewModel.changeInterests('hiking');
    expect(viewModel.canContinue, isTrue);
  });

  test('the details are trimmed and empty fields are left out', () {
    final viewModel = MatchDetailsViewModel()
      ..changeName('  Nika ')
      ..changeAge('28')
      ..changeMessage('')
      ..changeInterests(' mountains, tents ');

    final match = viewModel.match;

    expect(match.name, 'Nika');
    expect(match.age, 28);
    expect(match.message, isNull);
    expect(match.interests, 'mountains, tents');
    expect(match.toJson(), {'name': 'Nika', 'age': 28, 'interests': 'mountains, tents'});
  });
}
