import 'dart:async';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';

import '../../../zego_live_streaming_manager.dart';
import '../normal/live_command.dart';
import '../normal/live_page.dart';
import 'defines.dart';
import 'page_builder.dart';
import 'room_controller.dart';
import 'stream_controller.dart';

class ZegoSwipingLivePage extends StatefulWidget {
  const ZegoSwipingLivePage({
    super.key,
    required this.config,
    required this.liveStreamingManager,
  });
  final ZegoLiveSwipingConfig config;
  final ZegoLiveStreamingManager liveStreamingManager;

  @override
  State<ZegoSwipingLivePage> createState() => ZegoSwipingLivePageState();
}

class ZegoSwipingLivePageState extends State<ZegoSwipingLivePage> {
  final _roomController = ZegoSwipingRoomController();
  final _streamController = ZegoSwipingStreamController();

  var roomCommandsNotifier = ValueNotifier<Map<String, ZegoLivePageCommand>>({});
  ZegoRoomLoginNotifier? pageRoomLoginNotifier;
  ZegoSwipingPageChangedContext currentPageChangeContext = ZegoSwipingPageChangedContext(
    currentPageIndex: 0,
    currentRoomInfo: ZegoSwipingPageRoomInfo.empty(),
    previousRoomInfo: ZegoSwipingPageRoomInfo.empty(),
    nextRoomInfo: ZegoSwipingPageRoomInfo.empty(),
  );

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  ZegoLivePageCommand getCommandOfPage(ZegoSwipingPageRoomInfo pageRoomInfo) {
    if (!roomCommandsNotifier.value.containsKey(pageRoomInfo.roomID)) {
      roomCommandsNotifier.value[pageRoomInfo.roomID] = ZegoLivePageCommand(
        roomID: pageRoomInfo.roomID,
      );
    }

    return roomCommandsNotifier.value[pageRoomInfo.roomID]!;
  }

  @override
  void initState() {
    super.initState();

    _roomController.init(
      roomCommandsNotifier: roomCommandsNotifier,
      liveStreamingManager: widget.liveStreamingManager,
    );
  }

  @override
  void dispose() {
    super.dispose();

    pageRoomLoginNotifier?.notifier.removeListener(onCurrentPageRoomLoginStateChanged);
    _roomController.uninit();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ZegoSwipingPageRoomInfo>(
        future: widget.config.requiredCurrentLive(),
        builder: (
          BuildContext context,
          AsyncSnapshot<ZegoSwipingPageRoomInfo> snapshot,
        ) {
          if (ConnectionState.done != snapshot.connectionState) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return ZegoSwipingPageBuilder(
            defaultRoomInfo: snapshot.data!,
            onPageWillChanged: (int pageIndex) async {
              widget.config.onPageChanged.call(pageIndex);

              final currentLiveRoomInfo = await widget.config.requiredCurrentLive();
              final previousLiveRoomInfo = await widget.config.requiredPreviousLive();
              final nextLiveRoomInfo = await widget.config.requiredNextLive();
              return ZegoSwipingPageChangedContext(
                currentPageIndex: pageIndex,
                previousRoomInfo: previousLiveRoomInfo,
                currentRoomInfo: currentLiveRoomInfo,
                nextRoomInfo: nextLiveRoomInfo,
              );
            },
            onPageChanged: onPageChanged,
            itemBuilder: (
              context,
              int pageIndex,
              ZegoSwipingPageRoomInfo pageRoomInfo,
            ) {
              return ZegoNormalLivePage(
                liveStreamingManager: widget.liveStreamingManager,
                roomID: pageRoomInfo.roomID,
                role: ZegoLiveStreamingRole.audience,

                /// for swiping
                previewHostID: pageRoomInfo.hostID,
                externalControlCommand: getCommandOfPage(pageRoomInfo),
              );
            },
          );
        });
  }

  void onPageChanged(ZegoSwipingPageChangedContext pageChangeContext) {
    debugPrint('swiping page, onPageChanged $pageChangeContext');

    currentPageChangeContext = pageChangeContext;

    /// current page, switch room(leave previous and login current room)
    pageRoomLoginNotifier?.notifier.removeListener(
      onCurrentPageRoomLoginStateChanged,
    );
    pageRoomLoginNotifier = null;

    pageRoomLoginNotifier ??= ZegoRoomLoginNotifier(
      roomID: pageChangeContext.currentRoomInfo.roomID,
    );
    pageRoomLoginNotifier?.notifier.addListener(
      onCurrentPageRoomLoginStateChanged,
    );

    _roomController.switchRoom(
      pageChangeContext.currentRoomInfo.roomID,
    );
  }

  void onCurrentPageRoomLoginStateChanged() {
    if (!(pageRoomLoginNotifier?.notifier.value ?? false)) {
      return;
    }

    /// play previous live stream
    if (currentPageChangeContext.currentPageIndex > 0) {
      _streamController.playRemoteRoomStream(
        currentPageChangeContext.previousRoomInfo.roomID,
        currentPageChangeContext.previousRoomInfo.hostID,
      );
    }

    /// play next live stream
    _streamController.playRemoteRoomStream(
      currentPageChangeContext.nextRoomInfo.roomID,
      currentPageChangeContext.nextRoomInfo.hostID,
    );
  }
}
