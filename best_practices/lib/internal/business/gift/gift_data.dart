import 'defines.dart';

final List<ZegoGiftItem> giftItemList = [
  ZegoGiftItem(
    name: 'Music Box1',
    icon: 'assets/gift/musicBox.png',
    sourceURL:
        'https://storage.zego.im/sdk-doc/Pics/zegocloud/gift/music_box.mp4',
    source: ZegoGiftSource.url,
    type: ZegoGiftType.mp4,
    weight: 1,
  ),
  ZegoGiftItem(
    name: 'Music Box2',
    icon: 'assets/gift/musicBox.png',
    sourceURL:
        'https://storage.zego.im/sdk-doc/Pics/zegocloud/gift/music_box.mp4',
    source: ZegoGiftSource.url,
    type: ZegoGiftType.mp4,
    weight: 10,
  ),
  ZegoGiftItem(
    name: 'Music Box3',
    icon: 'assets/gift/musicBox.png',
    sourceURL:
        'https://storage.zego.im/sdk-doc/Pics/zegocloud/gift/music_box.mp4',
    source: ZegoGiftSource.url,
    type: ZegoGiftType.mp4,
    weight: 100,
  ),
  ZegoGiftItem(
    name: 'rocket',
    icon: 'assets/gift/rocket.png',
    sourceURL: 'assets/gift/rocket.svga',
    source: ZegoGiftSource.asset,
    type: ZegoGiftType.svga,
    weight: 1,
  ),
  ZegoGiftItem(
    name: 'crown',
    icon: 'assets/gift/crown.png',
    sourceURL: 'assets/gift/crown.svga',
    source: ZegoGiftSource.asset,
    type: ZegoGiftType.svga,
    weight: 100,
  ),
];

ZegoGiftItem? queryGiftInItemList(String name) {
  final index = giftItemList.indexWhere((item) => item.name == name);
  return -1 != index ? giftItemList.elementAt(index) : null;
}
