part of 'zim_service.dart';

extension ZIMServiceAvatar on ZIMService {
  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url) async {
    final result = await ZIM.getInstance()!.updateUserAvatarUrl(url);
    userAvatarUrlMap[currentZimUserInfo!.userID] = result.userAvatarUrl;
    ZEGOSDKManager().currentUser!.avatarUrlNotifier.value = result.userAvatarUrl;
    return result;
  }

  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(List<String> userIDList) async {
    final config = ZIMUserInfoQueryConfig();
    final result = await ZIM.getInstance()!.queryUsersInfo(userIDList, config);
    for (final userFullInfo in result.userList) {
      userAvatarUrlMap[userFullInfo.baseInfo.userID] = userFullInfo.userAvatarUrl;
      userNameMap[userFullInfo.baseInfo.userID] = userFullInfo.baseInfo.userName;
      ZEGOSDKManager().getUser(userFullInfo.baseInfo.userID)?.avatarUrlNotifier.value = userFullInfo.userAvatarUrl;
    }
    return result;
  }

  String? getUserAvatar(String userID) {
    return userAvatarUrlMap[userID];
  }

  String? getUserName(String userID) {
    return userNameMap[userID];
  }
}
