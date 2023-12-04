import 'package:flutter/material.dart';

import '../../internal/business/pk/pk_user.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';

class PKMuteButton extends StatefulWidget {
  final PKUser pkUser;
  const PKMuteButton({super.key, required this.pkUser});

  @override
  State<PKMuteButton> createState() => _PKMuteButtonState();
}

class _PKMuteButtonState extends State<PKMuteButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          ZEGOSDKManager().expressService.mutePlayStreamAudio(widget.pkUser.pkUserStream, !widget.pkUser.isMute);
          ZegoLiveStreamingManager().mutePKUser([widget.pkUser.userID], !widget.pkUser.isMute);
        },
        icon: widget.pkUser.isMute
            ? const Image(image: AssetImage('assets/icons/icon_speaker_off.png'))
            : const Image(image: AssetImage('assets/icons/icon_speaker_normal.png')));
  }
}
