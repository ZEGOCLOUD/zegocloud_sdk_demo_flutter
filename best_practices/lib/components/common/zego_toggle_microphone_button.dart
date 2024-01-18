import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoToggleMicrophoneButton extends StatelessWidget {
  const ZegoToggleMicrophoneButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: ZEGOSDKManager().expressService.currentUser!.isMicOnNotifier,
        builder: (context, isMicOn, _) {
          return GestureDetector(
            onTap: () => ZEGOSDKManager().expressService.turnMicrophoneOn(!isMicOn),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isMicOn ? const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6) : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 56,
                height: 56,
                child: isMicOn
                    ? const Image(image: AssetImage('assets/icons/toolbar_mic_normal.png'))
                    : const Image(image: AssetImage('assets/icons/toolbar_mic_off.png')),
              ),
            ),
          );
        });
  }
}
