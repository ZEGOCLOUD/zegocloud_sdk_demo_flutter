import 'package:flutter/cupertino.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoSwitchCameraButton extends StatefulWidget {
  const ZegoSwitchCameraButton({
    Key? key,
    this.onPressed,
    this.iconSize,
    this.buttonSize,
  }) : super(key: key);

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
  bool usingFacingCamera = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ZEGOSDKManager.instance.expressService.useFrontCamera(!usingFacingCamera);
        usingFacingCamera = !usingFacingCamera;
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xff2C2F3E).withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Image(image: AssetImage('assets/icons/toolbar_flip_camera.png')),
        ),
      ),
    );
  }
}
