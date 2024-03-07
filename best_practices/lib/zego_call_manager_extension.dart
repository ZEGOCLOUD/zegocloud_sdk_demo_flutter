import 'package:flutter/cupertino.dart';

import 'pages/call/call.dart';

extension ZegoCallManagerExtension on ZegoCallManager {
  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      for (final user in event.userList) {
        if (currentCallData != null) {
          for (final callUser in currentCallData!.callUserList) {
            if (callUser.userID == user.userID) {
              final sdkUser = ZEGOSDKManager().getUser(user.userID)
                ?..avatarUrlNotifier.value = callUser.headUrl
                ..userName = ZEGOSDKManager().zimService.getUserName(callUser.userID) ?? '';
              callUser.sdkUserNoti.value = sdkUser;
            }
          }
        }
      }
    } else {
      for (final user in event.userList) {
        if (currentCallData != null) {
          for (final callUser in currentCallData!.callUserList) {
            if (callUser.userID == user.userID) {
              callUser.sdkUserNoti.value = null;
            }
          }
        }
      }
    }
  }

  void onInComingUserRequestReceived(IncomingUserRequestReceivedEvent event) {
    final extendedData = CallExtendedData.parse(event.info.extendedData);
    if (!isCallBusiness(extendedData?.type)) {
      return;
    }
    final inRoom = ZEGOSDKManager().expressService.currentRoomID.isNotEmpty;
    final inviteeList = event.info.callUserList.map((e) => e.userID).toList();
    final info = ZegoCallInvitationReceivedInfo()
      ..inviter = event.info.inviter
      ..inviteeList = inviteeList
      ..extendedData = event.info.extendedData;
    if (inRoom || (currentCallData != null && currentCallData?.callID != event.requestID)) {
      incomingCallInvitationReceivedStreamCtrl
          .add(IncomingCallInvitationReceivedEvent(callID: event.requestID, info: info));
      return;
    }
    final userIDList = event.info.callUserList.map((e) => e.userID).toList();
    ZEGOSDKManager().zimService.queryUsersInfo(userIDList).then((value) {
      final callData = ZegoCallData()
        ..callID = event.requestID
        ..callUserList = []
        ..callType = extendedData!.type
        ..inviter = CallUserInfo(userID: info.inviter);

      for (final userInfo in event.info.callUserList) {
        final callUser = CallUserInfo(userID: userInfo.userID)
          ..sdkUserNoti.value =
              userInfo.userID == localUser?.userID ? localUser : ZEGOSDKManager().getUser(userInfo.userID)
          ..updateCallUserState(userInfo.state)
          ..extendedData = userInfo.extendedData;
        callData.callUserList.add(callUser);
      }
      currentCallData = callData;

      incomingCallInvitationReceivedStreamCtrl
          .add(IncomingCallInvitationReceivedEvent(callID: event.requestID, info: info));
    });
  }

  void onUserRequestStateChanged(UserRequestStateChangeEvent event) {
    if (currentCallData?.callID == event.requestID) {
      debugPrint('onUserRequestStateChanged:$event');
      for (final userInfo in event.info.callUserList) {
        var findIfAlreadyAdded = false;
        var hasUserStateUpdate = false;
        for (final callUser in currentCallData!.callUserList) {
          if (callUser.userID == userInfo.userID) {
            if (callUser.callUserState.value != userInfo.state) {
              callUser.updateCallUserState(userInfo.state);
              hasUserStateUpdate = true;
            }
            findIfAlreadyAdded = true;
          }
        }
        if (!findIfAlreadyAdded) {
          hasUserStateUpdate = true;
          final callUser = CallUserInfo(userID: userInfo.userID)
            ..sdkUserNoti.value =
                userInfo.userID == localUser?.userID ? localUser : ZEGOSDKManager().getUser(userInfo.userID)
            ..updateCallUserState(userInfo.state)
            ..extendedData = userInfo.extendedData;
          currentCallData?.callUserList.add(callUser);
        }

        if (hasUserStateUpdate) {
          onCallUserUpdateStreamCtrl
              .add(OnCallUserUpdateEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
        }
      }
      final receivedUsers = <ZIMCallUserInfo>[];
      for (final userInfo in event.info.callUserList) {
        switch (userInfo.state) {
          case ZIMCallUserState.received:
            debugPrint('onUserRequestStateChanged received:${userInfo.userID}');
            receivedUsers.add(userInfo);
            onReceiveCallUserReceived(receivedUsers);
            break;
          case ZIMCallUserState.accepted:
            debugPrint('onUserRequestStateChanged accept:${userInfo.userID}');
            onReceiveCallUserAccepted(userInfo);
            break;
          case ZIMCallUserState.rejected:
            debugPrint('onUserRequestStateChanged reject:${userInfo.userID}');
            outgoingCallInvitationRejectedStreamCtrl
                .add(OutgoingCallInvitationRejectedEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
            if (localUser != null) {
              checkIfPKEnd(event.requestID, localUser!);
            }
            break;
          case ZIMCallUserState.quited:
            onReceiveCallUserQuit(event.requestID, userInfo);
            break;
          case ZIMCallUserState.timeout:
            outgoingCallInvitationTimeoutStreamCtrl
                .add(OutgoingCallTimeoutEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
            if (localUser != null) {
              checkIfPKEnd(event.requestID, localUser!);
            }
            break;
          default:
        }
      }
    }
  }

  void onUserRequestEnded(UserRequestEndEvent event) {
    if (currentCallData?.callID == event.requestID) {
      stopCall();
    }
  }

  void onInComingUserRequestTimeout(IncomingUserRequestTimeoutEvent event) {
    if (currentCallData?.callID == event.requestID) {
      incomingCallInvitationTimeoutStreamCtrl.add(event);
      stopCall();
    }
  }

  void onReceiveCallUserReceived(List<ZIMCallUserInfo> userInfoList) {
    if (userInfoList.isNotEmpty) {
      final userIDList = userInfoList.map((e) => e.userID).toList();
      ZEGOSDKManager().zimService.queryUsersInfo(userIDList).then((value) {
        onCallUserInfoUpdateStreamCtrl.add(OnCallUserInfoUpdateEvent(userList: userIDList));
      });
    }
  }

  void onReceiveCallUserAccepted(ZIMCallUserInfo userInfo) {
    if (currentCallData == null) {
      return;
    }
    var moreThanOneAcceptedExceptMe = false;
    var meHasAccepted = false;
    for (final callUser in currentCallData!.callUserList) {
      if (callUser.userID == localUser?.userID) {
        meHasAccepted = callUser.hasAccepted.value;
      } else {
        if (callUser.hasAccepted.value) {
          moreThanOneAcceptedExceptMe = true;
        }
      }
    }

    if (currentCallData!.isGroupCall) {
      if (meHasAccepted && !isCallStart) {
        isCallStart = true;
        onCallStartStreamCtrl.add(null);
      }
    } else {
      if (meHasAccepted && moreThanOneAcceptedExceptMe && !isCallStart) {
        isCallStart = true;
        onCallStartStreamCtrl.add(null);
      }
    }
    onOutgoingCallInvitationAccepted
        .add(OnOutgoingCallAcceptedEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
  }

  void onReceiveCallUserQuit(String requestID, ZIMCallUserInfo userInfo) {
    if (currentCallData != null) {
      final selfCallUser = getCallUser(currentCallData!, localUser?.userID ?? '');
      if (selfCallUser != null && selfCallUser.hasAccepted.value) {
        var moreThanOneAcceptedExceptMe = false;
        var hasWaitingUser = false;
        for (final callUser in currentCallData!.callUserList) {
          if (callUser.userID != localUser?.userID) {
            if (callUser.hasAccepted.value || callUser.isWaiting.value) {
              hasWaitingUser = true;
            }
            if (callUser.hasAccepted.value) {
              moreThanOneAcceptedExceptMe = true;
            }
          }
        }
        if (moreThanOneAcceptedExceptMe) {
          onCallUserQuitStreamCtrl.add(CallUserQuitEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
        }
        if (!hasWaitingUser) {
          quitCall();
        }
      }
    }
  }

  void checkIfPKEnd(String requestID, ZegoSDKUser currentUser) {
    if (currentCallData == null) {
      return;
    }
    final selfCallUser = getCallUser(currentCallData!, currentUser.userID);
    if (selfCallUser != null) {
      if (selfCallUser.hasAccepted.value) {
        var hasWaitingUser = false;
        for (final callUser in currentCallData!.callUserList) {
          if (callUser.userID != localUser?.userID) {
            // except self
            if (callUser.hasAccepted.value || callUser.isWaiting.value) {
              hasWaitingUser = true;
            }
          }
        }
        if (!hasWaitingUser) {
          quitCall();
          stopCall();
        }
      }
    }
  }

  CallUserInfo? getCallUser(ZegoCallData callData, String userID) {
    for (final callUser in callData.callUserList) {
      if (callUser.userID == userID) {
        return callUser;
      }
    }
    return null;
  }

  void stopCall() {
    clearCallData();
    leaveRoom();
    onCallEndStreamCtrl.add(null);
  }
}
