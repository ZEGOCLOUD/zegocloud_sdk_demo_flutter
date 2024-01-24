import 'dart:convert';

import 'package:dio/dio.dart';

import '../zego_sdk_key_center.dart';
import '../zego_sdk_manager.dart';
import 'service/impl/zegocloud_token.dart';

class YourGameServer {
  final miniGameHostUrl = ;//'https://mini-game-test-server.zego.im';
  final apiToken = 'api/token';
  final apiGetUserCurrency = 'api/getUserCurrency';
  final apiExchangeUserCurrency = 'api/exchangeUserCurrency';
  final dio = Dio();

  Future<String> getToken({String? serverSecret}) async {
    if (serverSecret?.isNotEmpty ?? false) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      return ZegoTokenUtils.generateToken(SDKKeyCenter.appID, serverSecret!, ZEGOSDKManager().currentUser!.userID);
    }
    final response = await dio.post('$miniGameHostUrl/$apiToken',
        data: {'app_id': SDKKeyCenter.appID, 'user_id': ZEGOSDKManager().currentUser!.userID});
    return response.data.toString();
  }

  Future<dynamic> getUserCurrency({String? userID, required String gameID}) async {
    Response response;
    final dio = Dio();
    response = await dio.post('$miniGameHostUrl/$apiGetUserCurrency', data: {
      'UserId': userID ?? ZEGOSDKManager().currentUser!.userID,
      'AppId': SDKKeyCenter.appID,
      'MiniGameId': gameID,
    });

    return json.decode(response.data.toString());
  }

  Future<dynamic> exchangeUserCurrency(
      {required String outOrderId, required String gameID, required int exchangeValue}) async {
    final response = await dio.post('$miniGameHostUrl/$apiExchangeUserCurrency', data: {
      'OutOrderId': DateTime.now().millisecondsSinceEpoch.toString(),
      'UserId': ZEGOSDKManager().currentUser!.userID,
      'MiniGameId': gameID,
      'AppId': SDKKeyCenter.appID,
      'CurrencyDiff': exchangeValue,
    });

    return json.decode(response.data.toString());
  }

  factory YourGameServer() => instance;
  static final YourGameServer instance = YourGameServer._internal();
  YourGameServer._internal();
}
