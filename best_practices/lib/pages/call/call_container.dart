// ignore_for_file: omit_local_variable_types, prefer_final_locals

import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/components.dart';
import 'call.dart';

class CallContainer extends StatefulWidget {
  const CallContainer({super.key});
  @override
  State<CallContainer> createState() => CallContainerState();
}

class CallContainerState extends State<CallContainer> {
  ListNotifier<CallUserInfo> enableShowUserNoti = ListNotifier([]);

  List<StreamSubscription> subscriptions = [];

  @override
  void dispose() {
    super.dispose();
    for (final element in subscriptions) {
      element.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    final callManager = ZegoCallManager();
    subscriptions.addAll([
      callManager.onCallUserQuitStreamCtrl.stream.listen(onCallUserQuit),
      callManager.outgoingCallInvitationTimeoutStreamCtrl.stream.listen(onOutgoingCallTimeOut),
      callManager.onCallUserUpdateStreamCtrl.stream.listen(onCallUserUpdate)
    ]);

    if (ZegoCallManager().currentCallData != null) {
      for (final callUser in ZegoCallManager().currentCallData!.callUserList) {
        if (callUser.isWaiting.value || callUser.hasAccepted.value) {
          enableShowUserNoti.add(callUser);
        }
      }
    }
  }

  List<CallUserInfo> seatingArrangement(List<CallUserInfo> enableShowUserList) {
    final userList = <CallUserInfo>[];
    final waitingUser = <CallUserInfo>[];
    CallUserInfo? localUserInfo;
    for (final callUserInfo in enableShowUserList) {
      if (callUserInfo.userID == ZEGOSDKManager().currentUser?.userID) {
        localUserInfo = callUserInfo;
      } else {
        if (callUserInfo.isWaiting.value) {
          waitingUser.add(callUserInfo);
        }
        if (callUserInfo.hasAccepted.value) {
          userList.add(callUserInfo);
        }
      }
    }
    if (localUserInfo != null) {
      userList.insert(0, localUserInfo);
    }
    userList.addAll(waitingUser);
    return userList;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CallUserInfo>>(
        valueListenable: enableShowUserNoti,
        builder: (context, enableShowUsers, _) {
          final userList = seatingArrangement(enableShowUsers);
          if (enableShowUsers.length > 2) {
            return groupCallView(userList);
          } else {
            return oneOnoneView(userList);
          }
        });
  }

  Widget oneOnoneView(List<CallUserInfo> userList) {
    if (userList.length == 2) {
      return Stack(
        children: [largetVideoView(userList.last), smallVideoView(userList.first)],
      );
    } else {
      return Container();
    }
  }

  Widget groupCallView(List<CallUserInfo> userList) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: getGroupCallChildViews(userList, constraints));
    });
  }

  List<Positioned> getGroupCallChildViews(List<CallUserInfo> userList, BoxConstraints constraints) {
    final containerViewWidth = constraints.maxWidth;
    final containerViewHeight = constraints.maxWidth * (16 / 18);
    final views = <Positioned>[];
    if (userList.length == 3) {
      for (var i = 0; i < 3; i++) {
        final callUser = userList[i];
        double left = i == 0 ? 0 : containerViewWidth / 2;
        double top = i == 2 ? containerViewHeight / 2 : 0;
        final positionedView = Positioned(
            top: top,
            left: left,
            width: containerViewWidth / 2,
            height: i == 0 ? containerViewHeight : containerViewHeight / 2,
            child: GroupCallView(callUserInfo: callUser));
        views.add(positionedView);
      }
    } else if (userList.length == 4) {
      int row = 2;
      int column = 2;
      double cellWidth = containerViewWidth / column;
      double cellHeight = containerViewHeight / row;
      double left = 0;
      double top = 0;
      for (var i = 0; i < 4; i++) {
        left = cellWidth * (i % column);
        top = cellHeight * (i < column ? 0 : 1);
        final callUser = userList[i];
        final positionedView = Positioned(
            top: top, left: left, width: cellWidth, height: cellHeight, child: GroupCallView(callUserInfo: callUser));
        views.add(positionedView);
      }
    } else if (userList.length == 5) {
      double lastLeft = 0;
      double height = containerViewHeight / 2;
      for (var i = 0; i < 5; i++) {
        if (i == 2) {
          lastLeft = 0;
        }
        double width = i < 2 ? containerViewWidth / 2 : containerViewWidth / 3;
        double left = lastLeft + (width * (i < 2 ? i : (i - 2)));
        double top = i > 1 ? height : 0;
        final callUser = userList[i];
        final positionedView = Positioned(
            top: top, left: left, width: width, height: height, child: GroupCallView(callUserInfo: callUser));
        views.add(positionedView);
      }
    } else if (userList.length > 5) {
      int row = (userList.length % 3 == 0 ? (userList.length / 3) : (userList.length / 3) + 1).toInt();
      int column = 3;
      double cellWidth = containerViewWidth / column;
      double cellHeight = containerViewHeight / row;
      double left = 0;
      double top = 0;
      for (var i = 0; i < userList.length; i++) {
        left = cellWidth * (i % column);
        top = cellHeight * (i ~/ column);
        final callUser = userList[i];
        final positionedView = Positioned(
            top: top, left: left, width: cellWidth, height: cellHeight, child: GroupCallView(callUserInfo: callUser));
        views.add(positionedView);
      }
    }
    return views;
  }

  Widget largetVideoView(CallUserInfo callUser) {
    return ValueListenableBuilder(
        valueListenable: callUser.sdkUserNoti,
        builder: (context, ZegoSDKUser? sdkUser, _) {
          if (sdkUser != null) {
            return Container(
              padding: EdgeInsets.zero,
              color: Colors.black,
              child: ZegoAudioVideoView(userInfo: sdkUser),
            );
          } else {
            return Container(
              padding: EdgeInsets.zero,
              color: Colors.black,
            );
          }
        });
  }

  Widget smallVideoView(CallUserInfo callUser) {
    return ValueListenableBuilder(
        valueListenable: callUser.sdkUserNoti,
        builder: (context, ZegoSDKUser? sdkUser, _) {
          return LayoutBuilder(builder: (context, constraints) {
            if (sdkUser != null) {
              return Container(
                margin: EdgeInsets.only(top: 100, left: constraints.maxWidth - 95.0 - 20),
                width: 95.0,
                height: 164.0,
                child: ZegoAudioVideoView(userInfo: sdkUser),
              );
            } else {
              return Container(
                margin: EdgeInsets.only(top: 100, left: constraints.maxWidth - 95.0 - 20),
                width: 95.0,
                height: 164.0,
                color: Colors.black,
              );
            }
          });
        });
  }

  void onCallUserQuit(CallUserQuitEvent event) {
    enableShowUserNoti.removeWhere((element) => element.userID == event.userID);
  }

  void onOutgoingCallTimeOut(OutgoingCallTimeoutEvent event) {
    enableShowUserNoti.removeWhere((element) => element.userID == event.userID);
  }

  void onCallUserUpdate(OnCallUserUpdateEvent event) {
    debugPrint('onCallUserUpdate:$event');
    var isFindUser = false;
    for (final user in enableShowUserNoti.value) {
      if (user.userID == event.userID) {
        isFindUser = true;
        if (!user.isWaiting.value && !user.hasAccepted.value) {
          enableShowUserNoti.remove(user);
          break;
        }
      }
    }
    if (!isFindUser) {
      for (final user in ZegoCallManager().currentCallData!.callUserList) {
        if (user.userID == event.userID) {
          enableShowUserNoti.add(user);
          break;
        }
      }
    }
  }
}
