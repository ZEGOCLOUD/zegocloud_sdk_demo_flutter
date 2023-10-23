import 'package:flutter/material.dart';
import '../../internal/sdk/express/express_service.dart';

class ZegoAudioVideoView extends StatefulWidget {
  const ZegoAudioVideoView({required this.userInfo, super.key});

  final ZegoSDKUser userInfo;

  @override
  State<ZegoAudioVideoView> createState() => _ZegoAudioVideoViewState();
}

class _ZegoAudioVideoViewState extends State<ZegoAudioVideoView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.userInfo.isCamerOnNotifier,
      builder: (context, isCameraOn, _) {
        return createView(isCameraOn);
      },
    );
  }

  Widget createView(bool isCameraOn) {
    if (isCameraOn) {
      return videoView();
    } else {
      if (widget.userInfo.streamID != null) {
        return coHostNomalView();
      } else {
        return Container();
      }
    }
  }

  Widget backGroundView() {
    return Stack(
      children: [
        Image.asset(
          'assets/icons/bg.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              border: Border.all(width: 0),
            ),
            child: Center(
              child: SizedBox(
                  height: 20,
                  child: Text(
                    widget.userInfo.userName[0],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )),
            ),
          ),
        ),
      ],
    );
  }

  Widget coHostNomalView() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              // border: Border.all(width: 1, color: Colors.white),
            ),
            child: Center(
              child: SizedBox(
                  height: 20,
                  child: Text(
                    widget.userInfo.userName[0],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )),
            ),
          ),
        ),
      ],
    );
  }

  Widget videoView() {
    return ValueListenableBuilder<Widget?>(
      valueListenable: widget.userInfo.videoViewNotifier,
      builder: (context, view, _) {
        if (view != null) {
          return view;
        } else {
          return Container();
        }
      },
    );
  }
}
