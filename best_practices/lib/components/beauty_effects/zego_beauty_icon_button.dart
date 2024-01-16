// Flutter imports:
import 'package:flutter/material.dart';
import '../../internal/internal_defines.dart';

/// @nodoc
/// text button
/// icon button
/// text+icon button
class ZegoTextIconButton extends StatefulWidget {
  final String? text;
  final TextStyle? textStyle;

  final ButtonIcon? icon;
  final Size? iconSize;
  final double? iconTextSpacing;

  final Size? buttonSize;

  final VoidCallback? onPressed;

  const ZegoTextIconButton({
    Key? key,
    this.text,
    this.textStyle,
    this.icon,
    this.iconTextSpacing,
    this.iconSize,
    this.buttonSize,
    this.onPressed,
  }) : super(key: key);

  @override
  State<ZegoTextIconButton> createState() => _ZegoTextIconButtonState();
}

/// @nodoc
class _ZegoTextIconButtonState extends State<ZegoTextIconButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: widget.buttonSize?.width ?? 120,
        height: widget.buttonSize?.height ?? 120,
        decoration: const BoxDecoration(
            // color: Colors.orange,
            // shape: BoxShape.circle,
            ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children(context),
        ),
      ),
    );
  }

  List<Widget> children(BuildContext context) {
    return [
      icon(),
      ...text(),
    ];
  }

  Widget icon() {
    if (widget.icon == null) {
      return Container();
    }

    return Container(
      width: widget.iconSize?.width ?? 74,
      height: widget.iconSize?.height ?? 74,
      decoration: BoxDecoration(
        color: widget.icon?.backgroundColor ?? Colors.transparent,
        border: Border.all(
          color: widget.icon?.borderColor ?? Colors.transparent,
          width: widget.icon?.borderWidth ?? 1,
        ),
        borderRadius: BorderRadius.all(
            Radius.circular(widget.icon?.borderRadius ?? 74 / 2)),
      ),
      child: widget.icon?.icon,
    );
  }

  List<Widget> text() {
    if (widget.text == null || widget.text!.isEmpty) {
      return [Container()];
    }

    return [
      SizedBox(height: widget.iconTextSpacing ?? 10),
      Text(
        widget.text!,
        softWrap: false,
        style: widget.textStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  void onPressed() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }
}
