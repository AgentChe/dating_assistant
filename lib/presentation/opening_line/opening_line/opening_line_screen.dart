import 'dart:async';

import 'package:dating_assistant/misc/components/instant_page_route.dart';
import 'package:dating_assistant/misc/custom_views/phrase_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/spice_card.dart';
import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_view_model.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/views/copied_toast.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// «Opening line» (аналог OpeningLineViewController): готовая фраза, острота и «Another one».
/// Открывается во вкладке Main, таб-бар остаётся.
class OpeningLineScreen extends StatefulWidget {
  const OpeningLineScreen({super.key, this.match, this.firstLine, this.viewModel});

  /// [firstLine] — фраза, которую уже написало сканирование анкеты; без неё экран пишет первую сам.
  /// [isAnimated] false — экран появляется под сканированием или формой, которые потом закрываются над ним.
  static Route<void> route({MatchDetails? match, OpeningLine? firstLine, bool isAnimated = true}) {
    Widget builder(BuildContext context) => OpeningLineScreen(match: match, firstLine: firstLine);
    return isAnimated ? MaterialPageRoute(builder: builder) : InstantPageRoute(builder: builder);
  }

  /// Что известно о мэтче; null — «Just give me one».
  final MatchDetails? match;

  final OpeningLine? firstLine;

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final OpeningLineViewModel? viewModel;

  @override
  State<OpeningLineScreen> createState() => _OpeningLineScreenState();
}

class _OpeningLineScreenState extends State<OpeningLineScreen> {
  late final _viewModel = widget.viewModel ?? OpeningLineViewModel(match: widget.match, firstLine: widget.firstLine);

  late final StreamSubscription<OpeningLineAction> _actions;

  /// Только что скопированная фраза — для галочки и плашки.
  String? _copiedText;

  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _viewModel.start();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final line = _viewModel.line;
          final isCopied = line != null && line.text == _copiedText;
          return Stack(
            children: [
              // Фраза по центру между шапкой и ползунком; на маленьком экране всё прокручивается.
              LayoutBuilder(
                builder: (context, constraints) {
                  // Снизу в padding уже входит таб-бар: кнопка в 32 над ним.
                  final insets = EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 32);
                  return SingleChildScrollView(
                    padding: insets,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - insets.vertical),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(title: 'Opening line', onBack: () => Navigator.of(context).maybePop()),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: PhraseCard(
                              text: line?.text ?? (_viewModel.isGenerating ? null : 'No line yet. Tap Another one.'),
                              caption: _viewModel.caption,
                              isCopied: isCopied,
                              isLoading: _viewModel.isGenerating,
                              onCopy: line == null ? null : () => _copy(line.text),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SpiceCard(spice: _viewModel.spice, onChanged: _viewModel.selectSpice),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                title: 'Another one',
                                isLoading: _viewModel.isGenerating,
                                onPressed: _viewModel.generate,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: padding.top + 75,
                left: 16,
                right: 16,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isCopied ? const CopiedToast() : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    setState(() => _copiedText = text);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedText = null);
    });
  }

  Future<void> _handle(OpeningLineAction action) async {
    switch (action) {
      case OpeningLineAction.openPlus:
        if (await PlusSheet.present(context)) _viewModel.didSubscribe();
    }
  }
}
