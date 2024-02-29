import 'package:flutter/cupertino.dart';

class ZegoSwipingPageBuilder extends StatefulWidget {
  const ZegoSwipingPageBuilder({
    super.key,
    required this.itemBuilder,
    required this.onPageChanged,
  });

  final NullableIndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;

  @override
  State<ZegoSwipingPageBuilder> createState() => _ZegoSwipingPageBuilderState();
}

class _ZegoSwipingPageBuilderState extends State<ZegoSwipingPageBuilder> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageChanged(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      allowImplicitScrolling: true,
      scrollDirection: Axis.vertical,
      itemBuilder: widget.itemBuilder,
      onPageChanged: widget.onPageChanged,
    );
  }
}
