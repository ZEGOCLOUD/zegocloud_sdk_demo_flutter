import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

/// switch cameras
class ZegoSpeakerButton extends StatelessWidget {
  const ZegoSpeakerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: ZEGOSDKManager().expressService.currentUser!.isUsingSpeaker,
        builder: (context, isUsingSpeaker, _) {
          return GestureDetector(
            onTap: () => ZEGOSDKManager().expressService.setAudioRouteToSpeaker(!isUsingSpeaker),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isUsingSpeaker ? const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6) : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: SizedBox.fromSize(
                size: const Size(56, 56),
                child: isUsingSpeaker
                    ? const Image(image: AssetImage('assets/icons/icon_speaker_normal.png'))
                    : const Image(image: AssetImage('assets/icons/icon_speaker_off.png')),
              ),
            ),
          );
        });
  }
}
