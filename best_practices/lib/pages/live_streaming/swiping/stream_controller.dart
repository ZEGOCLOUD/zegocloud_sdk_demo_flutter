import 'package:flutter/cupertino.dart';

class ZegoSwipingStreamController {
  final _data = ZegoSwipingStreamControllerData();

  void init({int cacheCount = 3}) {
    if (_data.init) {
      return;
    }

    debugPrint('stream controller, init');

    _data
      ..init = true
      ..cacheCount = cacheCount;
  }

  void uninit() {
    if (!_data.init) {
      return;
    }

    debugPrint('stream controller, uninit');

    _data.init = false;
  }

  Future<bool> playRoomStream(String roomID, String streamID) async {
    if (-1 !=
        _data.playingStreams
            .indexWhere((streamData) => streamData.roomID == roomID && streamData.streamID == streamID)) {
      debugPrint('stream controller, playRoomStream, '
          'room id:$roomID, stream id:$streamID, stream is playing before');

      return true;
    }

    if (_data.playingStreams.length > _data.cacheCount) {
      final removedStream = _data.playingStreams.removeAt(0);
      debugPrint('stream controller, cache full, remove $removedStream');

      stopPlayRoomStreaming(removedStream.roomID, removedStream.streamID);
    }

    debugPrint('stream controller, playRoomStream, room id:$roomID, stream id:$streamID');

    _data.playingStreams.add(ZegoSwipingStreamData(
      roomID: roomID,
      streamID: streamID,
    ));

    ///todo

    return true;
  }

  Future<bool> stopPlayRoomStreaming(String roomID, String streamID) async {
    debugPrint('stream controller, stopPlayRoomStreaming, room id:$roomID, stream id:$streamID');

    ///todo
    return true;
  }
}

class ZegoSwipingStreamControllerData {
  bool init = false;
  int cacheCount = 3;
  final playingStreams = <ZegoSwipingStreamData>[];
}

class ZegoSwipingStreamData {
  String roomID = '';
  String streamID = '';

  ZegoSwipingStreamData({
    required this.roomID,
    required this.streamID,
  });
}
