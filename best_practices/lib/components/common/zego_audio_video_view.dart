import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';

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
      valueListenable: widget.userInfo.isCameraOnNotifier,
      builder: (context, isCameraOn, _) {
        return createView(isCameraOn);
      },
    );
  }

  Widget createView(bool isCameraOn) {
    return LayoutBuilder(builder: (context, constraints) {
      if (isCameraOn) {
        return Stack(
          children: [videoView(), userNameText(constraints)],
        );
      } else {
        return Stack(
          children: [noVideoView(constraints), userNameText(constraints)],
        );
      }
    });
  }

  Widget noVideoView(BoxConstraints constraints) {
    if (widget.userInfo.streamID != null) {
      if (widget.userInfo.streamID!.endsWith('_host')) {
        return backGroundView();
      } else {
        return normalView();
      }
    } else {
      return normalView();
    }
  }

  Widget userNameText(BoxConstraints constraints) {
    return Positioned(
        right: 10,
        bottom: 10,
        width: constraints.maxWidth - 15,
        height: 20,
        child: Text(
          widget.userInfo.userName,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ));
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
        Center(child: headView()),
      ],
    );
  }

  Widget headView() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        border: Border.all(width: 0),
      ),
      child: ValueListenableBuilder(
          valueListenable: widget.userInfo.avatarUrlNotifier,
          builder: (context, String? url, _) {
            if (url != null) {
              return Image.network(url);
            } else {
              return Center(
                child: SizedBox(
                  height: 20,
                  child: Text(
                    widget.userInfo.userName.isNotEmpty ? widget.userInfo.userName[0] : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
          }),
    );
  }

  Widget normalView() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        Center(
          child: headView(),
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
          return const SizedBox.shrink();
        }
      },
    );
  }
}
