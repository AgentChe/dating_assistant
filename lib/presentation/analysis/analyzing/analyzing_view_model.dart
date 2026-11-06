import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/foundation.dart';

sealed class AnalyzingAction {
  const AnalyzingAction();
}

final class AnalysisFinished extends AnalyzingAction {
  const AnalysisFinished(this.breakdown);

  final ChatBreakdown breakdown;
}

/// Бесплатные генерации на этой неделе кончились.
final class AnalysisLimitReached extends AnalyzingAction {
  const AnalysisLimitReached();
}

/// Ошибка, и пользователь не стал повторять.
final class AnalysisCancelled extends AnalyzingAction {
  const AnalysisCancelled();
}

/// Сканирование скриншота: отправляет его на разбор и ждёт ответа нейросети.
class AnalyzingViewModel extends ViewModel<AnalyzingAction> {
  AnalyzingViewModel({required this.screenshot, AnalysisManager? analysisManager})
    : _analysisManager = analysisManager ?? Injector.shared.analysisManager;

  final Uint8List screenshot;

  final AnalysisManager _analysisManager;

  var _isFinished = false;

  /// Разбор готов — прогресс добегает до 100%.
  bool get isFinished => _isFinished;

  /// При ошибке спрашивает [tryAgain] и повторяет; лимит генераций не повторяем.
  Future<void> analyze() async {
    while (true) {
      try {
        final breakdown = await _analysisManager.analyzeScreenshot(screenshot);
        _isFinished = true;
        notifyListeners();
        emit(AnalysisFinished(breakdown));
        return;
      } catch (error) {
        if (AnalysisManager.isGenerationLimit(error)) {
          emit(const AnalysisLimitReached());
          return;
        }
        debugPrint('AnalyzingViewModel: $error');
        if (!(await tryAgain?.call(error) ?? false)) {
          emit(const AnalysisCancelled());
          return;
        }
      }
    }
  }
}
