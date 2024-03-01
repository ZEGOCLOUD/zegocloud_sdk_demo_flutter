import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/common/common_button.dart';
import '../../components/common/zego_apply_cohost_list_page.dart';
import '../../components/common/zego_audio_video_view.dart';
import '../../components/common/zego_member_button.dart';
import '../../components/live_streaming/zego_live_bottom_bar.dart';
import '../../components/pk/pk_button.dart';
import '../../components/pk/pk_container.dart';
import '../../internal/sdk/utils/login_notifier.dart';
import '../../internal/sdk/utils/logout_notifier.dart';
import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../utils/zegocloud_token.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_key_center.dart';
import '../../zego_sdk_manager.dart';

import 'live_command.dart';
import 'live_page_gift.dart';
import 'live_page_pk.dart';

class ZegoLivePage extends StatefulWidget {
  const ZegoLivePage({
    super.key,
    required this.roomID,
    required this.role,
    this.externalControlCommand,
    this.previewHostID,
  });

  final String roomID;
  final ZegoLiveStreamingRole role;

  /// Use the command-driven interface.
  /// If external control is required, pass in an external command.
  final ZegoLivePageCommand? externalControlCommand;

  /// Cross-room users, only for preview
  final String? previewHostID;

  @override
  State<ZegoLivePage> createState() => ZegoLivePageState();
}

class ZegoLivePageState extends State<ZegoLivePage> {
  List<StreamSubscription> subscriptions = [];

  ValueNotifier<bool> applying = ValueNotifier(false);
  ZegoLivePageCommand? defaultCommand;

  bool showingDialog = false;
  bool showingPKDialog = false;

  /// room login notifiers, sliding up and down will cause changes in the state of the room
  var roomLoginNotifier = ZegoRoomLoginNotifier();

  /// room logout notifiers, sliding up and down will cause changes in the state of the room
  var roomLogoutNotifier = ZegoRoomLogoutNotifier();

  /// room ready notifiers, sliding up and down will cause changes in the state of the room
  var roomReadyNotifier = ValueNotifier<bool>(false);

  /// notifier of preview user
  var previewUserInfoNotifier = ValueNotifier<ZegoSDKUser?>(null);

  double get kButtonSize => 30;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  @override
  void initState() {
    super.initState();

    ZegoLiveStreamingManager().currentUserRoleNotifier.value = widget.role;

    registerCommandEvent();

    /// Monitor cross-room user updates
    expressService.remoteStreamUserInfoListNotifier.addListener(onRemoteStreamUserUpdated);

    registerLoginEvents();

    if (!hasExternalCommand) {
      command
        ..registerEvent()
        ..join();
    }

    initGift();
  }

  @override
  void dispose() {
    super.dispose();

    expressService.remoteStreamUserInfoListNotifier.removeListener(onRemoteStreamUserUpdated);
    unregisterLoginEvents();

    uninitGift();

    if (!hasExternalCommand) {
      command
        ..unregisterEvent()
        ..leave();
    }

    unregisterCommandEvent();
  }

  @override
  Widget build(Object context) {
    return ZegoLiveStreamingRole.host == widget.role
        ? liveRoomWidget()
        : ValueListenableBuilder<bool>(
            valueListenable: roomReadyNotifier,
            builder: (context, isRoomReady, _) {
              return isRoomReady ? liveRoomWidget() : previewRoomWidget();
            },
          );
  }

  Widget liveRoomWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: ZegoLiveStreamingManager().isLivingNotifier,
      builder: (context, isLiving, _) {
        return ValueListenableBuilder<RoomPKState>(
          valueListenable: ZegoLiveStreamingManager().pkStateNotifier,
          builder: (context, RoomPKState pkState, child) {
            return Scaffold(
              body: Stack(
                children: [
                  backgroundImage(),
                  hostVideoView(isLiving, pkState),
                  Positioned(right: 20, top: 100, child: coHostVideoView(isLiving, pkState)),
                  Positioned(bottom: 60, left: 0, right: 0, child: startLiveButton(isLiving, pkState)),
                  Positioned(top: 50, left: 20, child: hostText()),
                  Positioned(top: 60, right: 30, child: leaveButton()),
                  Positioned(bottom: 120, left: 30, child: cohostRequestListButton(isLiving, pkState)),
                  Positioned(bottom: 80, left: 30, child: pkButton(isLiving, pkState)),
                  Positioned(left: 0, right: 0, bottom: 20, child: bottomBar(isLiving, pkState)),
                  giftForeground()
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget previewRoomWidget() {
    if (null == widget.previewHostID) {
      return Container();
    }

    final previewUser = expressService.getRemoteUser(widget.previewHostID!);
    if (null != previewUser) {
      /// remote user's stream is playing
      return ZegoAudioVideoView(userInfo: previewUser);
    }

    /// remote user's stream not play now, waiting
    return ValueListenableBuilder<ZegoSDKUser?>(
      valueListenable: previewUserInfoNotifier,
      builder: (context, previewUserInfo, _) {
        return null == previewUserInfo

            /// waiting
            ? Stack(
                children: [
                  backgroundImage(),
                  Center(
                    child: Text(
                      'Loading ${widget.previewHostID}',
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              )

            /// remote user's stream is playing
            : ZegoAudioVideoView(userInfo: previewUserInfo);
      },
    );
  }

  Widget bottomBar(bool isLiving, RoomPKState pkState) {
    if (!isLiving) return const SizedBox.shrink();

    if (pkState != RoomPKState.isStartPK || ZegoLiveStreamingManager().iamHost()) {
      return ZegoLiveBottomBar(applying: applying);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget backgroundImage() {
    return Image.asset('assets/images/live_bg.png', width: double.infinity, height: double.infinity, fit: BoxFit.fill);
  }

  Widget hostVideoView(bool isLiving, RoomPKState pkState) {
    return ValueListenableBuilder(
      valueListenable: ZegoLiveStreamingManager().onPKViewAvailableNotifier,
      builder: (context, bool showPKView, _) {
        if (pkState == RoomPKState.isStartPK) {
          if (showPKView || ZegoLiveStreamingManager().iamHost()) {
            return LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                      top: 100,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth * 16 / 18,
                        child: const ZegoPKContainerView(),
                      )),
                ],
              );
            });
          } else {
            if (ZegoLiveStreamingManager().hostNotifier.value == null) {
              return const SizedBox.shrink();
            }

            return ZegoAudioVideoView(userInfo: ZegoLiveStreamingManager().hostNotifier.value!);
          }
        } else {
          if (ZegoLiveStreamingManager().hostNotifier.value == null) {
            return const SizedBox.shrink();
          }

          return ZegoAudioVideoView(userInfo: ZegoLiveStreamingManager().hostNotifier.value!);
        }
      },
    );
  }

  ZegoSDKUser? getHostUser() {
    if (widget.role == ZegoLiveStreamingRole.host) {
      return ZEGOSDKManager().currentUser;
    } else {
      for (final userInfo in expressService.userInfoList) {
        if (userInfo.streamID != null) {
          if (userInfo.streamID!.endsWith('_host')) {
            return userInfo;
          }
        }
      }
    }

    return null;
  }

  Widget coHostVideoView(bool isLiving, RoomPKState pkState) {
    if (pkState != RoomPKState.isStartPK) {
      return Builder(builder: (context) {
        final height = (MediaQuery.of(context).size.height - kButtonSize - 100) / 4;
        final width = height * (9 / 16);

        return ValueListenableBuilder<List<ZegoSDKUser>>(
          valueListenable: ZegoLiveStreamingManager().coHostUserListNotifier,
          builder: (context, cohostList, _) {
            final videoList = ZegoLiveStreamingManager().coHostUserListNotifier.value.map((user) {
              return ZegoAudioVideoView(userInfo: user);
            }).toList();

            return SizedBox(
              width: width,
              height: MediaQuery.of(context).size.height - kButtonSize - 150,
              child: ListView.separated(
                reverse: true,
                itemCount: videoList.length,
                itemBuilder: (context, index) {
                  return SizedBox(width: width, height: height, child: videoList[index]);
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
              ),
            );
          },
        );
      });
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget startLiveButton(bool isLiving, RoomPKState pkState) {
    if (!isLiving && widget.role == ZegoLiveStreamingRole.host) {
      return CommonButton(width: 100, height: 40, onTap: startLive, child: const Text('Start Live'));
    } else {
      return const SizedBox.shrink();
    }
  }

  void startLive() {
    ZegoLiveStreamingManager().startLive(widget.roomID).then((value) {
      if (value.errorCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
      } else {
        expressService.startPublishingStream(ZegoLiveStreamingManager().hostStreamID());
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: $error}')));
    });
  }

  Widget leaveButton() {
    return CommonButton(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(6),
      onTap: () => Navigator.pop(context),
      child: Image.asset('assets/icons/nav_close.png'),
    );
  }

  Widget cohostRequestListButton(bool isLiving, RoomPKState pkState) {
    if (isLiving && (widget.role == ZegoLiveStreamingRole.host) && (pkState != RoomPKState.isStartPK)) {
      return const CoHostRequestListButton();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget hostText() {
    return ValueListenableBuilder<ZegoSDKUser?>(
      valueListenable: ZegoLiveStreamingManager().hostNotifier,
      builder: (context, userInfo, _) {
        return Text(
          'RoomID: ${widget.roomID}\n'
          'HostID: ${userInfo?.userID ?? ''}',
          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 104, 94, 94)),
        );
      },
    );
  }

  Widget pkButton(bool isLiving, RoomPKState pkState) {
    if (isLiving && widget.role == ZegoLiveStreamingRole.host) {
      return const PKButton();
    } else {
      return const SizedBox.shrink();
    }
  }

  void onRemoteStreamUserUpdated() {
    final previewUser = expressService.getRemoteUser(widget.previewHostID!);
    if (null == previewUser) {
      return;
    }

    /// remote user's stream start playing
    previewUserInfoNotifier.value = previewUser;
  }

  void onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    debugPrint('LivePage:onExpressRoomStateChanged: $event');

    if (event.roomID != widget.roomID) {
      return;
    }

    if (event.errorCode != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('onExpressRoomStateChanged: reason:${event.reason.name}, errorCode:${event.errorCode}'),
        ),
      );
    }

    if ((event.reason == ZegoRoomStateChangedReason.KickOut) ||
        (event.reason == ZegoRoomStateChangedReason.ReconnectFailed) ||
        (event.reason == ZegoRoomStateChangedReason.LoginFailed)) {
      Navigator.pop(context);
    }
  }

  void onZIMRoomStateChanged(ZIMServiceRoomStateChangedEvent event) {
    debugPrint('LivePage:onZIMRoomStateChanged: $event');

    if (event.roomID != widget.roomID) {
      return;
    }

    if ((event.event != ZIMRoomEvent.success) && (event.state != ZIMRoomState.connected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('onZIMRoomStateChanged: $event'),
        ),
      );
    }
    if (event.state == ZIMRoomState.disconnected) {
      Navigator.pop(context);
    }
  }

  void onZIMConnectionStateChanged(ZIMServiceConnectionStateChangedEvent event) {
    debugPrint('LivePage:onZIMConnectionStateChanged: $event');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1000),
        content: Text('onZIMConnectionStateChanged: $event'),
      ),
    );
    if (event.state == ZIMConnectionState.disconnected) {
      Navigator.pop(context);
    }
  }

  void onInComingRoomRequest(OnInComingRoomRequestReceivedEvent event) {}

  void onInComingRoomRequestCancel(OnInComingRoomRequestCancelledEvent event) {}

  void onOutgoingRoomRequestAccepted(OnOutgoingRoomRequestAcceptedEvent event) {
    applying.value = false;
    ZegoLiveStreamingManager().startCoHost();
  }

  void onOutgoingRoomRequestRejected(OnOutgoingRoomRequestRejectedEvent event) {
    applying.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 1000),
        content: Text('Your request to co-host with the host has been refused.'),
      ),
    );
  }

  void showApplyCohostDialog() {
    RoomRequestListView.showBasicModalBottomSheet(context);
  }

  void refuseApplyCohost(RoomRequest roomRequest) {
    zimService.rejectRoomRequest(roomRequest.requestID ?? '').then((value) {}).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Disagree cohost failed: $error')));
    });
  }
}

extension ZegoLivePageStateLoginState on ZegoLivePageState {
  void registerLoginEvents() {
    roomLoginNotifier.notifier.addListener(onRoomLoginStateChanged);
    roomLogoutNotifier.notifier.addListener(onRoomLogoutStateChanged);
    roomLoginNotifier.resetCheckingData(widget.roomID);
    roomLogoutNotifier.resetCheckingData(widget.roomID);
  }

  void unregisterLoginEvents() {
    roomLoginNotifier.notifier.removeListener(onRoomLoginStateChanged);
    roomLogoutNotifier.notifier.removeListener(onRoomLogoutStateChanged);
  }

  void onRoomLoginStateChanged() {
    if (roomLoginNotifier.notifier.value) {
      roomLogoutNotifier.resetCheckingData(widget.roomID);
      roomReadyNotifier.value = true;
    }
  }

  void onRoomLogoutStateChanged() {
    if (roomLogoutNotifier.notifier.value) {
      roomLoginNotifier.resetCheckingData(widget.roomID);
      roomReadyNotifier.value = false;
    }
  }
}

extension ZegoLivePageStateCommand on ZegoLivePageState {
  /// Whether to enable external command control, if not, then it is internal control
  bool get hasExternalCommand => null != widget.externalControlCommand;

  /// current command
  ZegoLivePageCommand get command => widget.externalControlCommand ?? lazyCreateDefaultCommand();

  /// default internal command
  ZegoLivePageCommand lazyCreateDefaultCommand() {
    defaultCommand ??= ZegoLivePageCommand(roomID: widget.roomID);

    return defaultCommand!;
  }

  void registerCommandEvent() {
    command.joinRoomCommand.addListener(onJoinRoomCommand);
    command.leaveRoomCommand.addListener(onLeaveRoomCommand);
    command.registerEventCommand.addListener(onRegisterEventCommand);
    command.unregisterEventCommand.addListener(onUnregisterEventCommand);
  }

  void unregisterCommandEvent() {
    command.joinRoomCommand.removeListener(onJoinRoomCommand);
    command.leaveRoomCommand.removeListener(onLeaveRoomCommand);
    command.registerEventCommand.removeListener(onRegisterEventCommand);
    command.unregisterEventCommand.removeListener(onUnregisterEventCommand);
  }

  void onRegisterEventCommand() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }

    subscriptions.addAll([
      expressService.roomStateChangedStreamCtrl.stream.listen(onExpressRoomStateChanged),
      zimService.roomStateChangedStreamCtrl.stream.listen(onZIMRoomStateChanged),
      zimService.connectionStateStreamCtrl.stream.listen(onZIMConnectionStateChanged),
      zimService.onInComingRoomRequestStreamCtrl.stream.listen(onInComingRoomRequest),
      zimService.onInComingRoomRequestCancelledStreamCtrl.stream.listen(onInComingRoomRequestCancel),
      zimService.onOutgoingRoomRequestAcceptedStreamCtrl.stream.listen(onOutgoingRoomRequestAccepted),
      zimService.onOutgoingRoomRequestRejectedStreamCtrl.stream.listen(onOutgoingRoomRequestRejected),
    ]);
    listenPKEvents();
  }

  void onUnregisterEventCommand() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  void onJoinRoomCommand() {
    if (widget.role == ZegoLiveStreamingRole.audience) {
      /// Join room now
      String? token;
      if (kIsWeb) {
        // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
        // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
        token = ZegoTokenUtils.generateToken(
          SDKKeyCenter.appID,
          SDKKeyCenter.serverSecret,
          ZEGOSDKManager().currentUser!.userID,
        );
      }

      ZEGOSDKManager().loginRoom(widget.roomID, ZegoScenario.Broadcast, token: token).then(
        (value) {
          if (value.errorCode != 0) {
            debugPrint('login room failed: ${value.errorCode}');
          }
        },
      );
    } else if (widget.role == ZegoLiveStreamingRole.host) {
      /// will join room on startLive

      /// cache host
      ZegoLiveStreamingManager().hostNotifier.value = ZEGOSDKManager().currentUser;

      /// start preview
      ZEGOSDKManager().expressService.turnCameraOn(true);
      ZEGOSDKManager().expressService.turnMicrophoneOn(true);
      ZEGOSDKManager().expressService.startPreview();
    }
  }

  void onLeaveRoomCommand() {
    ZEGOSDKManager().expressService.stopPreview();

    ZegoLiveStreamingManager().leaveRoom();
  }
}
