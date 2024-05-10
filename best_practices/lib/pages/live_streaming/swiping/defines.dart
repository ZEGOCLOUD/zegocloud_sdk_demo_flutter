class ZegoLiveSwipingConfig {
  ZegoLiveSwipingConfig({
    required this.requiredCurrentLive,
    required this.requiredPreviousLive,
    required this.requiredNextLive,
    required this.onPageChanged,
  });

  final Future<ZegoSwipingPageRoomInfo> Function() requiredPreviousLive;
  final Future<ZegoSwipingPageRoomInfo> Function() requiredNextLive;
  final Future<ZegoSwipingPageRoomInfo> Function() requiredCurrentLive;

  void Function(int) onPageChanged;
}

class ZegoSwipingPageChangedContext {
  ZegoSwipingPageChangedContext({
    required this.currentPageIndex,
    required this.currentRoomInfo,
    required this.previousRoomInfo,
    required this.nextRoomInfo,
  });

  int currentPageIndex = 0;
  ZegoSwipingPageRoomInfo currentRoomInfo;
  ZegoSwipingPageRoomInfo previousRoomInfo;
  ZegoSwipingPageRoomInfo nextRoomInfo;

  @override
  String toString() {
    return 'ZegoSwipingPageChangedResult{'
        'currentPageIndex:$currentPageIndex, '
        'currentRoomInfo:$currentRoomInfo, '
        'previousRoomInfo:$previousRoomInfo, '
        'nextRoomInfo:$nextRoomInfo, '
        '}';
  }
}

class ZegoSwipingPageRoomInfo {
  ZegoSwipingPageRoomInfo({
    this.roomID = '',
    this.hostID = '',
  });

  ZegoSwipingPageRoomInfo.empty();

  bool get isEmpty => roomID.isEmpty || hostID.isEmpty;

  String roomID = '';
  String hostID = '';

  @override
  String toString() {
    return 'ZegoSwipingPageRoomInfo{'
        'roomID:$roomID, '
        'hostID:$hostID, '
        '}';
  }
}
