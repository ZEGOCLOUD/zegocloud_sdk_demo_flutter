import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../zego_sdk_manager.dart';
import 'defines.dart';

class ZegoSwipingPageBuilder extends StatefulWidget {
  const ZegoSwipingPageBuilder({
    super.key,
    required this.itemBuilder,
    required this.defaultRoomInfo,
    required this.onPageWillChanged,
    required this.onPageChanged,
  });

  final Widget Function(
    BuildContext context,
    int pageIndex,
    ZegoSwipingPageRoomInfo pageRoomInfo,
  ) itemBuilder;

  final ZegoSwipingPageRoomInfo defaultRoomInfo;

  final Future<ZegoSwipingPageChangedContext> Function(int pageIndex)
      onPageWillChanged;
  final void Function(
    ZegoSwipingPageChangedContext changedContext,
  ) onPageChanged;

  @override
  State<ZegoSwipingPageBuilder> createState() => _ZegoSwipingPageBuilderState();
}

class _ZegoSwipingPageBuilderState extends State<ZegoSwipingPageBuilder> {
  final roomLoginNotifier = ZegoRoomLoginNotifier();

  int currentPageIndex = 0;
  int? cachePageIndex;
  final pageRoomInfoMapNotifier =
      ValueNotifier<Map<int, ZegoSwipingPageRoomInfo>>({});

  int get initialPageIndex => 0;

  @override
  void initState() {
    super.initState();

    pageRoomInfoMapNotifier.value[0] = widget.defaultRoomInfo;

    roomLoginNotifier.notifier.addListener(onRoomLoginStatedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await onPageChanged(initialPageIndex);
    });
  }

  void onRoomLoginStatedChanged() {
    if (roomLoginNotifier.notifier.value) {
      if (null != cachePageIndex) {
        final pageIndex = cachePageIndex!;
        cachePageIndex = null;

        if (currentPageIndex != pageIndex) {
          onPageChanged(pageIndex);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      allowImplicitScrolling: true,
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int pageIndex) {
        return ValueListenableBuilder<Map<int, ZegoSwipingPageRoomInfo>>(
          valueListenable: pageRoomInfoMapNotifier,
          builder: (context, pageRoomInfoMap, _) {
            if (!pageRoomInfoMap.keys.contains(pageIndex)) {
              return Stack(
                children: [
                  const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
                  Text(
                    'index:$pageIndex',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                widget.itemBuilder(
                  context,
                  pageIndex,
                  pageRoomInfoMap[pageIndex]!,
                ),
                Text(
                  'index:$pageIndex, roomID:${pageRoomInfoMap[pageIndex]!.roomID}',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          },
        );
      },
      onPageChanged: onPageChangedRequest,
    );
  }

  Future<void> onPageChangedRequest(int page) async {
    if (!roomLoginNotifier.notifier.value) {
      /// To prevent failures caused by fast scrolling, cache the scroll page index before the previous room login is completed
      cachePageIndex = page;
    } else {
      await onPageChanged(page);
    }
  }

  Future<void> onPageChanged(int pageIndex) async {
    currentPageIndex = pageIndex;

    final pageChangedContext = await widget.onPageWillChanged.call(pageIndex);

    final updatedValue =
        Map<int, ZegoSwipingPageRoomInfo>.from(pageRoomInfoMapNotifier.value);
    updatedValue[pageIndex - 1] = pageChangedContext.previousRoomInfo;
    updatedValue[pageIndex] = pageChangedContext.currentRoomInfo;
    updatedValue[pageIndex + 1] = pageChangedContext.nextRoomInfo;
    pageRoomInfoMapNotifier.value = updatedValue;

    roomLoginNotifier
        .resetCheckingData(pageChangedContext.currentRoomInfo.roomID);

    widget.onPageChanged(pageChangedContext);
  }
}
