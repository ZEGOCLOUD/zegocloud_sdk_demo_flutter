import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoToggleCameraButton extends StatefulWidget {
  const ZegoToggleCameraButton({
    Key? key,
  }) : super(key: key);

  @override
  State<ZegoToggleCameraButton> createState() => _ZegoToggleCameraButtonState();
}

class _ZegoToggleCameraButtonState extends State<ZegoToggleCameraButton> {
  ValueNotifier<bool> isCameraOnNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isCameraOnNotifier,
        builder: (context, isCameraOn, _) {
          return GestureDetector(
            onTap: () {
              ZEGOSDKManager.instance.expressService.turnCameraOn(!isCameraOn);
              isCameraOnNotifier.value = !isCameraOnNotifier.value;
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isCameraOn ? const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 56,
                height: 56,
                child: isCameraOn
                    ? const Image(image: AssetImage('assets/icons/toolbar_camera_normal.png'))
                    : const Image(image: AssetImage('assets/icons/toolbar_camera_off.png')),
              ),
            ),
          );
        });
  }
}
