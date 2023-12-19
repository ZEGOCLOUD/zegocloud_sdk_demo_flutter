import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  const CommonButton(
      {super.key, required this.onTap, required this.child, this.width, this.height, this.borderRadius, this.padding});

  final GestureTapCallback onTap;
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xff1e2740).withOpacity(0.4),
              borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(14)),
            ),
            padding: padding ?? const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
