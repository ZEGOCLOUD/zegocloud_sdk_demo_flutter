import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../zego_sdk_manager.dart';

part 'gift_service.dart';

class ZegoGiftController with GiftService {
  static final ZegoGiftController _instance = ZegoGiftController._internal();
  factory ZegoGiftController() => _instance;
  ZegoGiftController._internal() {
    ZEGOSDKManager().expressService.onMediaPlayerStateUpdateCtrl.stream.listen(onGiftPlayerStateUpdate);
    createMediaPlayer();
    playingGiftDataNotifier.addListener(onPlayingGiftDataUpdate);
    giftWidget = ValueListenableBuilder(
      valueListenable: shouldShowNotifier,
      builder: (context, shouldShow, _) {
        return shouldShow
            ? IgnorePointer(ignoring: true, child: _mediaPlayerView ?? const SizedBox.shrink())
            : const SizedBox.shrink();
      },
    );
  }

  void onPlayingGiftDataUpdate() {
    if (playingGiftDataNotifier.value != null) {
      loadResource(playingGiftDataNotifier.value!.giftPath!);
      startMediaPlayer();
    }
  }

  void onGiftPlayerStateUpdate(ZegoPlayerStateChangeEvent event) {
    switch (event.state) {
      case ZegoMediaPlayerState.NoPlay:
        shouldShowNotifier.value = false;
        break;
      case ZegoMediaPlayerState.Playing:
        shouldShowNotifier.value = true;
        break;
      case ZegoMediaPlayerState.Pausing:
        shouldShowNotifier.value = false;
        break;
      case ZegoMediaPlayerState.PlayEnded:
        shouldShowNotifier.value = false;
        clearView();
        next();
        break;
    }
  }

  late Widget giftWidget;

  ValueNotifier<bool> shouldShowNotifier = ValueNotifier<bool>(false);
  Widget? _mediaPlayerView;
  ZegoMediaPlayer? _mediaPlayer;
  int _mediaPlayerViewID = -1;
  String? currentResource;

  final playingGiftDataNotifier = ValueNotifier<ZegoGiftData?>(null);
  List<ZegoGiftData> pendingPlaylist = [];

  void next() {
    if (pendingPlaylist.isEmpty) {
      playingGiftDataNotifier.value = null;
    } else {
      playingGiftDataNotifier.value = pendingPlaylist.removeAt(0);
    }
  }

  void addToPlayingList(ZegoGiftData data) {
    if (playingGiftDataNotifier.value != null) {
      pendingPlaylist.add(data);
      return;
    }
    playingGiftDataNotifier.value = data;
  }

  bool clearPlayingList() {
    playingGiftDataNotifier.value = null;
    pendingPlaylist.clear();

    return true;
  }

  /// create media player
  Future<Widget?> createMediaPlayer() async {
    _mediaPlayer ??= await ZegoExpressEngine.instance.createMediaPlayer();
    _mediaPlayer?.clearView();
    // create widget
    if (_mediaPlayerViewID == -1) {
      _mediaPlayerView = await ZegoExpressEngine.instance.createCanvasView((viewID) {
        _mediaPlayerViewID = viewID;
        _mediaPlayer?.setPlayerCanvas(ZegoCanvas(viewID, alphaBlend: true));
      });
    }
    return _mediaPlayerView;
  }

  void destroyMediaPlayer() {
    currentResource = null;
    _mediaPlayerView = null;
    if (_mediaPlayer != null) {
      ZegoExpressEngine.instance.destroyMediaPlayer(_mediaPlayer!);
      _mediaPlayer = null;
    }
    if (_mediaPlayerViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_mediaPlayerViewID);
      _mediaPlayerViewID = -1;
    }
  }

  void clearView() {
    _mediaPlayer?.clearView();
  }

  Future<int> loadResource(String giftPath, {ZegoAlphaLayoutType alphaLayout = ZegoAlphaLayoutType.Left}) async {
    if (currentResource == giftPath) return 0;
    var ret = -1;
    if (_mediaPlayer != null) {
      debugPrint('Mp4 Player loadResource $giftPath');
      final source = ZegoMediaPlayerResource.defaultConfig()
        ..loadType = ZegoMultimediaLoadType.FilePath
        ..alphaLayout = alphaLayout
        ..filePath = giftPath;
      currentResource = giftPath;
      final result = await _mediaPlayer!.loadResourceWithConfig(source);
      ret = result.errorCode;
    }
    return ret;
  }

  void startMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.start();
    }
  }

  void pauseMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.pause();
    }
  }

  void resumeMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.resume();
    }
  }

  void stopMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.stop();
    }
  }
}

class ZegoGiftData {
  String? giftPath;

  ZegoGiftData({this.giftPath});
}

Future<String> getPathFromAssetOrCache(String asset) async {
  final cache = await DefaultCacheManager().getFileFromCache(asset);
  if (cache == null) {
    final assetData = await rootBundle.load(asset);
    final cacheFile = await DefaultCacheManager().putFile(asset, assetData.buffer.asUint8List());
    return cacheFile.path;
  } else {
    return cache.file.path;
  }
}
