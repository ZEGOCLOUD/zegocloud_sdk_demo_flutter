import 'package:flutter/material.dart';

import 'zego_defines.dart';

/// switch cameras
class ZegoSpeakerButton extends StatefulWidget {
  const ZegoSpeakerButton({
    Key? key,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.buttonSize,
  }) : super(key: key);

  final ButtonIcon? icon;

  ///  You can do what you want after pressed.
  final void Function()? onPressed;

  /// the size of button's icon
  final Size? iconSize;

  /// the size of button
  final Size? buttonSize;

  @override
  State<ZegoSpeakerButton> createState() => _ZegoSpeakerButtonState();
}

class _ZegoSpeakerButtonState extends State<ZegoSpeakerButton> {
  ValueNotifier<bool> speakerStateNoti = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.buttonSize ?? const Size(96, 96);
    final sizeBoxSize = widget.iconSize ?? const Size(56, 56);

    return ValueListenableBuilder<bool>(
        valueListenable: speakerStateNoti,
        builder: (context, speakerState, _) {
          return GestureDetector(
            onTap: () {
              if (widget.onPressed != null) {
                speakerStateNoti.value = !speakerStateNoti.value;
                widget.onPressed!();
              }
            },
            child: Container(
              width: containerSize.width,
              height: containerSize.height,
              decoration: BoxDecoration(
                color: speakerState
                    ? Colors.white
                    : const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: SizedBox.fromSize(
                size: sizeBoxSize,
                child: speakerState
                    ? const Image(
                        image:
                            AssetImage('assets/icons/toolbar_speaker_off.png'))
                    : const Image(
                        image: AssetImage(
                            'assets/icons/toolbar_speaker_normal.png')),
              ),
            ),
          );
        });
  }
}
