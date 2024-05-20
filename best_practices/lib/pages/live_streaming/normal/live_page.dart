import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../components/components.dart';
import '../../../utils/zegocloud_token.dart';
import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_key_center.dart';
import 'live_command.dart';

part 'live_page_buttons.dart';
part 'live_page_gift.dart';
part 'live_page_pk.dart';

class ZegoNormalLivePage extends StatefulWidget {
  const ZegoNormalLivePage({
    super.key,
    required this.liveStreamingManager,
    required this.roomID,
    required this.role,
    this.externalControlCommand,
    this.previewHostID,
  });

  final ZegoLiveStreamingManager liveStreamingManager;

  final String roomID;
  final ZegoLiveStreamingRole role;

  /// Use the command-driven APIs.
  /// If external control is required, pass in an external command.
  final ZegoLivePageCommand? externalControlCommand;

  /// Cross-room users, only for preview
  final String? previewHostID;

  @override
  State<ZegoNormalLivePage> createState() => ZegoNormalLivePageState();
}

class ZegoNormalLivePageState extends State<ZegoNormalLivePage> {
  List<StreamSubscription> subscriptions = [];

  ValueNotifier<bool> applying = ValueNotifier(false);
  ZegoLivePageCommand? defaultCommand;

  bool showingDialog = false;
  bool showingPKDialog = false;

  var swipingData = ZegoLivePageSwipingData();

  double get kButtonSize => 30;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  @override
  void initState() {
    super.initState();

    widget.liveStreamingManager.currentUserRoleNotifier.value = widget.role;

    registerCommandEvent();

    addPreviewUserUpdateListeners();
    addRoomLoginListeners();

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

    removePreviewUserUpdateListeners();
    removeRoomLoginListeners();

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
    return ValueListenableBuilder<bool>(
      valueListenable: widget.liveStreamingManager.isLivingNotifier,
      builder: (context, isLiving, _) {
        return ValueListenableBuilder<RoomPKState>(
          valueListenable: widget.liveStreamingManager.pkStateNotifier,
          builder: (context, RoomPKState pkState, child) {
            return Scaffold(
              body: Stack(
                children: [
                  backgroundImage(),
                  hostVideoView(isLiving, pkState),
                  Positioned(top: 50, left: 20, child: hostText()),
                  Positioned(
                    right: 20,
                    top: 100,
                    child: coHostVideoView(isLiving, pkState),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 30,
                    child: cohostRequestListButton(isLiving, pkState),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 30,
                    child: pkButton(isLiving, pkState),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: bottomBar(isLiving, pkState),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: startLiveButton(isLiving, pkState),
                  ),
                  Positioned(
                    top: 60,
                    right: 30,
                    child: leaveButton(),
                  ),
                  giftForeground(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget bottomBar(bool isLiving, RoomPKState pkState) {
    if (!isLiving) return const SizedBox.shrink();

    if (pkState != RoomPKState.isStartPK || widget.liveStreamingManager.iamHost()) {
      return ZegoLiveBottomBar(
        applying: applying,
        liveStreamingManager: widget.liveStreamingManager,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/images/live_bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  Widget hostVideoView(bool isLiving, RoomPKState pkState) {
    return ValueListenableBuilder(
      valueListenable: widget.liveStreamingManager.onPKViewAvailableNotifier,
      builder: (context, bool showPKView, _) {
        if (pkState == RoomPKState.isStartPK) {
          return ValueListenableBuilder<List<PKUser>>(
              valueListenable: widget.liveStreamingManager.pkInfo!.pkUserList,
              builder: (context, pkUsers, _) {
                /// in sliding, if it is not the current display room, the PK view is not displayed
                var isCurrentRoomHostTakingPK = false;
                if (pkUsers.isNotEmpty) {
                  final mainHost = pkUsers.first;
                  isCurrentRoomHostTakingPK = mainHost.userID == widget.liveStreamingManager.hostNotifier.value?.userID && mainHost.roomID == widget.roomID;
                }
                if (isCurrentRoomHostTakingPK) {
                  if (showPKView || widget.liveStreamingManager.iamHost()) {
                    return hostVideoViewInPK();
                  } else {
                    return hostVideoViewFromManagerNotifier();
                  }
                } else {
                  return ZegoLiveStreamingRole.host == widget.role ? hostVideoViewFromManagerNotifier() : hostVideoViewFromSwipingNotifier();
                }
              });
        } else {
          return ZegoLiveStreamingRole.host == widget.role ? hostVideoViewFromManagerNotifier() : hostVideoViewFromSwipingNotifier();
        }
      },
    );
  }

  Widget hostVideoViewInPK() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            top: 100,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxWidth * 16 / 18,
              child: ZegoPKContainerView(
                liveStreamingManager: widget.liveStreamingManager,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget hostVideoViewFromManagerNotifier() {
    return ValueListenableBuilder(
      valueListenable: widget.liveStreamingManager.hostNotifier,
      builder: (context, host, _) {
        if (widget.liveStreamingManager.hostNotifier.value == null) {
          return const SizedBox.shrink();
        }

        return ZegoAudioVideoView(
          userInfo: widget.liveStreamingManager.hostNotifier.value!,
        );
      },
    );
  }

  Widget hostVideoViewFromSwipingNotifier() {
    /// Core rendering logic for scrolling up and down preview
    return ValueListenableBuilder<ZegoSDKUser?>(
      valueListenable: swipingData.hostNotifier,
      builder: (context, host, _) {
        final r = widget.roomID;
        return null == host ? const SizedBox.shrink() : ZegoAudioVideoView(userInfo: host);
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
          valueListenable: widget.liveStreamingManager.coHostUserListNotifier,
          builder: (context, cohostList, _) {
            final videoList = widget.liveStreamingManager.coHostUserListNotifier.value.map((user) {
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
    widget.liveStreamingManager.startLive(widget.roomID).then((value) {
      if (value.errorCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
      } else {
        expressService.startPublishingStream(widget.liveStreamingManager.hostStreamID());
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
      valueListenable: swipingData.hostNotifier,
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
      return PKButton(
        liveStreamingManager: widget.liveStreamingManager,
      );
    } else {
      return const SizedBox.shrink();
    }
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
      if (mounted) Navigator.pop(context);
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
    widget.liveStreamingManager.startCoHost();
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

extension ZegoLivePageStateCommand on ZegoNormalLivePageState {
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
    debugPrint('xxxx onRegisterEventCommand');
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
    debugPrint('xxxx onUnregisterEventCommand');

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
      widget.liveStreamingManager.hostNotifier.value = ZEGOSDKManager().currentUser;
      swipingData.hostNotifier.value = ZEGOSDKManager().currentUser;

      /// start preview
      ZEGOSDKManager().expressService.turnCameraOn(true);
      ZEGOSDKManager().expressService.turnMicrophoneOn(true);
      ZEGOSDKManager().expressService.startPreview();
    }
  }

  void onLeaveRoomCommand() {
    ZEGOSDKManager().expressService.stopPreview();

    widget.liveStreamingManager.leaveRoom();
  }
}

class ZegoLivePageSwipingData {
  /// room login notifiers, sliding up and down will cause changes in the state of the room
  var roomLoginNotifier = ZegoRoomLoginNotifier();

  /// room logout notifiers, sliding up and down will cause changes in the state of the room
  var roomLogoutNotifier = ZegoRoomLogoutNotifier();

  /// room ready notifiers, sliding up and down will cause changes in the state of the room
  var roomReadyNotifier = ValueNotifier<bool>(false);

  /// preview host or real host
  var hostNotifier = ValueNotifier<ZegoSDKUser?>(null);
}

extension ZegoLivePageStateSwiping on ZegoNormalLivePageState {
  void addRoomLoginListeners() {
    swipingData.roomLoginNotifier.notifier.addListener(onRoomLoginStateChanged);
    swipingData.roomLogoutNotifier.notifier.addListener(onRoomLogoutStateChanged);
    swipingData.roomLoginNotifier.resetCheckingData(widget.roomID);
    swipingData.roomLogoutNotifier.resetCheckingData(widget.roomID);
  }

  void removeRoomLoginListeners() {
    swipingData.roomLoginNotifier.notifier.removeListener(onRoomLoginStateChanged);
    swipingData.roomLogoutNotifier.notifier.removeListener(onRoomLogoutStateChanged);
  }

  void onRoomLoginStateChanged() {
    if (swipingData.roomLoginNotifier.notifier.value) {
      swipingData.roomLogoutNotifier.resetCheckingData(widget.roomID);
      swipingData.roomReadyNotifier.value = true;
    }
  }

  void onRoomLogoutStateChanged() {
    if (swipingData.roomLogoutNotifier.notifier.value) {
      swipingData.roomLoginNotifier.resetCheckingData(widget.roomID);
      swipingData.roomReadyNotifier.value = false;
    }
  }

  void addPreviewUserUpdateListeners() {
    if (ZegoLiveStreamingRole.host == widget.role) {
      return;
    }

    /// Monitor cross-room user updates
    if (widget.previewHostID != null) {
      final previewUser = expressService.getRemoteUser(widget.previewHostID!);
      if (null != previewUser) {
        /// remote user's stream is playing
        swipingData.hostNotifier.value = previewUser;
      }
    }

    ///  in sliding, the room/host will switch, so need to listen for
    ///  changes in the flow
    onRemoteStreamUserUpdated();
    expressService.remoteStreamUserInfoListNotifier.addListener(onRemoteStreamUserUpdated);
    onHostUpdated();
    widget.liveStreamingManager.hostNotifier.addListener(onHostUpdated);
  }

  void removePreviewUserUpdateListeners() {
    expressService.remoteStreamUserInfoListNotifier.removeListener(onRemoteStreamUserUpdated);
  }

  void onRemoteStreamUserUpdated() {
    if (!mounted) return;

    if (widget.previewHostID != null) {
      final previewUser = expressService.getRemoteUser(widget.previewHostID!);
      if (null != previewUser) {
        /// remote user's stream start playing
        swipingData.hostNotifier.value = previewUser;
      }
    }
  }

  void onHostUpdated() {
    if (expressService.currentRoomID == widget.roomID) {
      /// Sliding the LIVE room will trigger it, which only takes effect for updates caused by the current room
      if (null != widget.liveStreamingManager.hostNotifier.value) {
        /// To prevent the preview from flashing when sliding the LIVE room, the host caused by checking out is null
        swipingData.hostNotifier.value = widget.liveStreamingManager.hostNotifier.value;
      }
    }
  }
}
