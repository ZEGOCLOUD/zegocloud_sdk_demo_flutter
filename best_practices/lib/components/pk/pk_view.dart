import 'package:flutter/material.dart';

import '../../internal/business/pk/pk_user.dart';
import '../../zego_sdk_manager.dart';

class PKView extends StatefulWidget {
  final PKUser pkUser;
  const PKView({super.key, required this.pkUser});

  @override
  State<PKView> createState() => _PKViewState();
}

class _PKViewState extends State<PKView> {
  @override
  void initState() {
    super.initState();
    if (widget.pkUser.userID == ZEGOSDKManager().currentUser?.userID) {
      // ZEGOSDKManager().expressService.startPreview();
    } else {
      ZEGOSDKManager().expressService.startPlayingAnotherHostStream(widget.pkUser.pkUserStream, widget.pkUser.sdkUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.pkUser.connectingDuration,
        builder: (context, int duration, _) {
          if (duration > 5000) {
            return hostReconnecting();
          } else {
            return ValueListenableBuilder(
                valueListenable: widget.pkUser.camera,
                builder: (context, bool isCameraOn, _) {
                  if (isCameraOn) {
                    return SizedBox(
                      child: Stack(
                        children: [videoView(), foregroundView()],
                      ),
                    );
                  } else {
                    return SizedBox(
                      child: backGroundView(),
                    );
                  }
                });
          }
        });
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
                    widget.pkUser.userName[0],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )),
            ),
          ),
        ),
      ],
    );
  }

  Widget foregroundView() {
    return Container(
      color: Colors.transparent,
    );
  }

  Widget videoView() {
    return ValueListenableBuilder<Widget?>(
      valueListenable: widget.pkUser.sdkUser.videoViewNotifier,
      builder: (context, view, _) {
        if (view != null) {
          return Container(
            color: Colors.blue,
            child: view,
          );
        } else {
          return Container(
            color: Colors.red,
          );
        }
      },
    );
  }

  Widget hostReconnecting() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Host is reconnecting…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
