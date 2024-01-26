class ZegoGiftItem {
  String name;
  String icon;
  String sourceURL;
  ZegoGiftSource source;
  ZegoGiftType type;
  int weight;

  ZegoGiftItem({
    required this.sourceURL,
    required this.weight,
    this.name = '',
    this.icon = '',
    this.source = ZegoGiftSource.url,
    this.type = ZegoGiftType.svga,
  });
}

enum ZegoGiftSource {
  url,
  asset,
}

enum ZegoGiftType {
  svga,
  mp4,
}

class PlayData {
  ZegoGiftItem giftItem;
  int count;

  PlayData({
    required this.giftItem,
    this.count = 1,
  });
}
