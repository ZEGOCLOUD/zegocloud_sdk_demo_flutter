import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../internal/sdk/utils/login_notifier.dart';
import '../../../internal/sdk/utils/logout_notifier.dart';
import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_manager.dart';
import '../live_command.dart';
import '../live_page.dart';

import 'page_builder.dart';
import 'room_controller.dart';
import 'stream_controller.dart';

class ZegoSwipingLiveInfo {
  String roomID;
  String hostID;

  ZegoSwipingLiveInfo({required this.roomID, required this.hostID});
}

class ZegoSwipingLivePage extends StatefulWidget {
  const ZegoSwipingLivePage({
    super.key,
    required this.roomList,
  });

  final List<ZegoSwipingLiveInfo> roomList;

  @override
  State<ZegoSwipingLivePage> createState() => ZegoSwipingLivePageState();
}

class ZegoSwipingLivePageState extends State<ZegoSwipingLivePage> {
  final _roomController = ZegoSwipingRoomController();
  final _streamController = ZegoSwipingStreamController();

  var swipingRoomListNotifier = ValueNotifier<List<ZegoSwipingLiveInfo>>([]);
  var roomCommandsNotifier = ValueNotifier<Map<String, ZegoLivePageCommand>>({});
  ZegoRoomLogoutNotifier? singleLiveLogoutNotifier;
  ZegoRoomLoginNotifier? pageRoomLoginNotifier;
  int currentPageIndex = 0;

  List<StreamSubscription<dynamic>?> subscriptions = [];

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  int getRoomIDIndexOfPage(int pageIndex) {
    if (pageIndex > swipingRoomListNotifier.value.length - 1) {
      return pageIndex % swipingRoomListNotifier.value.length;
    }

    return pageIndex;
  }

  ZegoLivePageCommand getCommandOfPage(int pageIndex) {
    final targetRoom = swipingRoomListNotifier.value[getRoomIDIndexOfPage(pageIndex)];
    if (!roomCommandsNotifier.value.containsKey(targetRoom.roomID)) {
      roomCommandsNotifier.value[targetRoom.roomID] = ZegoLivePageCommand(roomID: targetRoom.roomID);
    }

    return roomCommandsNotifier.value[targetRoom.roomID]!;
  }

  @override
  void initState() {
    super.initState();

    swipingRoomListNotifier.value = List<ZegoSwipingLiveInfo>.from(widget.roomList);

    _roomController.init(roomCommandsNotifier: roomCommandsNotifier);
    if (widget.roomList.length > 1) {
      _roomController.joinRoom(widget.roomList.first.roomID);
    }
  }

  @override
  void dispose() {
    super.dispose();

    pageRoomLoginNotifier?.notifier.removeListener(onCurrentPageRoomLoginStateChanged);
    _roomController.uninit();

    for (final subscription in subscriptions) {
      subscription?.cancel();
    }

    ZegoLiveStreamingManager().leaveRoom();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ZegoSwipingLiveInfo>>(
      valueListenable: swipingRoomListNotifier,
      builder: (context, roomList, _) {
        if (roomList.isEmpty) {
          return emptyLivePage();
        }

        return roomList.length == 1 ? singleLivePage() : multiLivePage();
      },
    );
  }

  Widget emptyLivePage() {
    return const Center(
      child: Text(
        'Not Lives',
        style: TextStyle(
          decoration: TextDecoration.none,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget singleLivePage() {
    return Stack(
      children: [
        ZegoLivePage(
          roomID: swipingRoomListNotifier.value.first.roomID,
          role: ZegoLiveStreamingRole.audience,
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: ElevatedButton(
            onPressed: updateRoomLists,
            child: const Text('UpdateRoomLists'),
          ),
        )
      ],
    );
  }

  Widget multiLivePage() {
    singleLiveLogoutNotifier?.notifier.removeListener(onSingleLiveLogoutStateUpdated);

    singleLiveLogoutNotifier ??= ZegoRoomLogoutNotifier();
    if (!(singleLiveLogoutNotifier?.notifier.value ?? false)) {
      /// previous single live room still login, wait logout
      singleLiveLogoutNotifier?.notifier.addListener(onSingleLiveLogoutStateUpdated);

      return const Center(child: CircularProgressIndicator());
    }

    return ZegoSwipingPageBuilder(
      onPageChanged: onPageChanged,
      swipingRoomListNotifier: swipingRoomListNotifier,
      itemBuilder: (context, pageIndex) {
        final targetRoom = swipingRoomListNotifier.value[getRoomIDIndexOfPage(pageIndex)];

        return ZegoLivePage(
          roomID: targetRoom.roomID,
          previewHostID: targetRoom.hostID,
          role: ZegoLiveStreamingRole.audience,
          externalControlCommand: getCommandOfPage(pageIndex),
        );
      },
    );
  }

  void onSingleLiveLogoutStateUpdated() {
    if (singleLiveLogoutNotifier?.value ?? false) {
      singleLiveLogoutNotifier?.notifier.removeListener(onSingleLiveLogoutStateUpdated);

      /// previous single live logout, render multi live page
      swipingRoomListNotifier.value = List.from(swipingRoomListNotifier.value);
    }
  }

  void onCurrentPageRoomLoginStateChanged() {
    if (!(pageRoomLoginNotifier?.notifier.value ?? false)) {
      return;
    }

    if (currentPageIndex > 0) {
      final previousRoom = swipingRoomListNotifier.value[getRoomIDIndexOfPage(currentPageIndex - 1)];

      _streamController.playRemoteRoomStream(previousRoom.roomID, previousRoom.hostID);
    }

    final nextRoom = swipingRoomListNotifier.value[getRoomIDIndexOfPage(currentPageIndex + 1)];

    _streamController.playRemoteRoomStream(nextRoom.roomID, nextRoom.hostID);
  }

  void onPageChanged(int pageIndex) {
    debugPrint('swiping page, onPageChanged $pageIndex');

    currentPageIndex = pageIndex;

    /// current page, switch room(leave previous and login current room)
    final targetRoom = swipingRoomListNotifier.value[getRoomIDIndexOfPage(pageIndex)];

    pageRoomLoginNotifier?.notifier.removeListener(onCurrentPageRoomLoginStateChanged);
    pageRoomLoginNotifier = null;

    pageRoomLoginNotifier ??= ZegoRoomLoginNotifier(roomID: targetRoom.roomID);
    pageRoomLoginNotifier?.notifier.addListener(onCurrentPageRoomLoginStateChanged);

    _streamController.clear();
    _roomController.switchRoom(targetRoom.roomID);
  }

  void updateRoomLists() {
    const roomCount = 6;
    final roomIDEditors = List<TextEditingController>.generate(
        roomCount, (index) => TextEditingController(text: (200 + index).toString()));
    final hostIDEditors = List<TextEditingController>.generate(
        roomCount, (index) => TextEditingController(text: (200 + index).toString()));

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Input room id & host id'),
          content: Column(
            children: List.generate(roomCount, (index) {
              return [
                Row(
                  children: [
                    const SizedBox(width: 30, child: Text('room:', style: TextStyle(fontSize: 10))),
                    SizedBox(width: 80, child: CupertinoTextField(controller: roomIDEditors[index])),
                    const SizedBox(width: 2),
                    const SizedBox(width: 30, child: Text('host:', style: TextStyle(fontSize: 10))),
                    SizedBox(width: 80, child: CupertinoTextField(controller: hostIDEditors[index])),
                  ],
                ),
                const SizedBox(height: 5),
              ];
            }).expand((widgets) => widgets).toList(),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                var tempRoomList = <ZegoSwipingLiveInfo>[];
                void addRoomID(String roomID, String hostID) {
                  if (roomID.isNotEmpty && hostID.isNotEmpty) {
                    tempRoomList.add(ZegoSwipingLiveInfo(roomID: roomID, hostID: hostID));
                  }
                }

                for (var index = 0; index < roomCount; index++) {
                  addRoomID(roomIDEditors[index].text, hostIDEditors[index].text);
                }

                swipingRoomListNotifier.value = List<ZegoSwipingLiveInfo>.from(tempRoomList);

                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
