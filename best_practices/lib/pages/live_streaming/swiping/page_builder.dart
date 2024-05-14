import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

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

  final Future<ZegoSwipingPageChangedContext> Function(int pageIndex) onPageWillChanged;
  final void Function(
    ZegoSwipingPageChangedContext changedContext,
  ) onPageChanged;

  @override
  State<ZegoSwipingPageBuilder> createState() => _ZegoSwipingPageBuilderState();
}

class _ZegoSwipingPageBuilderState extends State<ZegoSwipingPageBuilder> {
  final roomLoginNotifier = ZegoRoomLoginNotifier();
  Lock cachePageIndexLocker = Lock();

  int currentPageIndex = 0;
  int? cachePageIndex;
  final pageRoomInfoMapNotifier = ValueNotifier<Map<int, ZegoSwipingPageRoomInfo>>({});

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: roomLoginNotifier.notifier,
      builder: (context, _isRoomLogin, _) {
        final isRoomLogin = roomLoginNotifier.targetRoomID.isEmpty || _isRoomLogin;
        // debugPrint('xxx roomLoginNotifier, '
        //     'roomID:${roomLoginNotifier.targetRoomID}, '
        //     'isRoomLogin:$isRoomLogin, ');
        return PageView.builder(
          physics: isRoomLogin ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          allowImplicitScrolling: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (BuildContext context, int pageIndex) {
            // debugPrint('xxx itemBuilder,'
            //     'pageIndex:$pageIndex ,'
            //     'map:${pageRoomInfoMapNotifier.value}');
            return ValueListenableBuilder<Map<int, ZegoSwipingPageRoomInfo>>(
              valueListenable: pageRoomInfoMapNotifier,
              builder: (context, pageRoomInfoMap, _) {
                // debugPrint('xxx map builder:'
                //     'pageIndex:$pageIndex ,'
                //     'map:${pageRoomInfoMapNotifier.value}');
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
          onPageChanged: onPageChanged,
        );
      },
    );
  }

  void onRoomLoginStatedChanged() {
    // debugPrint('xxx onRoomLoginStatedChanged,'
    //     'login:$roomLoginNotifier, '
    //     'cachePageIndex:$cachePageIndex');

    if (roomLoginNotifier.notifier.value) {
      cachePageIndexLocker.synchronized(() async {
        if (null != cachePageIndex) {
          final pageIndex = cachePageIndex!;
          cachePageIndex = null;

          if (currentPageIndex != pageIndex) {
            onPageChanged(pageIndex);
          }
        }
      });
    }
  }

  Future<void> onPageChangedRequest(int page) async {
    // debugPrint('xxx onPageChangedRequest,'
    //     'page:$page, '
    //     'cachePageIndex:$cachePageIndex, '
    //     'login:$roomLoginNotifier, ');

    if (!roomLoginNotifier.notifier.value) {
      /// previous room login process not finished, wait...
      cachePageIndexLocker.synchronized(() async {
        /// To prevent failures caused by fast scrolling, cache the scroll page index before the previous room login is completed
        cachePageIndex = page;
        // debugPrint('xxx onPageChangedRequest, cache $cachePageIndex');
      });
    } else {
      ///  room had login, will be switch outside
      await onPageChanged(page);
    }
  }

  Future<void> onPageChanged(int pageIndex) async {
    currentPageIndex = pageIndex;

    final pageChangedContext = await widget.onPageWillChanged.call(pageIndex);

    final updatedValue = <int, ZegoSwipingPageRoomInfo>{};
    updatedValue[pageIndex - 1] = pageChangedContext.previousRoomInfo;
    updatedValue[pageIndex] = pageChangedContext.currentRoomInfo;
    updatedValue[pageIndex + 1] = pageChangedContext.nextRoomInfo;
    pageRoomInfoMapNotifier.value = updatedValue;

    // debugPrint('xxx onPageChanged,'
    //     'pageIndex: $pageIndex, '
    //     'map:${pageRoomInfoMapNotifier.value}, '
    //     'context:$pageChangedContext');

    roomLoginNotifier.resetCheckingData(pageChangedContext.currentRoomInfo.roomID);

    widget.onPageChanged(pageChangedContext);
  }
}
