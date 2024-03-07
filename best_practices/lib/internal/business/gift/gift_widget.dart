import 'dart:async';

import 'package:flutter/material.dart';

import '../../../zego_sdk_manager.dart';
import 'gift_controller.dart';

class ZegoGiftWidget extends StatefulWidget {
  const ZegoGiftWidget({Key? key, required this.giftData}) : super(key: key);

  final ZegoGiftData giftData;

  @override
  State<ZegoGiftWidget> createState() => ZegoGiftWidgetState();
}

class ZegoGiftWidgetState extends State<ZegoGiftWidget> with SingleTickerProviderStateMixin {
  Widget? _mediaPlayerView;

  List<StreamSubscription> subscriptions = [];

  ValueNotifier<bool> show = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
    for (final element in subscriptions) {
      element.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('load ${widget.giftData} begin:${DateTime.now()}');

    subscriptions.add(ZEGOSDKManager().expressService.onMediaPlayerStateUpdateCtrl.stream.listen((event) {
      onMediaPlayerStateUpdate(event);
    }));

    ZegoGiftController().createMediaPlayer().then((view) async {
      _mediaPlayerView = view;
      await ZegoGiftController().loadResource(widget.giftData.giftPath!);
      ZegoGiftController().startMediaPlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: show,
      builder: (BuildContext context, bool show, Widget? child) {
        return show ? IgnorePointer(ignoring: true, child: _mediaPlayerView) : const SizedBox.shrink();
      },
    );
  }

  void onMediaPlayerStateUpdate(ZegoPlayerStateChangeEvent event) {
    if (!context.mounted) {
      return;
    }
    final playerState = event.state;
    debugPrint('Media Player State: $playerState');
    switch (playerState) {
      case ZegoMediaPlayerState.NoPlay:
        break;
      case ZegoMediaPlayerState.Playing:
        Future.delayed(const Duration(milliseconds: 200), () {
          show.value = true;
        });
        break;
      case ZegoMediaPlayerState.Pausing:
        break;
      case ZegoMediaPlayerState.PlayEnded:
        show.value = false;
        ZegoGiftController().clearView();
        ZegoGiftController().next();
        break;
    }
  }
}
