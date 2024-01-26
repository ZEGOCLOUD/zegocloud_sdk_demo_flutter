part of 'gift_manager.dart';

mixin GiftProtocol {
  final _giftProtocolImpll = GiftProtocolImpll();
  GiftProtocolImpll get service => _giftProtocolImpll;
}

class GiftProtocolImpll {
  late int _appID;
  late String _liveID;
  late String _localUserID;
  late String _localUserName;

  final List<StreamSubscription<dynamic>?> _subscriptions = [];

  final recvNotifier = ValueNotifier<ZegoGiftProtocolItem?>(null);

  void init({required int appID, required String liveID, required String localUserID, required String localUserName}) {
    _appID = appID;
    _liveID = liveID;
    _localUserID = localUserID;
    _localUserName = localUserName;

    _subscriptions.add(ZEGOSDKManager().zimService.onRoomCommandReceivedEventStreamCtrl.stream.listen((event) {
      onInRoomCommandMessageReceived(event);
    }));
  }

  void uninit() {
    for (final subscription in _subscriptions) {
      subscription?.cancel();
    }
    GiftMp4Player().destroyMediaPlayer();
  }

  Future<bool> sendGift({
    required String name,
    required int count,
  }) async {
    final data = ZegoGiftProtocol(
      appID: _appID,
      liveID: _liveID,
      localUserID: _localUserID,
      localUserName: _localUserName,
      giftItem: ZegoGiftProtocolItem(
        name: name,
        count: count,
      ),
    ).toJson();

    ///! This is just a demo for synchronous display effects.
    ///!
    ///! If it involves billing or your business logic,
    ///! please use the SERVER API to send a Message of type ZIMCommandMessage.
    ///!
    ///! https://docs.zegocloud.com/article/16201
    debugPrint('! ${'*' * 80}');
    debugPrint('! ** Warning: This is just a demo for synchronous display effects.');
    debugPrint('! ** ');
    debugPrint('! ** If it involves billing or your business logic,');
    debugPrint('! ** please use the SERVER API to send a Message of type ZIMCommandMessage.');
    debugPrint('! ${'*' * 80}');

    debugPrint('try send gift, name:$name, count:$count, data:$data');
    ZEGOSDKManager().zimService.sendRoomCommand(data).then((result) {
      debugPrint('send gift result:$result');
    });
    return true;
  }

  Uint8List _stringToUint8List(String input) {
    List<int> utf8Bytes = utf8.encode(input);
    Uint8List uint8List = Uint8List.fromList(utf8Bytes);
    return uint8List;
  }

  void onInRoomCommandMessageReceived(OnRoomCommandReceivedEvent event) {
    debugPrint('onInRoomCommandMessageReceived: ${event.command}');
    final message = event.command;
    final senderUserID = event.senderID;
    // You can display different animations according to gift-type
    if (senderUserID != _localUserID) {
      final gift = ZegoGiftProtocol.fromJson(message);
      recvNotifier.value = gift.giftItem;
    }
  }
}

class ZegoGiftProtocolItem {
  String name = '';
  int count = 0;

  ZegoGiftProtocolItem({required this.name, required this.count});
  ZegoGiftProtocolItem.empty();
}

class ZegoGiftProtocol {
  int appID = 0;
  String liveID = '';
  String localUserID = '';
  String localUserName = '';
  ZegoGiftProtocolItem giftItem;

  ZegoGiftProtocol({
    required this.appID,
    required this.liveID,
    required this.localUserID,
    required this.localUserName,
    required this.giftItem,
  });

  String toJson() => json.encode({
        'app_id': appID,
        'room_id': liveID,
        'user_id': localUserID,
        'user_name': localUserName,
        'gift_name': giftItem.name,
        'gift_count': giftItem.count,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

  factory ZegoGiftProtocol.fromJson(String jsonData) {
    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(jsonData) as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('protocol data is not json:$jsonData');
    }
    return ZegoGiftProtocol(
      appID: json['app_id'] ?? 0,
      liveID: json['room_id'] ?? '',
      localUserID: json['user_id'] ?? '',
      localUserName: json['user_name'] ?? '',
      giftItem: ZegoGiftProtocolItem(
        name: json['gift_name'] ?? 0,
        count: json['gift_count'] ?? 0,
      ),
    );
  }
}
