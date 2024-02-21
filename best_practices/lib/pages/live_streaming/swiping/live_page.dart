import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../live_page.dart';
import 'loading.dart';
import '../../../zego_sdk_manager.dart';
import 'login_notifier.dart';

class ZegoSwipingLivePage extends StatefulWidget {
  const ZegoSwipingLivePage({
    super.key,
    required this.initialRoomID,
    required this.roomIDList,
  });

  final String initialRoomID;
  final List<String> roomIDList;

  @override
  State<ZegoSwipingLivePage> createState() => ZegoSwipingLivePageState();
}

class ZegoSwipingLivePageState extends State<ZegoSwipingLivePage> {
  ZegoLiveSwipingRoomLoginNotifier? roomLoginNotifier;

  int roomIDIndex = -1;
  List<String> roomIDList = [];

  String _targetRoomID = '';
  bool _targetRoomDone = false;

  List<StreamSubscription<dynamic>?> subscriptions = [];

  late final PageController _pageController;

  int get currentPageIndex => _pageController.page?.round() ?? 0;

  int get pageCount => 2;

  Duration get pageDuration => const Duration(milliseconds: 500);

  Curve get pageCurve => Curves.easeInOut;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  @override
  void initState() {
    super.initState();

    roomIDList = List<String>.from(widget.roomIDList);

    roomLoginNotifier = ZegoLiveSwipingRoomLoginNotifier();
    roomLoginNotifier?.notifier.addListener(onRoomStateChanged);

    _pageController = PageController(initialPage: 0);

    _targetRoomID = widget.initialRoomID;
    _targetRoomDone = false;
    roomLoginNotifier?.resetCheckingData(_targetRoomID);
  }

  @override
  void dispose() {
    super.dispose();

    for (final subscription in subscriptions) {
      subscription?.cancel();
    }

    _pageController.dispose();
    roomLoginNotifier?.notifier.removeListener(onRoomStateChanged);
  }

  String previousRoomID() {
    if (roomIDList.isEmpty) {
      return '';
    }

    roomIDIndex--;
    if (roomIDIndex < 0) {
      /// back to the last live
      roomIDIndex = roomIDList.length - 1;
    }
    return roomIDList[roomIDIndex];
  }

  String nextRoomID() {
    if (roomIDList.isEmpty) {
      return '';
    }

    roomIDIndex++;
    if (roomIDIndex > (roomIDList.length - 1)) {
      /// back to the first live
      roomIDIndex = 0;
    }
    return roomIDList[roomIDIndex];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (!_targetRoomDone) {
          return;
        }

        var targetRoomID = '';
        if (details.velocity.pixelsPerSecond.dy > 0) {
          targetRoomID = previousRoomID();
        } else if (details.velocity.pixelsPerSecond.dy < 0) {
          targetRoomID = nextRoomID();
        }
        swipingTo(targetRoomID);
      },
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (pageIndex) {
          debugPrint('swiping page, PageView.onPageChanged $pageIndex');
        },
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          debugPrint('swiping page, PageView.itemBuilder $pageIndex, room id:$_targetRoomID');

          return ZegoLiveSwipingLoading(
            loadingRoomID: _targetRoomID,
            roomBuilder: () {
              debugPrint('swiping page, PageView.itemBuilder.builder, page index:$pageIndex live id:$_targetRoomID');

              ///wait express room and zim room login result
              roomLoginNotifier?.resetCheckingData(_targetRoomID);

              return Stack(
                children: [
                  ZegoLivePage(
                    roomID: _targetRoomID,
                    role: ZegoLiveStreamingRole.audience,
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: ElevatedButton(
                      onPressed: updateRoomLists,
                      child: Text('UpdateRoomLists'),
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

  void updateRoomLists() {
    final editingController1 = TextEditingController();
    final editingController2 = TextEditingController();
    final editingController3 = TextEditingController();
    final editingController4 = TextEditingController();
    final editingController5 = TextEditingController();
    final editingController6 = TextEditingController();

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Input room id'),
          content: Column(
            children: [
              CupertinoTextField(controller: editingController1),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController2),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController3),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController4),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController5),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController6),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                var tempRoomIDList = <String>[];
                void addRoomID(String roomID) {
                  if (roomID.isNotEmpty) {
                    tempRoomIDList.add(roomID);
                  }
                }

                addRoomID(editingController1.text);
                addRoomID(editingController2.text);
                addRoomID(editingController3.text);
                addRoomID(editingController4.text);
                addRoomID(editingController5.text);
                addRoomID(editingController6.text);

                debugPrint('swiping page, update room id list:$tempRoomIDList');
                roomIDList = tempRoomIDList;

                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void swipingTo(String targetRoomID) {
    if (targetRoomID == _targetRoomID) {
      debugPrint('swiping page, swipingTo, target room id($targetRoomID) is same as before ($_targetRoomID)');
      return;
    }

    if (targetRoomID.isEmpty) {
      debugPrint('swiping page, swipingTo, target room id is empty');

      return;
    }

    debugPrint('swiping page, swipingTo, $targetRoomID');

    _targetRoomID = targetRoomID;
    _targetRoomDone = false;

    _pageController.jumpToPage(0 == currentPageIndex ? 1 : 0);
  }

  void onRoomStateChanged() {
    final expressDone = expressService.currentRoomID == _targetRoomID &&
        ZegoRoomStateChangedReason.Logined == expressService.currentRoomState;

    debugPrint('swiping page, on room state changed, '
        'target room id:$_targetRoomID, '
        'express room id:${expressService.currentRoomID}, '
        'express room state:${expressService.currentRoomState}, ');

    final zimDone = zimService.currentRoomID == _targetRoomID && ZIMRoomState.connected == zimService.currentRoomState;
    debugPrint('swiping page, on room state changed, '
        'ZIM room id:${zimService.currentRoomID}, '
        'ZIM room state:${zimService.currentRoomState},');

    debugPrint('swiping page, on room state changed, express done:$expressDone, ZIM done:$zimDone');
    if (expressDone && zimDone) {
      _targetRoomDone = true;
    }
  }
}
