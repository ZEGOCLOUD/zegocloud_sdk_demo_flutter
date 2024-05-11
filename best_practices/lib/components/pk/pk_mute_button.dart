import 'package:flutter/material.dart';

import '../../zego_live_streaming_manager.dart';

class PKMuteButton extends StatefulWidget {
  const PKMuteButton({
    super.key,
    required this.pkUser,
    required this.liveStreamingManager,
  });

  final PKUser pkUser;

  final ZegoLiveStreamingManager liveStreamingManager;

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
          widget.liveStreamingManager.mutePKUser([widget.pkUser.userID], !widget.pkUser.isMute);
        },
        icon: widget.pkUser.isMute
            ? const Image(image: AssetImage('assets/icons/icon_speaker_off.png'))
            : const Image(image: AssetImage('assets/icons/icon_speaker_normal.png')));
  }
}
