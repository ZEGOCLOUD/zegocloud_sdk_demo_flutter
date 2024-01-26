import 'package:flutter/material.dart';

import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';

import '../../internal/business/gift/defines.dart';
import '../../internal/business/gift/gift_manager.dart';


class ZegoSvgaPlayerWidget extends StatefulWidget {
  const ZegoSvgaPlayerWidget({
    Key? key,
    required this.onPlayEnd,
    required this.playData,
    this.size,
    this.textStyle,
  }) : super(key: key);

  final VoidCallback onPlayEnd;
  final PlayData playData;

  /// restrict the display area size for the gift animation
  final Size? size;

  /// the gift count text style
  final TextStyle? textStyle;

  @override
  State<ZegoSvgaPlayerWidget> createState() => ZegoSvgaPlayerWidgetState();
}

class ZegoSvgaPlayerWidgetState extends State<ZegoSvgaPlayerWidget>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? animationController;

  final loadedNotifier = ValueNotifier<bool>(false);
  late Future<MovieEntity> movieEntity;

  double get fontSize => 15;

  Size get displaySize => null != widget.size
      ? Size(
          (widget.size!.width) -
              widget.playData.count.toString().length * fontSize,
          widget.size!.height,
        )
      : MediaQuery.of(context).size;

  Size get countSize => Size(
        (widget.playData.count.toString().length + 2) * fontSize * 1.2,
        fontSize + 2,
      );

  @override
  void initState() {
    super.initState();

    debugPrint('load ${widget.playData} begin:${DateTime.now().toString()}');
    switch (widget.playData.giftItem.source) {
      case ZegoGiftSource.url:
        ZegoGiftManager()
            .cache
            .readFromURL(url: widget.playData.giftItem.sourceURL)
            .then((byteData) {
          movieEntity = SVGAParser.shared.decodeFromBuffer(byteData);

          loadedNotifier.value = true;
          setState(() {});
        });
        break;
      case ZegoGiftSource.asset:
        ZegoGiftManager()
            .cache
            .readFromAsset(widget.playData.giftItem.sourceURL)
            .then((byteData) {
          movieEntity = SVGAParser.shared.decodeFromBuffer(byteData);

          loadedNotifier.value = true;
          setState(() {});
        });
        break;
    }
  }

  @override
  void dispose() {
    if (animationController?.isAnimating ?? false) {
      animationController?.stop();
      widget.onPlayEnd();
    }

    animationController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadedNotifier,
      builder: (context, isLoaded, _) {
        if (!isLoaded) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.red,
            ),
          );
        }

        debugPrint(
            'load ${widget.playData.giftItem} done:${DateTime.now().toString()}');

        return FutureBuilder<MovieEntity>(
          future: movieEntity,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              animationController ??= (SVGAAnimationController(vsync: this)
                ..videoItem = snapshot.data as MovieEntity
                ..forward().whenComplete(() {
                  widget.onPlayEnd();
                }));

              final countWidget = widget.playData.count > 1
                  ? SizedBox.fromSize(
                      size: countSize,
                      child: Text(
                        'x ${widget.playData.count}',
                        style: widget.textStyle ??
                            TextStyle(
                              fontSize: fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : const SizedBox.shrink();

              if (displaySize.width < MediaQuery.of(context).size.width) {
                ///  width < 1/2
                return Row(
                  children: [
                    SizedBox.fromSize(
                      size: displaySize,
                      child: SVGAImage(animationController!),
                    ),
                    countWidget,
                  ],
                );
              }

              return SizedBox.fromSize(
                size: displaySize,
                child: Stack(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: SizedBox.fromSize(
                      size: displaySize,
                      child: SVGAImage(animationController!),
                    )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: countWidget,
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      },
    );
  }
}
