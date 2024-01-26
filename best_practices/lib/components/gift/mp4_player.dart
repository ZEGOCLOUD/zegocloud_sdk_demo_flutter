import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../zego_sdk_manager.dart';

class GiftMp4Player {
  static final GiftMp4Player _instance = GiftMp4Player._internal();
  factory GiftMp4Player() => _instance;
  GiftMp4Player._internal();

  Widget? _mediaPlayerWidget;
  ZegoMediaPlayer? _mediaPlayer;
  int _mediaPlayerViewID = -1;

  /// create media player
  Future<Widget?> createMediaPlayer() async {
    _mediaPlayer ??= await ZegoExpressEngine.instance.createMediaPlayer();
    // create widget
    if (_mediaPlayerViewID == -1) {
      _mediaPlayerWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
        _mediaPlayerViewID = viewID;
        _mediaPlayer?.setPlayerCanvas(ZegoCanvas(viewID, alphaBlend: true));
      });
    }
    return _mediaPlayerWidget;
  }

  void destroyMediaPlayer() {
    if (_mediaPlayer != null) {
      ZegoExpressEngine.instance.destroyMediaPlayer(_mediaPlayer!);
      _mediaPlayer = null;
    }
    destroyPlayerView();
  }

  void destroyPlayerView() {
    if (_mediaPlayerViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_mediaPlayerViewID);
      _mediaPlayerViewID = -1;
    }
  }

  void clearView() {
    _mediaPlayer?.clearView();
  }

  Future<int> loadResource(String url, {ZegoAlphaLayoutType layoutType = ZegoAlphaLayoutType.Left}) async {
    debugPrint('Mp4 Player loadResource: $url');
    int ret = -1;
    if (_mediaPlayer != null) {
      ZegoMediaPlayerResource source = ZegoMediaPlayerResource.defaultConfig();
      source.filePath = url;
      source.loadType = ZegoMultimediaLoadType.FilePath;
      source.alphaLayout = layoutType;
      var result = await _mediaPlayer!.loadResourceWithConfig(source);
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
