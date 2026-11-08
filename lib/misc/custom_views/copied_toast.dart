import 'package:dating_assistant/misc/custom_views/glass_toast.dart';
import 'package:flutter/widgets.dart';

/// Плашка «Copied — paste it into your chat» с оранжевой галочкой: у первой фразы и у сообщений коуча.
class CopiedToast extends StatelessWidget {
  const CopiedToast({super.key});

  @override
  Widget build(BuildContext context) => const GlassToast.success(message: 'Copied — paste it into your chat');
}
