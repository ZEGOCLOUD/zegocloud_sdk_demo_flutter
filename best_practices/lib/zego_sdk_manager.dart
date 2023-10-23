import 'package:flutter/foundation.dart';

import 'internal/sdk/effect/zego_effects_service.dart';
import 'internal/sdk/express/express_service.dart';
import 'internal/sdk/zim/zim_service.dart';

export 'internal/sdk/express/express_service.dart';
export 'internal/sdk/zim/zim_service.dart';

class ZEGOSDKManager {
  ZEGOSDKManager._internal();
  factory ZEGOSDKManager() => instance;
  static final ZEGOSDKManager instance = ZEGOSDKManager._internal();

  ExpressService expressService = ExpressService.instance;
  ZIMService zimService = ZIMService.instance;
  EffectsService effectsService = EffectsService.instance;

  int appID = 0;
  String appSign = '';

  Future<void> init(int appID, String? appSign, {ZegoScenario scenario = ZegoScenario.Default}) async {
    await expressService.init(appID: appID, appSign: appSign);
    await zimService.init(appID: appID, appSign: appSign);
    await effectsService.init(appID, appSign ?? '');

    this.appID = appID;
    this.appSign = appSign ?? '';
  }

  Future<void> initEffects() async {
    if (!kIsWeb) {
      await effectsService.init(appID, appSign);
      await expressService.enableCustomVideoProcessing(true);
    }
  }

  Future<void> unInitEffects() async {
    if (!kIsWeb) {
      await effectsService.unInit();
      await expressService.enableCustomVideoProcessing(false);
    }
  }

  Future<void> connectUser(String userID, String userName, {String? token}) async {
    await expressService.connectUser(userID, userName, token: token);
    await zimService.connectUser(userID, userName, token: token);
  }

  Future<void> disconnectUser() async {
    await logoutRoom();
    await expressService.disconnectUser();
    await zimService.disconnectUser();
  }

  Future<void> uploadLog() async {
    await Future.wait([
      expressService.uploadLog(),
      zimService.uploadLog(),
    ]);
    return;
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID, ZegoScenario scenario, {String? token}) async {
    // await these two methods
    final expressResult = await expressService.loginRoom(roomID, token: token);
    if (expressResult.errorCode != 0) {
      return expressResult;
    }

    expressService.setRoomScenario(scenario);

    final zimResult = await zimService.loginRoom(roomID);

    // rollback if one of them failed
    if (zimResult.errorCode != 0) {
      expressService.logoutRoom();
    }
    return zimResult;
  }

  Future<void> logoutRoom() async {
    await expressService.logoutRoom();
    await zimService.logoutRoom();
  }

  ZegoSDKUser? get currentUser => expressService.currentUser;
  ZegoSDKUser? getUser(String userID) {
    for (final user in expressService.userInfoList) {
      if (userID == user.userID) {
        return user;
      }
    }
    return null;
  }
}
