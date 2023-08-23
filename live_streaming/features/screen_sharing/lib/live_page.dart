import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'utils/device_orientation.dart';
import 'utils/zegocloud_token.dart';

import 'key_center.dart';

class LivePage extends StatefulWidget {
  const LivePage({
    Key? key,
    required this.isHost,
    required this.localUserID,
    required this.localUserName,
    required this.roomID,
  }) : super(key: key);

  final bool isHost;
  final String localUserID;
  final String localUserName;
  final String roomID;

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  Widget? hostCameraView;
  int? hostCameraViewID;

  Widget? hostScreenView;
  int? hostScreenViewID;

  bool isCameraEnabled = true;
  bool isSharingScreen = false;
  ZegoScreenCaptureSource? screenSharingSource;

  bool isLandscape = false;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    startListenEvent();
    loginRoom();

    subscriptions.addAll([
      NativeDeviceOrientationCommunicator().onOrientationChanged().listen((NativeDeviceOrientation orientation) {
        updateAppOrientation(orientation);
      }),
    ]);

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subscriptions) {
      sub.cancel();
    }
    stopListenEvent();
    logoutRoom();
    resetAppOrientation();
    super.dispose();
  }

  Widget get screenView => isSharingScreen ? (hostScreenView ?? const SizedBox()) : const SizedBox();
  Widget get cameraView => isCameraEnabled ? (hostCameraView ?? const SizedBox()) : const SizedBox();

  void updateAppOrientation(NativeDeviceOrientation orientation) async {
    if (isLandscape != orientation.isLandscape) {
      isLandscape = orientation.isLandscape;
      debugPrint('updateAppOrientation: ${orientation.name}');
      final videoConfig = await ZegoExpressEngine.instance.getVideoConfig();
      if (isLandscape && (videoConfig.captureWidth > videoConfig.captureHeight)) return;

      final oldValues = {
        'captureWidth': videoConfig.captureWidth,
        'captureHeight': videoConfig.captureHeight,
        'encodeWidth': videoConfig.encodeWidth,
        'encodeHeight': videoConfig.encodeHeight,
      };
      videoConfig
        ..captureHeight = oldValues['captureWidth']!
        ..captureWidth = oldValues['captureHeight']!
        ..encodeHeight = oldValues['encodeWidth']!
        ..encodeWidth = oldValues['encodeHeight']!;
      ZegoExpressEngine.instance.setAppOrientation(orientation.toZegoType);
      ZegoExpressEngine.instance.setVideoConfig(videoConfig);
    }
  }

  void resetAppOrientation() => updateAppOrientation(NativeDeviceOrientation.portraitUp);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live page")),
      body: Stack(
        children: [
          Container(color: Colors.black),
          Builder(builder: (context) {
            if (!isSharingScreen) return cameraView;
            if (!widget.isHost) return screenView;
            return const Center(child: Text('You are sharing your screen', style: TextStyle(color: Colors.white)));
          }),
          Positioned(
            bottom: MediaQuery.of(context).orientation == Orientation.portrait ? 140 : 100,
            right: 20,
            child: SizedBox(
              width: MediaQuery.of(context).orientation == Orientation.portrait ? 100 : 200,
              child: AspectRatio(
                aspectRatio: MediaQuery.of(context).orientation == Orientation.portrait ? 9.0 / 16.0 : 16.0 / 9.0,
                child: (isSharingScreen ? cameraView : screenView),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isHost) ...[
                  DemoButton(
                    text: isCameraEnabled ? 'Disable Camera' : 'Enable Camera',
                    onPressed: () {
                      setState(() {
                        isCameraEnabled = !isCameraEnabled;
                        ZegoExpressEngine.instance.setStreamExtraInfo(jsonEncode({'isCameraEnabled': isCameraEnabled}));
                        ZegoExpressEngine.instance.enableCamera(isCameraEnabled);
                      });
                    },
                  ),
                  DemoButton(
                    text: isSharingScreen ? 'Stop ScreenSharing' : 'Start ScreenSharing',
                    onPressed: () async {
                      if (isSharingScreen) {
                        await stopScreenSharing();
                      } else {
                        await startScreenSharing();
                      }
                    },
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<ZegoRoomLoginResult> loginRoom() async {
    // The value of `userID` is generated locally and must be globally unique.
    final user = ZegoUser(widget.localUserID, widget.localUserName);

    // The value of `roomID` is generated locally and must be globally unique.
    final roomID = widget.roomID;

    // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()..isUserStatusNotify = true;

    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      roomConfig.token = ZegoTokenUtils.generateToken(appID, serverSecret, widget.localUserID);
    }
    // log in to a room
    // Users must log in to the same room to call each other.
    return ZegoExpressEngine.instance
        .loginRoom(roomID, user, config: roomConfig)
        .then((ZegoRoomLoginResult loginRoomResult) async {
      debugPrint('loginRoom: errorCode:${loginRoomResult.errorCode}, extendedData:${loginRoomResult.extendedData}');
      if (loginRoomResult.errorCode == 0) {
        if (widget.isHost) {
          startPreview();
          startPublish();
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('loginRoom failed: ${loginRoomResult.errorCode}')));
      }
      return loginRoomResult;
    });
  }

  Future<ZegoRoomLogoutResult> logoutRoom() async {
    stopPreview();
    stopPublish();
    stopScreenSharing();
    if (screenSharingSource != null) ZegoExpressEngine.instance.destroyScreenCaptureSource(screenSharingSource!);
    return ZegoExpressEngine.instance.logoutRoom(widget.roomID);
  }

  void startListenEvent() {
    // Callback for updates on the status of other users in the room.
    // Users can only receive callbacks when the isUserStatusNotify property of ZegoRoomConfig is set to `true` when logging in to the room (loginRoom).
    ZegoExpressEngine.onRoomUserUpdate = (roomID, updateType, List<ZegoUser> userList) {
      debugPrint(
          'onRoomUserUpdate: roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => e.userID)}');
    };
    // Callback for updates on the status of the streams in the room.
    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, List<ZegoStream> streamList, extendedData) {
      debugPrint(
          'onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList: ${streamList.map((e) => e.streamID)}, extendedData: $extendedData');
      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          startPlayStream(stream.streamID);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID);
        }
      }
    };
    // Callback for updates on the current user's room connection status.
    ZegoExpressEngine.onRoomStateUpdate = (roomID, state, errorCode, extendedData) {
      debugPrint(
          'onRoomStateUpdate: roomID: $roomID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };

    // Callback for updates on the current user's stream publishing changes.
    ZegoExpressEngine.onPublisherStateUpdate = (streamID, state, errorCode, extendedData) {
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };
    ZegoExpressEngine.onPublisherStateUpdate = (streamID, state, errorCode, extendedData) {
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };

    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = (String roomID, List<ZegoStream> streamList) {
      for (ZegoStream stream in streamList) {
        try {
          Map<String, dynamic> extraInfoMap = jsonDecode(stream.extraInfo);
          if (extraInfoMap['isCameraEnabled'] is bool) {
            setState(() {
              isCameraEnabled = extraInfoMap['isCameraEnabled'];
            });
          }
        } catch (e) {
          debugPrint('streamExtraInfo is not json');
        }
      }
    };
    ZegoExpressEngine.onApiCalledResult = (int errorCode, String funcName, String info) {
      if (errorCode != 0) {
        String errorMessage = 'onApiCalledResult, $funcName failed: $errorCode, $info';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        debugPrint(errorMessage);

        if (funcName == 'startScreenCapture') {
          stopScreenSharing();
        }
      }
    };

    ZegoExpressEngine.onPlayerVideoSizeChanged = (String streamID, int width, int height) {
      String message = 'onPlayerVideoSizeChanged: $streamID, ${width}x$height,isLandScape: ${width > height}';
      debugPrint(message);
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onApiCalledResult = null;
    ZegoExpressEngine.onPlayerVideoSizeChanged = null;
  }

  Future<void> startScreenSharing() async {
    screenSharingSource ??= (await ZegoExpressEngine.instance.createScreenCaptureSource())!;
    await ZegoExpressEngine.instance.setVideoConfig(
      ZegoVideoConfig.preset(ZegoVideoConfigPreset.Preset720P)..fps = 10,
      channel: ZegoPublishChannel.Aux,
    );
    await ZegoExpressEngine.instance.setVideoSource(ZegoVideoSourceType.ScreenCapture, channel: ZegoPublishChannel.Aux);
    await screenSharingSource!.startCapture();
    String streamID = '${widget.roomID}_${widget.localUserID}_screen';
    await ZegoExpressEngine.instance.startPublishingStream(streamID, channel: ZegoPublishChannel.Aux);
    await ZegoExpressEngine.instance.stopPublishingStream(channel: ZegoPublishChannel.Aux);
    await ZegoExpressEngine.instance.startPublishingStream(streamID, channel: ZegoPublishChannel.Aux);
    setState(() => isSharingScreen = true);

    bool needPreview = false;
    // ignore: dead_code
    if (needPreview && (hostScreenViewID == null)) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        hostScreenViewID = viewID;
        ZegoCanvas previewCanvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFit);
        ZegoExpressEngine.instance.startPreview(canvas: previewCanvas, channel: ZegoPublishChannel.Aux);
      }).then((canvasViewWidget) {
        // use this canvasViewWidget to preview the screensharing
        setState(() => hostScreenView = canvasViewWidget);
      });
    }
  }

  Future<void> stopScreenSharing() async {
    await screenSharingSource?.stopCapture();
    await ZegoExpressEngine.instance.stopPreview(channel: ZegoPublishChannel.Aux);
    await ZegoExpressEngine.instance.stopPublishingStream(channel: ZegoPublishChannel.Aux);
    await ZegoExpressEngine.instance.setVideoSource(ZegoVideoSourceType.None, channel: ZegoPublishChannel.Aux);
    if (mounted) setState(() => isSharingScreen = false);
    if (hostScreenViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(hostScreenViewID!);
      if (mounted) {
        setState(() {
          hostScreenViewID = null;
          hostScreenView = null;
        });
      }
    }
  }

  Future<void> startPreview() async {
    // cameraView
    ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      hostCameraViewID = viewID;
      ZegoCanvas previewCanvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFit);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas, channel: ZegoPublishChannel.Main);
    }).then((canvasViewWidget) {
      setState(() => hostCameraView = canvasViewWidget);
    });
  }

  Future<void> stopPreview() async {
    ZegoExpressEngine.instance.stopPreview(channel: ZegoPublishChannel.Main);
    if (hostCameraViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(hostCameraViewID!);
      if (mounted) {
        setState(() {
          hostCameraViewID = null;
          hostCameraView = null;
        });
      }
    }
  }

  Future<void> startPublish() async {
    // After calling the `loginRoom` method, call this method to publish streams.
    // The StreamID must be unique in the room.
    String streamID = '${widget.roomID}_${widget.localUserID}_live';
    return ZegoExpressEngine.instance.startPublishingStream(streamID, channel: ZegoPublishChannel.Main);
  }

  Future<void> stopPublish() async {
    return ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> startPlayStream(String streamID) async {
    // Start to play streams. Set the view for rendering the remote streams.
    bool isScreenSharingStream = streamID.endsWith('_screen');
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      if (isScreenSharingStream) {
        hostScreenViewID = viewID;
      } else {
        hostCameraViewID = viewID;
      }
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFit);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((canvasViewWidget) {
      setState(() {
        if (isScreenSharingStream) {
          hostScreenView = canvasViewWidget;
          isSharingScreen = true;
        } else {
          hostCameraView = canvasViewWidget;
        }
      });
    });
  }

  Future<void> stopPlayStream(String streamID) async {
    bool isScreenSharingStream = streamID.endsWith('_screen');

    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    if (isScreenSharingStream) {
      if (hostScreenViewID != null) {
        ZegoExpressEngine.instance.destroyCanvasView(hostScreenViewID!);
        if (mounted) {
          setState(() {
            hostScreenViewID = null;
            hostScreenView = null;
            isSharingScreen = false;
          });
        }
      }
    } else {
      if (hostCameraViewID != null) {
        ZegoExpressEngine.instance.destroyCanvasView(hostCameraViewID!);
        if (mounted) {
          setState(() {
            hostCameraViewID = null;
            hostCameraView = null;
          });
        }
      }
    }
  }
}

class DemoButton extends StatelessWidget {
  const DemoButton({
    Key? key,
    required this.onPressed,
    required this.text,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 160,
        height: 50,
        child: ElevatedButton(onPressed: onPressed, child: Text(text)),
      ),
    );
  }
}
