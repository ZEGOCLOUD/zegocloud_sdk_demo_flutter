import 'package:flutter/cupertino.dart';

import '../../../internal/sdk/utils/login_notifier.dart';
import 'live_page.dart';

class ZegoSwipingPageBuilder extends StatefulWidget {
  const ZegoSwipingPageBuilder({
    super.key,
    required this.itemBuilder,
    required this.onPageChanged,
    required this.swipingRoomListNotifier,
  });

  final NullableIndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;
  final ValueNotifier<List<ZegoSwipingLiveInfo>> swipingRoomListNotifier;

  @override
  State<ZegoSwipingPageBuilder> createState() => _ZegoSwipingPageBuilderState();
}

class _ZegoSwipingPageBuilderState extends State<ZegoSwipingPageBuilder> {
  final roomLoginNotifier = ZegoRoomLoginNotifier();

  int currentPageIndex = 0;
  int? cachePageIndex;

  int get initialPageIndex => 0;

  @override
  void initState() {
    super.initState();

    roomLoginNotifier.notifier.addListener(onRoomLoginStatedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPageChanged(initialPageIndex);
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
      itemBuilder: widget.itemBuilder,
      onPageChanged: onPageChangedRequest,
    );
  }

  int getRoomIDIndexOfPage(int pageIndex) {
    if (pageIndex > widget.swipingRoomListNotifier.value.length - 1) {
      return pageIndex % widget.swipingRoomListNotifier.value.length;
    }

    return pageIndex;
  }

  void onPageChangedRequest(int page) {
    if (!roomLoginNotifier.notifier.value) {
      /// To prevent failures caused by fast scrolling, cache the scroll page index before the previous room login is completed
      cachePageIndex = page;
    } else {
      onPageChanged(page);
    }
  }

  void onPageChanged(int page) {
    final roomID = widget.swipingRoomListNotifier.value[getRoomIDIndexOfPage(page)].roomID;
    roomLoginNotifier.resetCheckingData(roomID);
    widget.onPageChanged.call(page);
  }
}
