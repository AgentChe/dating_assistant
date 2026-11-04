import 'package:intl/intl.dart';

/// Общие для пейгейта и экрана «You’re in» тексты о пробном периоде.
abstract final class PaygateCopy {
  /// «3 days» / «1 day».
  static String trialLength(int days) => days == 1 ? '1 day' : '$days days';

  /// Последний бесплатный день — когда спишется первый платёж.
  static DateTime trialEnd(int days) => _today.add(Duration(days: days));

  /// Напоминание приходит за день до списания.
  static DateTime trialReminder(int days) => trialEnd(days).subtract(const Duration(days: 1));

  /// «Sep 30».
  static String day(DateTime date) => DateFormat('MMM d', 'en_US').format(date);

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
