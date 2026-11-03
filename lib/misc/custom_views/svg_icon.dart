import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG-иконка из assets/icons; [color] перекрашивает её целиком.
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.asset, {super.key, this.size = 24, this.color});

  final String asset;

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
