// Flutter imports:
import 'package:flutter/material.dart';

import '../../../zego_sdk_manager.dart';

class ZegoLiveSwipingLoading extends StatefulWidget {
  const ZegoLiveSwipingLoading({
    Key? key,
    required this.loadingRoomID,
    required this.roomBuilder,
  }) : super(key: key);

  final String loadingRoomID;
  final Widget Function() roomBuilder;

  @override
  State<ZegoLiveSwipingLoading> createState() => _ZegoUIKitPrebuiltLiveStreamingScrollerElementState();
}

/// @nodoc
class _ZegoUIKitPrebuiltLiveStreamingScrollerElementState extends State<ZegoLiveSwipingLoading> {
  final roomBuildNotifier = ValueNotifier<bool>(false);
  final roomLogoutNotifier = ZegoRoomLogoutNotifier();

  @override
  void initState() {
    super.initState();

    ///wait express room and zim room logout
    if (roomLogoutNotifier.value) {
      debugPrint('swiping loading, room ${roomLogoutNotifier.checkingRoomID} is logout, can build');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        roomBuildNotifier.value = true;
      });
    } else {
      debugPrint('swiping loading, room ${roomLogoutNotifier.checkingRoomID} is not logout, wait room logout');

      roomLogoutNotifier.notifier.addListener(onRoomStateChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    roomLogoutNotifier.notifier.removeListener(onRoomStateChanged);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: roomBuildNotifier,
      builder: (context, canBuild, _) {
        return canBuild
            ? widget.roomBuilder()
            : Stack(
                children: [
                  Image.asset(
                    'assets/images/live_bg.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
      },
    );
  }

  void onRoomStateChanged() {
    debugPrint(
        'swiping loading, room ${roomLogoutNotifier.checkingRoomID} state changed, logout:${roomLogoutNotifier.value}');

    if (roomLogoutNotifier.value) {
      debugPrint('swiping loading, room ${roomLogoutNotifier.checkingRoomID} had logout, build..');

      roomBuildNotifier.value = true;
    }
  }
}
