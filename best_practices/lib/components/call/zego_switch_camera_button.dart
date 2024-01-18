import 'package:flutter/cupertino.dart';

import 'zego_defines.dart';

/// switch cameras
class ZegoSwitchCameraButton extends StatefulWidget {
  const ZegoSwitchCameraButton({
    Key? key,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.buttonSize,
  }) : super(key: key);

  final ButtonIcon? icon;

  ///  You can do what you want after pressed.
  final void Function()? onPressed;

  /// the size of button's icon
  final Size? iconSize;

  /// the size of button
  final Size? buttonSize;

  @override
  State<ZegoSwitchCameraButton> createState() => _ZegoSwitchCameraButtonState();
}

class _ZegoSwitchCameraButtonState extends State<ZegoSwitchCameraButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.buttonSize ?? const Size(96, 96);
    final sizeBoxSize = widget.iconSize ?? const Size(56, 56);

    return GestureDetector(
      onTap: () {
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
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
                  image: AssetImage('assets/icons/toolbar_flip_camera.png')),
        ),
      ),
    );
  }
}
