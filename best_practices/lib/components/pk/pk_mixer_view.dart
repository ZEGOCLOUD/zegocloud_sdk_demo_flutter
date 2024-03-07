import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

class PKMixerView extends StatefulWidget {
  final List<PKUser> pkAcceptUsers;
  final String mixStreamID;
  const PKMixerView({super.key, required this.pkAcceptUsers, required this.mixStreamID});

  @override
  State<PKMixerView> createState() => _PKMixerViewState();
}

class _PKMixerViewState extends State<PKMixerView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return mixerViewContainer();
  }

  Widget mixerViewContainer() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return SizedBox(
        child: Stack(
          children: [videoView(), backGroundContainer(constraints), hostReconnectingContainer(constraints)],
        ),
      );
    });
  }

  Widget videoView() {
    return ValueListenableBuilder<Widget?>(
      valueListenable: ZEGOSDKManager().expressService.mixerStreamNotifier,
      builder: (context, view, _) {
        if (view != null) {
          return Container(
            color: Colors.blue,
            child: view,
          );
        } else {
          return Container(
            color: Colors.black.withOpacity(0),
          );
        }
      },
    );
  }

  Rect conversionRect(Rect originalRect, BoxConstraints constraints) {
    final wRatio = constraints.maxWidth / 810.0;
    final hRatio = constraints.maxHeight / 720.0;
    return Rect.fromLTRB(originalRect.left * wRatio, originalRect.top * hRatio, originalRect.right * wRatio,
        originalRect.bottom * hRatio);
  }

  Widget backGroundContainer(BoxConstraints constraints) {
    return Stack(
      children: backGroundViews(constraints),
    );
  }

  List<Widget> backGroundViews(BoxConstraints constraints) {
    final views = <Widget>[];
    for (final pkuser in widget.pkAcceptUsers) {
      final newRect = conversionRect(pkuser.rect, constraints);
      final positioned = Positioned(
        left: newRect.left,
        top: newRect.top,
        width: newRect.right - newRect.left,
        height: newRect.bottom - newRect.top,
        child: SizedBox(
            width: newRect.right - newRect.left, height: newRect.bottom - newRect.top, child: backGroundView(pkuser)),
      );
      views.add(positioned);
    }
    return views;
  }

  Widget backGroundView(PKUser user) {
    return ValueListenableBuilder(
        valueListenable: user.sdkUser.isCameraOnNotifier,
        builder: (context, bool isCameraOn, _) {
          if (isCameraOn) {
            return IgnorePointer(
              ignoring: true,
              child: Container(color: Colors.black.withOpacity(0)),
            );
          } else {
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
                            user.userName[0],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          )),
                    ),
                  ),
                ),
              ],
            );
          }
        });
  }

  Widget hostReconnectingContainer(BoxConstraints constraints) {
    return Stack(
      children: hostReconnectingViews(constraints),
    );
  }

  List<Widget> hostReconnectingViews(BoxConstraints constraints) {
    final views = <Widget>[];
    for (final pkuser in widget.pkAcceptUsers) {
      final newRect = conversionRect(pkuser.rect, constraints);
      final positioned = Positioned(
          left: newRect.left,
          top: newRect.top,
          width: newRect.right - newRect.left,
          height: newRect.bottom - newRect.top,
          child: hostReconnecting(pkuser));
      views.add(positioned);
    }
    return views;
  }

  Widget hostReconnecting(PKUser user) {
    return ValueListenableBuilder<int>(
        valueListenable: user.connectingDuration,
        builder: (context, duration, _) {
          if (duration > 5000) {
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
          } else {
            return IgnorePointer(
              ignoring: true,
              child: Container(color: Colors.black.withOpacity(0)),
            );
          }
        });
  }
}
