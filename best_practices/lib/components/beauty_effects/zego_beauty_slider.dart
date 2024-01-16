// Flutter imports:
import 'package:flutter/material.dart';

/// @nodoc
class ZegoBeautyEffectSlider extends StatefulWidget {
  final int currentValue;
  final double? thumpHeight;
  final int? maxValue;
  final int? minValue;
  final ValueChanged<double>? onChanged;

  const ZegoBeautyEffectSlider({
    Key? key,
    required this.currentValue,
    this.thumpHeight,
    this.maxValue,
    this.minValue,
    this.onChanged,
  }) : super(key: key);

  @override
  State<ZegoBeautyEffectSlider> createState() => _ZegoBeautyEffectSliderState();
}

/// @nodoc
class _ZegoBeautyEffectSliderState extends State<ZegoBeautyEffectSlider> {
  var valueNotifier = ValueNotifier<int>(50);

  @override
  void initState() {
    super.initState();

    valueNotifier.value = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    valueNotifier.value = widget.currentValue;

    final thumpHeight = widget.thumpHeight ?? 16;
    return SizedBox(
      width: 320,
      height: thumpHeight,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          valueIndicatorTextStyle: const TextStyle(
            color: Color(0xff1B1A1C),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          valueIndicatorColor: Colors.white.withOpacity(0.5),
          activeTrackColor: Colors.white,
          inactiveTrackColor: const Color(0xff000000).withOpacity(0.3),
          trackHeight: 3,
          thumbColor: Colors.white,
          thumbShape:
              RoundSliderThumbShape(enabledThumbRadius: thumpHeight / 2.0),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return Slider(
              value: value.toDouble(),
              min: (widget.minValue ?? 0).toDouble(),
              max: (widget.maxValue ?? 100).toDouble(),
              divisions: (widget.maxValue ?? 100) - (widget.minValue ?? 0),
              label: value.toDouble().round().toString(),
              onChanged: (double defaultValue) {
                valueNotifier.value = defaultValue.toInt();
                widget.onChanged?.call(defaultValue);
              },
            );
          },
        ),
      ),
    );
  }
}
