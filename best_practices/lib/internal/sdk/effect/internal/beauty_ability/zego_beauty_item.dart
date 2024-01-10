import 'package:flutter/material.dart';

import '../../../../internal_defines.dart';
import 'zego_beauty_type.dart';

class ZegoEffectItem {
  ZegoBeautyType type;
  ButtonIcon icon;
  ButtonIcon? selectIcon;
  String iconText;
  TextStyle? textStyle;
  TextStyle? selectedTextStyle;

  ZegoEffectItem({
    required this.type,
    required this.icon,
    required this.iconText,
    this.selectIcon,
    this.textStyle,
    this.selectedTextStyle,
  });
}

enum ZegoEffectModelType {
  basic,
  advanced,
  filter,
  lipstick,
  blusher,
  eyelash,
  eyeliner,
  eyeshadow,
  coloredContacts,
  style,
  sticker,
  background,
}

class ZegoEffectModel {
  String title;
  ZegoEffectModelType type;
  List<ZegoEffectItem> items = [];

  ZegoEffectModel({
    required this.title,
    required this.items,
    required this.type,
  });
}
