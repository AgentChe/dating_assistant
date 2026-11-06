import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter/foundation.dart';

sealed class AnalyzingAction<T> {
  const AnalyzingAction();
}

final class AnalysisFinished<T> extends AnalyzingAction<T> {
  const AnalysisFinished(this.result);

  final T result;
}

/// Бесплатные генерации на этой неделе кончились.
final class AnalysisLimitReached<T> extends AnalyzingAction<T> {
  const AnalysisLimitReached();
}

/// Ошибка, и пользователь не стал повторять.
final class AnalysisCancelled<T> extends AnalyzingAction<T> {
  const AnalysisCancelled();
}

/// Сканирование скриншота: ждёт, пока нейросеть разберёт переписку или прочитает анкету.
class AnalyzingViewModel<T> extends ViewModel<AnalyzingAction<T>> {
  AnalyzingViewModel({required this.task});

  /// Запрос к нейросети по скриншоту.
  final Future<T> Function() task;

  var _isFinished = false;

  /// Ответ готов — прогресс добегает до 100%.
  bool get isFinished => _isFinished;

  /// При ошибке спрашивает [tryAgain] и повторяет; лимит генераций не повторяем.
  Future<void> analyze() async {
    while (true) {
      try {
        final result = await task();
        _isFinished = true;
        notifyListeners();
        emit(AnalysisFinished(result));
        return;
      } catch (error) {
        if (UsageManager.isGenerationLimit(error)) {
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
