import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_effects_plugin/zego_effects_plugin.dart';

import 'internal/beauty_ability/zego_beauty_ability.dart';
import 'internal/beauty_ability/zego_beauty_type.dart';
import 'internal/zego_effects_helper.dart';
import 'internal/zego_effects_service_extension.dart';

class EffectsService {
  EffectsService._internal();
  factory EffectsService() => instance;
  static final EffectsService instance = EffectsService._internal();

  final methodChannel = const MethodChannel('zego_beauty_effects');

  int appID = 0;
  String appSign = '';

  final backendApiUrl =
      'https://aieffects-api.zego.im/?Action=DescribeEffectsLicense';

  String resourcesFolder = '';

  final beautyAbilities = <ZegoBeautyType, ZegoBeautyAbility>{};

  Future<void> init(int appID, String appSign) async {
    this.appID = appID;
    this.appSign = appSign;

    ZegoEffectsPlugin.instance.getAuthInfo(appSign).then((authInfo) {
      EffectsHelper.getLicence(backendApiUrl, appID, authInfo).then((license) {
        initEffects(license);
      });
    });
  }

  Future<void> unInit() async {
    await ZegoEffectsPlugin.instance.destroy();
  }

  Future<void> initEffects(String license) async {
    await EffectsHelper.setResources();
    resourcesFolder = EffectsHelper.resourcesFolder;

    final ret = await ZegoEffectsPlugin.instance.create(license);
    debugPrint('ZegoEffectsPlugin init result: $ret');

    await ZegoEffectsPlugin.instance.initEnv(const Size(720, 1280));

    await enableCustomVideoProcessing();

    // callback of effects sdk.
    ZegoEffectsPlugin.registerEventCallback(
      onEffectsError: onEffectsError,
      onEffectsFaceDetected: onEffectsFaceDetected,
    );

    initBeautyAbilities();

    ZegoEffectsPlugin.instance.enableFaceDetection(true);
  }

  void onEffectsError(int errorCode, String desc) {
    debugPrint('effects errorCode: $errorCode, desc: $desc');
    if (errorCode == 5000002) {
      EffectsHelper.inValidLicense();
      init(appID, appSign);
    }
  }

  void onEffectsFaceDetected(double score, Point point, Size size) {
    debugPrint(
        'onEffectsFaceDetected, score: $score, point: $point, size: $size');
  }

  Future<void> enableCustomVideoProcessing() async {
    await methodChannel.invokeMethod('enableCustomVideoProcessing');
  }

  Future<String?> getResourcesFolder() async {
    final folder =
        await methodChannel.invokeMethod<String>('getResourcesFolder');
    return folder;
  }
}
