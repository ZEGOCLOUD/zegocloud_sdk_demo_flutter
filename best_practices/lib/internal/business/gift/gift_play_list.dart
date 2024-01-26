part of 'gift_manager.dart';

mixin GiftPlayList {
  final _playListImpl = PlayListImpl();

  PlayListImpl get playList => _playListImpl;
}

class PlayListImpl {
  final playingDataNotifier = ValueNotifier<PlayData?>(null);
  List<PlayData> pendingPlaylist = [];

  void next() {
    if (pendingPlaylist.isEmpty) {
      playingDataNotifier.value = null;
    } else {
      playingDataNotifier.value = pendingPlaylist.removeAt(0);
    }
  }

  void add(
    PlayData data,
  ) {
    if (playingDataNotifier.value != null) {
      pendingPlaylist.add(data);
      return;
    }
    playingDataNotifier.value = data;
  }

  bool clear() {
    playingDataNotifier.value = null;
    pendingPlaylist.clear();

    return true;
  }
}
