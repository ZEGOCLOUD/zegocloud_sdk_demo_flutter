import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  List<StreamSubscription<dynamic>?> subscriptions = [];

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

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

    _roomController.uninit();

    for (final subscription in subscriptions) {
      subscription?.cancel();
    }

    ZegoLiveStreamingManager()
      ..leaveRoom()
      ..uninit();
  }

  int roomIDIndexOfPage(int pageIndex) {
    if (pageIndex > swipingRoomListNotifier.value.length - 1) {
      return pageIndex % swipingRoomListNotifier.value.length;
    }

    return pageIndex;
  }

  ZegoLivePageCommand commandOfPage(int pageIndex) {
    final targetRoom = swipingRoomListNotifier.value[roomIDIndexOfPage(pageIndex)];
    if (!roomCommandsNotifier.value.containsKey(targetRoom.roomID)) {
      roomCommandsNotifier.value[targetRoom.roomID] = ZegoLivePageCommand(roomID: targetRoom.roomID);
    }

    return roomCommandsNotifier.value[targetRoom.roomID]!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ZegoSwipingLiveInfo>>(
      valueListenable: swipingRoomListNotifier,
      builder: (context, roomList, _) {
        if (roomList.isEmpty) {
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

        return roomList.length == 1
            ? Stack(
                children: [
                  ZegoLivePage(
                    roomID: roomList.first.roomID,
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
              )
            : livePages();
      },
    );
  }

  void _onSingleLiveLogoutChanged() {
    debugPrint(
        'swiping page, room ${singleLiveLogoutNotifier?.checkingRoomID} state changed, logout:${singleLiveLogoutNotifier?.value}');

    if (singleLiveLogoutNotifier?.value ?? false) {
      debugPrint('swiping page, room ${singleLiveLogoutNotifier?.checkingRoomID} had logout..');

      singleLiveLogoutNotifier?.notifier.removeListener(_onSingleLiveLogoutChanged);

      /// previous single live logout, render PageView
      swipingRoomListNotifier.value = List.from(swipingRoomListNotifier.value);
    }
  }

  Widget livePages() {
    singleLiveLogoutNotifier?.notifier.removeListener(_onSingleLiveLogoutChanged);

    singleLiveLogoutNotifier ??= ZegoRoomLogoutNotifier();
    if (!(singleLiveLogoutNotifier?.notifier.value ?? false)) {
      /// previous single live room still login, wait logout
      singleLiveLogoutNotifier?.notifier.addListener(_onSingleLiveLogoutChanged);

      return const Center(child: CircularProgressIndicator());
    }

    return ZegoSwipingPageBuilder(
      onPageChanged: onPageChanged,
      itemBuilder: (context, pageIndex) {
        /// todo: 跨房间拉流，绑定跨房间用户
        /// 展示所属房间的流（controller去拉流，view负责展示，有什么展示什么）
        final targetRoom = swipingRoomListNotifier.value[roomIDIndexOfPage(pageIndex)];
        debugPrint('swiping page, PageView.itemBuilder $pageIndex, room:$targetRoom');

        final streamID = ZegoLiveStreamingManager().hostStreamIDFormat(targetRoom.roomID, targetRoom.hostID);
        _streamController.playRoomStream(targetRoom.roomID, streamID);

        return ZegoLivePage(
          roomID: targetRoom.roomID,
          previewHostID: targetRoom.hostID,
          role: ZegoLiveStreamingRole.audience,
          externalControlCommand: commandOfPage(pageIndex),
        );
      },
    );
  }

  Future<void> onPageChanged(int pageIndex) async {
    debugPrint('swiping page, PageView.onPageChanged $pageIndex');

    /// current page, switch room(leave previous and login current room)
    final targetRoom = swipingRoomListNotifier.value[roomIDIndexOfPage(pageIndex)];
    await _roomController.switchRoom(targetRoom.roomID);
  }

  void updateRoomLists() {
    const roomCount = 6;
    final roomIDEditors =
        List<TextEditingController>.generate(roomCount, (index) => TextEditingController(text: index.toString()));
    final hostIDEditors =
        List<TextEditingController>.generate(roomCount, (index) => TextEditingController(text: index.toString()));

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

                debugPrint('swiping page, update room list:$tempRoomList');
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
