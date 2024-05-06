import 'package:flutter/cupertino.dart';

import 'internal/internal.dart';

export 'internal/internal.dart';

class ZEGOSDKManager {
  ZEGOSDKManager._internal();
  factory ZEGOSDKManager() => instance;
  static final ZEGOSDKManager instance = ZEGOSDKManager._internal();

  ExpressService expressService = ExpressService();
  ZIMService zimService = ZIMService();

  Future<void> init(int appID, String? appSign, {ZegoScenario scenario = ZegoScenario.Default}) async {
    await expressService.init(appID: appID, appSign: appSign);
    await zimService.init(appID: appID, appSign: appSign);
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
    await expressService.setRoomScenario(scenario);
    final expressResult = await expressService.loginRoom(roomID, token: token);
    if (expressResult.errorCode != 0) {
      return expressResult;
    }
    final zimResult = await zimService.loginRoom(roomID);

    // rollback if one of them failed
    if (zimResult.errorCode != 0) {
      expressService.logoutRoom();
    }
    return zimResult;
  }

  Future<void> logoutRoom() async {
    debugPrint('sdk manager, logoutRoom');

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
