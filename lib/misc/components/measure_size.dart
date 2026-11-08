import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Сообщает размер [child] после раскладки — когда от размера одного блока зависят отступы другого
/// (лента чата прокручивается под шапкой и полем ввода, а их высота меняется).
///
/// Колбэк приходит после кадра, поэтому в нём можно вызывать setState.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, RenderMeasureSize renderObject) => renderObject.onChange = onChange;
}

/// Раскладывает ребёнка как есть и, если размер изменился, сообщает его после кадра.
class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;

  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final size = this.size;
    if (size == _reported) return;
    _reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChange(size);
    });
  }
}
