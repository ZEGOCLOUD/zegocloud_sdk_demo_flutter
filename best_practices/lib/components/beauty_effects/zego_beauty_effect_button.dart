// Flutter imports:
import 'package:flutter/material.dart';

import '../../internal/internal_defines.dart';


class ZegoBeautyEffectButton extends StatefulWidget {
  const ZegoBeautyEffectButton({
    Key? key,
    this.iconSize,
    this.buttonSize,
    this.icon,
    this.onPressed,
  }) : super(key: key);

  final Size? iconSize;
  final Size? buttonSize;
  final ButtonIcon? icon;

  ///  You can do what you want after pressed.
  final void Function()? onPressed;

  @override
  State<StatefulWidget> createState() => _ZegoBeautyEffectButtonState();
}

class _ZegoBeautyEffectButtonState extends State<ZegoBeautyEffectButton> {
  @override
  Widget build(BuildContext context) {
    final containerSize = widget.buttonSize ?? const Size(96, 96);
    final sizeBoxSize = widget.iconSize ?? const Size(56, 56);
    return GestureDetector(
      onTap: () {
        widget.onPressed?.call();
      },
      child: Container(
        width: containerSize.width,
        height: containerSize.height,
        decoration: BoxDecoration(
          color: widget.icon?.backgroundColor ??
              const Color(0xff2C2F3E).withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: SizedBox.fromSize(
          size: sizeBoxSize,
          child: widget.icon?.icon ??
              const Image(
                image: AssetImage('assets/icons/toolbar_beauty.png'),
              ),
        ),
      ),
    );
  }
}
