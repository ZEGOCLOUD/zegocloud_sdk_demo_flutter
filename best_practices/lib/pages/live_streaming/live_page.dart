import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../zego_live_streaming_manager.dart';
import 'normal/live_page.dart';
import 'swiping/defines.dart';
import 'swiping/live_page.dart';

class ZegoLivePage extends StatefulWidget {
  const ZegoLivePage({
    super.key,
    this.roomID = '',
    this.role = ZegoLiveStreamingRole.audience,
    this.swipingConfig,
  });

  final String roomID;
  final ZegoLiveStreamingRole role;
  final ZegoLiveSwipingConfig? swipingConfig;

  @override
  State<ZegoLivePage> createState() => ZegoLivePageState();
}

class ZegoLivePageState extends State<ZegoLivePage> {
  final liveStreamingManager = ZegoLiveStreamingManager();

  @override
  void initState() {
    super.initState();

    liveStreamingManager.init();
  }

  @override
  void dispose() {
    super.dispose();

    liveStreamingManager.uninit();
  }

  @override
  Widget build(BuildContext context) {
    return null == widget.swipingConfig
        ? ZegoNormalLivePage(
            liveStreamingManager: liveStreamingManager,
            roomID: widget.roomID,
            role: widget.role,
          )
        : ZegoSwipingLivePage(
            liveStreamingManager: liveStreamingManager,
            config: widget.swipingConfig!,
          );
  }
}
