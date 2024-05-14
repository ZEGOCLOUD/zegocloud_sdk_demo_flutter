import 'dart:convert';

import '../../../zego_live_streaming_manager.dart';

extension PKServiceZIMExtension on PKService {
  // zim listener
  void onReceiveUserRequest(IncomingUserRequestReceivedEvent event) {
    final inviterExtendedData = PKExtendedData.parse(event.info.extendedData);
    if (inviterExtendedData == null) {
      return;
    }
    if (inviterExtendedData.type == PKExtendedData.START_PK) {
      final currentRoomID = ZEGOSDKManager().expressService.currentRoomID;
      final userNotHost = currentRoomID.isEmpty || (cohostService?.iamHost() ?? false);
      if (pkInfo != null && userNotHost) {
        rejectPKBattle(event.requestID);
        return;
      }
      final newPKInfo = PKInfo()..requestID = event.requestID;
      for (final callUserInfo in event.info.callUserList) {
        final pkuser = PKUser(
            userID: callUserInfo.userID,
            sdkUser: callUserInfo.userID == localUser?.userID ? localUser! : ZegoSDKUser(userID: callUserInfo.userID, userName: ''))
          ..callUserState = callUserInfo.state
          ..extendedData = callUserInfo.extendedData;
        if (callUserInfo.extendedData.isNotEmpty) {
          final userData = PKExtendedData.parse(callUserInfo.extendedData);
          if (userData != null) {
            pkuser
              ..userName = userData.userName ?? ''
              ..roomID = userData.roomID ?? '';
          }
        }
        if (localUser?.userID == callUserInfo.userID) {
          pkuser
            ..userName = localUser?.userName ?? ''
            ..roomID = ZEGOSDKManager().expressService.currentRoomID
            ..camera.value = localUser?.isCameraOnNotifier.value ?? false
            ..microphone.value = localUser?.isMicOnNotifier.value ?? false;
          newPKInfo.pkUserList.insert(0, pkuser);
        } else {
          if (callUserInfo.userID == inviterExtendedData.userID) {
            pkuser
              ..roomID = inviterExtendedData.roomID ?? ''
              ..userName = inviterExtendedData.userName ?? '';
            newPKInfo.pkUserList.add(pkuser);
          }
        }
      }
      pkInfo = newPKInfo;
      onPKBattleReceived.add(PKBattleReceivedEvent(requestID: event.requestID, info: event.info));
    }
  }

  void onReceiveUserRequestCancel(IncomingUserRequestCancelledEvent event) {
    onPKBattleCancelStreamCtrl.add(PKBattleCancelledEvent(requestID: event.requestID));
  }

  void onUserRequestEnded(UserRequestEndEvent event) {
    if (pkInfo?.requestID == event.requestID) {
      stopPKBattle();
    }
  }

  void onUserRequestStateChanged(UserRequestStateChangeEvent event) {
    if (pkInfo?.requestID == event.requestID) {
      for (final userInfo in event.info.callUserList) {
        var findIfAlreadyAdded = false;
        for (final pkuser in pkInfo!.pkUserList.value) {
          if (pkuser.userID == userInfo.userID) {
            pkuser
              ..callUserState = userInfo.state
              ..extendedData = userInfo.extendedData;
            if (userInfo.extendedData.isNotEmpty) {
              final userData = PKExtendedData.parse(userInfo.extendedData);
              if (userData != null) {
                pkuser
                  ..userName = userData.userName ?? ''
                  ..roomID = userData.roomID ?? '';
              }
            }
            if (pkuser.userID == localUser?.userID) {
              pkuser
                ..roomID = ZEGOSDKManager().expressService.currentRoomID
                ..userName = localUser?.userName ?? ''
                ..camera.value = localUser?.isCameraOnNotifier.value ?? false
                ..microphone.value = localUser?.isMicOnNotifier.value ?? false;
            }
            findIfAlreadyAdded = true;
            break;
          }
        }
        if (!findIfAlreadyAdded) {
          final newPKUser =
              PKUser(userID: userInfo.userID, sdkUser: userInfo.userID == localUser?.userID ? localUser! : ZegoSDKUser(userID: userInfo.userID, userName: ''))
                ..callUserState = userInfo.state
                ..extendedData = userInfo.extendedData;
          if (newPKUser.userID == localUser?.userID) {
            newPKUser
              ..roomID = ZEGOSDKManager().expressService.currentRoomID
              ..userName = localUser?.userName ?? ''
              ..camera.value = localUser?.isCameraOnNotifier.value ?? false
              ..microphone.value = localUser?.isMicOnNotifier.value ?? false;
            pkInfo!.pkUserList.insert(0, newPKUser);
          } else {
            final extendedData = PKExtendedData.parse(userInfo.extendedData);
            if (extendedData != null) {
              newPKUser
                ..roomID = extendedData.roomID ?? ''
                ..userName = extendedData.userName ?? '';
            }
            pkInfo!.pkUserList.add(newPKUser);
          }
        }
      }

      for (final userInfo in event.info.callUserList) {
        if (userInfo.state == ZIMCallUserState.accepted) {
          final oldPKUser = getPKUser(pkInfo!, userInfo.userID);
          if (oldPKUser != null) {
            onPKBattleAcceptedCtrl.add(PKBattleAcceptedEvent(userID: oldPKUser.userID, extendedData: oldPKUser.extendedData));
            _onReceivePKUserAccepted(userInfo);
          }
        } else if (userInfo.state == ZIMCallUserState.rejected) {
          onPKBattleRejectedStreamCtrl.add(PKBattleRejectedEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
          if (localUser != null) {
            checkIfPKEnd(event.requestID, localUser!);
          }
        } else if (userInfo.state == ZIMCallUserState.timeout) {
          onPKBattleTimeoutCtrl.add(PKBattleTimeoutEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
          if (localUser != null) {
            checkIfPKEnd(event.requestID, localUser!);
          }
        } else if (userInfo.state == ZIMCallUserState.quited) {
          onReceivePKUserQuit(event.requestID, userInfo);
          seiTimeMap.remove(userInfo.userID);
        }
      }
    }
  }

  void _onReceivePKUserAccepted(ZIMCallUserInfo userInfo) {
    final pkExtendedData = PKExtendedData.parse(userInfo.extendedData);
    if (pkExtendedData == null || pkInfo == null) {
      return;
    }
    if (pkExtendedData.type == PKExtendedData.START_PK) {
      var moreThanOneAcceptedExceptMe = false;
      var meHasAccepted = false;
      for (final pkuser in pkInfo!.pkUserList.value) {
        if (pkuser.userID == localUser?.userID) {
          meHasAccepted = pkuser.hasAccepted;
        } else {
          if (pkuser.hasAccepted) {
            moreThanOneAcceptedExceptMe = true;
          }
        }
      }
      if (meHasAccepted && moreThanOneAcceptedExceptMe && pkStateNotifier.value != RoomPKState.isStartPK) {
        updatePKMixTask().then((value) {
          if (value.errorCode == 0) {
            startSendSEI();
            checkSEITime();
            pkStateNotifier.value = RoomPKState.isStartPK;
            onPKStartStreamCtrl.add(null);
            for (final pkuser in pkInfo!.pkUserList.value) {
              if (pkuser.hasAccepted) {
                onPKUserJoinCtrl.add(PKBattleUserJoinEvent(userID: pkuser.userID, extendedData: pkuser.extendedData));
              }
            }
          } else {
            pkStateNotifier.value = RoomPKState.isNoPK;
            quitPKBattle(pkInfo?.requestID ?? '');
          }
        });
      } else {
        updatePKMixTask().then((value) {
          if (value.errorCode == 0) {
            onPKUserJoinCtrl.add(PKBattleUserJoinEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
          }
        });
      }
    }
  }

  void onReceivePKUserQuit(String requestID, ZIMCallUserInfo userInfo) {
    if (pkInfo == null) {
      return;
    }
    final selfPKUser = getPKUser(pkInfo!, localUser?.userID ?? '');
    if (selfPKUser != null && selfPKUser.hasAccepted) {
      var moreThanOneAcceptedExceptMe = false;
      var hasWaitingUser = false;
      for (final pkuser in pkInfo!.pkUserList.value) {
        if (pkuser.userID != localUser?.userID) {
          if (pkuser.hasAccepted || pkuser.isWaiting) {
            hasWaitingUser = true;
          }
          if (pkuser.hasAccepted) {
            moreThanOneAcceptedExceptMe = true;
          }
        }
      }
      if (moreThanOneAcceptedExceptMe && pkStateNotifier.value == RoomPKState.isStartPK) {
        updatePKMixTask().then((value) {
          onPKBattleUserQuitCtrl.add(PKBattleUserQuitEvent(userID: userInfo.userID, extendedData: userInfo.extendedData));
        });
      }
      if (!hasWaitingUser) {
        quitPKBattle(requestID);
        stopPKBattle();
      }
    }
  }

  void onReceivePKTimeout(IncomingUserRequestTimeoutEvent event) {
    if (pkInfo?.requestID == event.requestID) {
      pkInfo = null;
      incomingPKRequestTimeoutStreamCtrl.add(IncomingPKRequestTimeoutEvent(requestID: event.requestID));
    }
  }

  void onReceivePKAnswerTimeout(OutgoingUserRequestTimeoutEvent event) {
    outgoingPKRequestAnsweredTimeoutStreamCtrl.add(OutgoingPKRequestTimeoutEvent(requestID: event.requestID));
  }

  void onRoomAttributesUpdated2(RoomAttributesUpdatedEvent event) {
    for (final deleteProperty in event.deleteProperties) {
      deleteProperty.forEach((key, value) {
        pkRoomAttribute.remove(key);
      });
    }
    for (final setProperty in event.setProperties) {
      setProperty.forEach((key, value) {
        pkRoomAttribute[key] = value;
      });
    }

    for (final setProperty in event.setProperties) {
      if (setProperty.keys.contains('pk_users')) {
        onReceivePKRoomAttribute(setProperty);
      }
    }

    for (final deleteProperty in event.deleteProperties) {
      if (deleteProperty.keys.contains('pk_users')) {
        if (pkInfo != null) {
          stopPKBattle();
        } else {
          return;
        }
      }
    }
  }

  void onReceivePKRoomAttribute(Map<String, String> roomProperties) {
    final requestId = roomProperties['request_id'];
    final pkUserList = <PKUser>[];
    final pkUsersStr = roomProperties['pk_users']!;
    final pkUsers = jsonDecode(pkUsersStr) as List;
    for (final userMap in pkUsers) {
      final userString = jsonEncode(userMap);
      final pkUser = PKUser.parse(userString);
      if (!iamHost) {
        pkUser.callUserState = ZIMCallUserState.accepted;
      }
      pkUserList.add(pkUser);
    }

    if (iamHost) {
      if (pkInfo == null) {
        deletePKAttributes();
      }
    } else {
      for (final pkUser in pkUserList) {
        seiTimeMap[pkUser.userID] = DateTime.now().millisecondsSinceEpoch;
      }
      if (pkInfo == null) {
        if (cohostService?.hostNotifier.value != null) {
          pkInfo = PKInfo()
            ..requestID = requestId ?? ''
            ..pkUserList.value = pkUserList;
          checkSEITime();
          ZEGOSDKManager().expressService.startPlayingMixerStream(generateMixerStreamID());
          pkStateNotifier.value = RoomPKState.isStartPK;
          onPKStartStreamCtrl.add(null);

          for (final pkuser in pkInfo!.pkUserList.value) {
            if (pkuser.hasAccepted) {
              onPKUserJoinCtrl.add(PKBattleUserJoinEvent(userID: pkuser.userID, extendedData: pkuser.extendedData));
            }
          }
        }
      } else {
        pkInfo?.pkUserList.value = pkUserList;
        final updateUsers = pkUserList.map((e) => e.userID).toList();
        onPKBattleUserUpdateCtrl.add(PKBattleUserUpdateEvent(userList: updateUsers));
      }
    }
  }
}
