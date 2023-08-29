import 'package:flutter/material.dart';

import 'zego_defines.dart';

/// switch cameras
class ZegoToggleCameraButton extends StatefulWidget {
  const ZegoToggleCameraButton({
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
  State<ZegoToggleCameraButton> createState() => _ZegoToggleCameraButtonState();
}

class _ZegoToggleCameraButtonState extends State<ZegoToggleCameraButton> {
  ValueNotifier<bool> cameraStateNoti = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.buttonSize ?? const Size(96, 96);
    final sizeBoxSize = widget.iconSize ?? const Size(56, 56);

    return ValueListenableBuilder<bool>(
        valueListenable: cameraStateNoti,
        builder: ((context, cameraState, _) {
          return GestureDetector(
            onTap: () {
              if (widget.onPressed != null) {
                cameraStateNoti.value = !cameraStateNoti.value;
                widget.onPressed!();
              }
            },
            child: Container(
              width: containerSize.width,
              height: containerSize.height,
              decoration: BoxDecoration(
                color: cameraState
                    ? Colors.white
                    : const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: SizedBox.fromSize(
                size: sizeBoxSize,
                child: cameraState
                    ? const Image(
                        image:
                            AssetImage('assets/icons/toolbar_camera_off.png'))
                    : const Image(
                        image: AssetImage(
                            'assets/icons/toolbar_camera_normal.png')),
              ),
            ),
          );
        }));
  }
}
