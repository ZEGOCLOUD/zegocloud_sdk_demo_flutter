import 'dart:async';

import 'package:flutter/material.dart';

import '../../zego_live_streaming_manager.dart';
import 'pk_mixer_view.dart';
import 'pk_view.dart';

class ZegoPKContainerView extends StatefulWidget {
  const ZegoPKContainerView({
    super.key,
    required this.liveStreamingManager,
  });

  final ZegoLiveStreamingManager liveStreamingManager;

  @override
  State<ZegoPKContainerView> createState() => _ZegoPKContainerViewState();
}

class _ZegoPKContainerViewState extends State<ZegoPKContainerView> {
  List<StreamSubscription> subscriptions = [];

  ListNotifier<PKUser> pkUserListNotifier = ListNotifier([]);

  @override
  void initState() {
    super.initState();
    subscriptions.addAll([
      widget.liveStreamingManager.onPKUserJoinCtrl.stream.listen(onPKUserJoin),
      widget.liveStreamingManager.onPKBattleUserQuitCtrl.stream.listen(onPKUserQuit),
      widget.liveStreamingManager.onPKBattleUserUpdateCtrl.stream.listen(onPKUserUpdate),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    for (final element in subscriptions) {
      element.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoLiveStreamingRole>(
        valueListenable: widget.liveStreamingManager.currentUserRoleNotifier,
        builder: (context, role, _) {
          if (role == ZegoLiveStreamingRole.host) {
            //is host
            return hostPKView();
          } else {
            // is not host
            return audiencePKView();
          }
        });
  }

  Widget audiencePKView() {
    return ValueListenableBuilder<List<PKUser>>(
        valueListenable: widget.liveStreamingManager.pkInfo!.pkUserList,
        builder: (context, pkusers, _) {
          final pkAcceptUser = pkusers.where((element) => element.hasAccepted).toList();
          return PKMixerView(
            pkAcceptUsers: pkAcceptUser,
            mixStreamID: '${ZEGOSDKManager().expressService.currentRoomID}_mix',
          );
        });
  }

  Widget hostPKView() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return ValueListenableBuilder<List<PKUser>>(
          valueListenable: widget.liveStreamingManager.pkInfo!.pkUserList,
          builder: (context, pkUsers, _) {
            return Container(
              color: Colors.black,
              child: Stack(
                children: hostPKViews(pkUsers, constraints),
              ),
            );
          });
    });
  }

  List<Positioned> hostPKViews(List<PKUser> pkUsers, BoxConstraints constraints) {
    final views = <Positioned>[];
    for (final pkUser in pkUsers.where((element) => element.hasAccepted).toList()) {
      final newRect = conversionRect(pkUser.rect, constraints);
      final positioned = Positioned(
          left: newRect.left,
          top: newRect.top,
          width: newRect.right - newRect.left,
          height: newRect.bottom - newRect.top,
          child: Container(
            width: newRect.right - newRect.left,
            height: newRect.bottom - newRect.top,
            color: pkUser.userID == ZEGOSDKManager().currentUser!.userID ? Colors.yellow : Colors.blue,
            child: PKView(
              pkUser: pkUser,
              liveStreamingManager: widget.liveStreamingManager,
            ),
          ));
      views.add(positioned);
    }
    return views;
  }

  Rect conversionRect(Rect originalRect, BoxConstraints constraints) {
    final wRatio = constraints.maxWidth / 810.0;
    final hRatio = constraints.maxHeight / 720.0;
    return Rect.fromLTRB(originalRect.left * wRatio, originalRect.top * hRatio, originalRect.right * wRatio, originalRect.bottom * hRatio);
  }

  void onPKUserJoin(PKBattleUserJoinEvent event) {
    onRoomPKUserJoin();
  }

  void onPKUserUpdate(PKBattleUserUpdateEvent event) {
    onRoomPKUserJoin();
  }

  void onPKUserQuit(PKBattleUserQuitEvent event) {
    onRoomPKUserJoin();
  }

  void onRoomPKUserJoin() {
    if (widget.liveStreamingManager.pkInfo != null) {
      setState(() {});
    }
  }
}
