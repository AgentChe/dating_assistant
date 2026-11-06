import 'package:dating_assistant/misc/custom_views/bottom_buttons.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/labeled_text_field.dart';
import 'package:dating_assistant/presentation/opening_line/match_details/match_details_view_model.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// «Type it out» (аналог MatchDetailsViewController): имя, возраст, что мэтч написал и его интересы.
/// Открывается поверх таб-бара, внизу — «Continue».
class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key, required this.onSubmit});

  static Route<void> route({required void Function(MatchDetails match) onSubmit}) =>
      MaterialPageRoute(builder: (_) => MatchDetailsScreen(onSubmit: onSubmit));

  /// Подробности введены. Вызывается до того, как форма закроется, — чтобы под ней уже была фраза.
  final void Function(MatchDetails match) onSubmit;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final _viewModel = MatchDetailsViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 11, 16, 0),
              child: ScreenHeader(title: 'Type it out', onBack: () => Navigator.of(context).maybePop()),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 47, 16, 16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Пропорции из Figma (271 и 113) чуть сдвинуты: иначе «Enter age» обрезается.
                      Expanded(
                        flex: 262,
                        child: LabeledTextField(
                          label: 'Name',
                          hint: 'Enter name',
                          textCapitalization: TextCapitalization.words,
                          onChanged: _viewModel.changeName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 122,
                        child: LabeledTextField(
                          label: 'Age',
                          hint: 'Enter age',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: _viewModel.changeAge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'What they wrote',
                    hint: 'Enter message',
                    onChanged: _viewModel.changeMessage,
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'Interests or bio',
                    hint: 'Hiking, bad puns, dogs...',
                    minLines: 5,
                    onChanged: _viewModel.changeInterests,
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => BottomButtons(
                buttons: [PrimaryButton(title: 'Continue', onPressed: _viewModel.canContinue ? _submit : null)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    widget.onSubmit(_viewModel.match);
    Navigator.of(context).pop();
  }
}
