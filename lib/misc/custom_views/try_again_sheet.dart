import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter/material.dart';

/// Ошибка с кнопкой «Повторить» (аналог TryAgainViewController).
abstract final class TryAgainSheet {
  /// Завершается `true`, если пользователь нажал «Повторить».
  static Future<bool> show(BuildContext context, Object error) async {
    if (!context.mounted) return false;

    final retry = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_message(error), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try again')),
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
    return retry ?? false;
  }

  static String _message(Object error) => switch (error) {
    NetworkError(code: NetworkErrorCode.serverNotAvailable) => 'Check your internet connection.',
    NetworkError(:final message?) => message,
    _ => 'Please try again.',
  };
}
