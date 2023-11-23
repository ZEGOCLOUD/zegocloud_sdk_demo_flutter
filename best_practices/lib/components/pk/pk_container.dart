import 'dart:async';

import 'package:flutter/material.dart';
import '../../internal/business/pk/pk_user.dart';
import '../../internal/sdk/utils/flutter_extension.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';

class ZegoPKContainerView extends StatefulWidget {
  const ZegoPKContainerView({super.key});

  @override
  State<ZegoPKContainerView> createState() => _ZegoPKContainerViewState();
}

class _ZegoPKContainerViewState extends State<ZegoPKContainerView> {
  List<StreamSubscription> subscriptions = [];

  final liveManager = ZegoLiveStreamingManager();
  ListNotifier<PKUser> pkUserListNoti = ListNotifier([]);

  @override
  void initState() {
    super.initState();
    subscriptions.addAll([
      ZegoLiveStreamingManager().onPKUserJoinCtrl.stream.listen(onPKUserJoin),
      ZegoLiveStreamingManager().onPKBattleUserQuitCtrl.stream.listen(onPKUserQuit),
      ZegoLiveStreamingManager().onPKBattleUserUpdateCtrl.stream.listen(onPKUserUpdate)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoLiveRole>(
        valueListenable: liveManager.currentUserRoleNoti,
        builder: (context, role, _) {
          if (role == ZegoLiveRole.host) {
            //is host
            return Container();
          } else {
            // is not host
            return Container();
          }
        });
  }

  Widget audiencePKView() {
    return Container();
  }

  Widget hostPKView() {
    return ValueListenableBuilder<List<PKUser>>(
        valueListenable: pkUserListNoti,
        builder: (context, pkUsers, _) {
          return Stack(
            children: hostPKViews(pkUsers),
          );
        });
  }

  List<Widget> hostPKViews(List<PKUser> pkUsers) {
    final views = <Widget>[];
    for (final pkuser in pkUsers) {
      final positioned = Positioned(
          left: pkuser.rect.left,
          right: pkuser.rect.right,
          top: pkuser.rect.top,
          bottom: pkuser.rect.bottom,
          child: Container());
      views.add(positioned);
    }
    return views;
  }

  void onPKUserJoin(PKBattleUserJoinEvent event) {
    _onRoomPKUserJoin();
  }

  void onPKUserUpdate(PKBattleUserUpdateEvent event) {
    _onRoomPKUserJoin();
  }

  void onPKUserQuit(PKBattleUserQuitEvent event) {}

  void _onRoomPKUserJoin() {}
}
