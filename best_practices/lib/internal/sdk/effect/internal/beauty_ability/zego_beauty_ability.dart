import 'zego_beauty_editor.dart';
import 'zego_beauty_type.dart';

class ZegoBeautyAbility {
  final int maxValue;
  final int minValue;
  final int defaultValue;
  final ZegoBeautyType type;
  final ZegoBeautyEditor editor;
  int _currentValue = 0;

  int get currentValue {
    return _currentValue;
  }

  set currentValue(int value) {
    _currentValue = value;
    editor.apply(value);
  }

  ZegoBeautyAbility({
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.type,
    required this.editor,
  }) {
    currentValue = defaultValue;
  }

  void reset() {
    currentValue = defaultValue;
  }
}
