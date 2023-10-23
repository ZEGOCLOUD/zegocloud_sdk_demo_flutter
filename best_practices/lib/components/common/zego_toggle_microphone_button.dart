import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoToggleMicrophoneButton extends StatefulWidget {
  const ZegoToggleMicrophoneButton({
    Key? key,
  }) : super(key: key);

  @override
  State<ZegoToggleMicrophoneButton> createState() => _ZegoToggleMicrophoneButtonState();
}

class _ZegoToggleMicrophoneButtonState extends State<ZegoToggleMicrophoneButton> {
  ValueNotifier<bool> isMicOnNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isMicOnNotifier,
        builder: (context, isMicOn, _) {
          return GestureDetector(
            onTap: () {
              ZEGOSDKManager.instance.expressService.turnMicrophoneOn(!isMicOn);
              isMicOnNotifier.value = !isMicOn;
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isMicOn ? const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6) : Colors.white,
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
