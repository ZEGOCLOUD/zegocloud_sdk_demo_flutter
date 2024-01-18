import 'package:flutter/cupertino.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoSwitchCameraButton extends StatelessWidget {
  const ZegoSwitchCameraButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ZEGOSDKManager().expressService.currentUser!.isUsingFrontCameraNotifier,
      builder: (BuildContext context, bool isUsingFacingCamera, Widget? child) {
        return GestureDetector(
          onTap: () => ZEGOSDKManager().expressService.useFrontCamera(!isUsingFacingCamera),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: const Color(0xff2C2F3E).withOpacity(0.6), shape: BoxShape.circle),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Image(image: AssetImage('assets/icons/toolbar_flip_camera.png')),
            ),
          ),
        );
      },
    );
  }
}
