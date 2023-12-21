import 'package:flutter/material.dart';

import '../../internal/sdk/effect/internal/beauty_ability/zego_beauty_item.dart';
import '../../internal/sdk/effect/internal/beauty_ability/zego_beauty_type.dart';
import '../../zego_sdk_manager.dart';
import 'zego_beauty_data.dart';
import 'zego_beauty_icon_button.dart';
import 'zego_beauty_slider.dart';

final selectedEffectTypeNotifier = ValueNotifier<ZegoBeautyType?>(null);
final selectedModelNotifier = ValueNotifier<ZegoEffectModel>(ZegoBeautyData.data()[0]);
final Map<ZegoEffectModelType, ZegoBeautyType> modelSelectedTypeMap = {};

class ZegoBeautyEffectSheet extends StatefulWidget {
  const ZegoBeautyEffectSheet({super.key});

  @override
  State<StatefulWidget> createState() => _ZegoBeautyEffectSheetState();
}

double get _besSheetTotalHeight => 165;

double get _besSliderHeight => 20;

double get _besSliderPadding => 22;

class _ZegoBeautyEffectSheetState extends State<ZegoBeautyEffectSheet> {
  final titleController = ScrollController();
  final contentController = ScrollController();
  final Map<ZegoBeautyType, GlobalKey> contentItemKeys = {};
  final Map<ZegoEffectModelType, GlobalKey> titleItemKeys = {};

  bool animated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        slider(),
        sheet(
            height: _besSheetTotalHeight,
            child: Column(
              children: [
                SizedBox(
                  width: 30,
                  height: 4.0,
                  child: Container(
                    decoration:
                        const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(2.0)), color: Colors.white),
                  ),
                ),
                Container(height: 5.0),
                sheetTitle(),
                Container(height: 1.0, color: Colors.white),
                sheetContent(),
              ],
            )),
      ],
    );
  }

  Widget slider() {
    return ValueListenableBuilder<ZegoBeautyType?>(
      valueListenable: selectedEffectTypeNotifier,
      builder: (context, type, child) {
        if (type == null ||
            type == ZegoBeautyType.backgroundPortraitSegmentation ||
            (ZegoBeautyType.stickerAnimal.index <= type.index &&
                type.index <= ZegoBeautyType.stickerSailorMoon.index)) {
          return Container(height: _besSliderHeight + _besSliderPadding);
        } else if (type.index >= ZegoBeautyType.beautyBasicReset.index) {
          // reset to default value.
          for (final item in selectedModelNotifier.value.items) {
            ZEGOSDKManager().effectsService.beautyAbilities[item.type]!.reset();
          }
          return Container(height: _besSliderHeight + _besSliderPadding);
        }

        final ability = ZEGOSDKManager().effectsService.beautyAbilities[type]!;
        return Column(
          children: [
            ZegoBeautyEffectSlider(
              currentValue: ability.currentValue,
              thumpHeight: _besSliderHeight,
              minValue: ability.minValue,
              maxValue: ability.maxValue,
              onChanged: (value) {
                ability.currentValue = value.toInt();
              },
            ),
            SizedBox(height: _besSliderPadding),
          ],
        );
      },
    );
  }

  Widget sheet({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xff222222),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: child,
    );
  }

  Widget sheetTitle() {
    return ValueListenableBuilder(
      valueListenable: selectedModelNotifier,
      builder: (context, selectedModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final itemKey = titleItemKeys[selectedModel.type];
          if (itemKey != null) {
            scrollToCenter(itemKey, titleController);
          }
        });
        return SizedBox(
          height: 40,
          child: ListView.builder(
            controller: titleController,
            itemCount: ZegoBeautyData.data().length,
            scrollDirection: Axis.horizontal,
            cacheExtent: 800,
            itemBuilder: (context, index) {
              final model = ZegoBeautyData.data()[index];
              final isSelected = model.type == selectedModel.type;
              final textColor = isSelected ? Colors.white : const Color(0xffcccccc);
              final textStyle = isSelected
                  ? const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)
                  : const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400);

              final itemKey = GlobalKey();
              titleItemKeys[model.type] = itemKey;
              return TextButton(
                key: itemKey,
                onPressed: () {
                  selectedModelNotifier.value = model;
                  selectBeautyItem();
                },
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(textColor),
                ),
                child: Text(model.title, style: textStyle),
              );
            },
          ),
        );
      },
    );
  }

  Widget sheetContent() {
    return ValueListenableBuilder(
      valueListenable: selectedModelNotifier,
      builder: (context, model, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final beautyType = modelSelectedTypeMap[model.type];
          final itemKey = contentItemKeys[beautyType];
          if (itemKey != null) {
            scrollToCenter(itemKey, contentController);
          } else {
            contentController.jumpTo(0);
          }
        });

        return SizedBox(
            height: 105,
            child: ListView.builder(
              // key: ValueKey(model.type),
              controller: contentController,
              cacheExtent: 74.0 * model.items.length,
              scrollDirection: Axis.horizontal,
              itemCount: model.items.length,
              itemBuilder: (context, index) {
                final item = model.items[index];
                final itemKey = GlobalKey();
                contentItemKeys[item.type] = itemKey;
                return ZegoTextIconButton(
                  key: itemKey,
                  buttonSize: const Size(74, 74),
                  iconSize: const Size(48, 48),
                  icon: item.type == selectedEffectTypeNotifier.value ? item.selectIcon : item.icon,
                  text: item.iconText,
                  textStyle: item.type == selectedEffectTypeNotifier.value ? item.selectedTextStyle : item.textStyle,
                  onPressed: () {
                    final ability = ZEGOSDKManager().effectsService.beautyAbilities[item.type]!;
                    ability.editor.enable(true);
                    ability.editor.apply(ability.currentValue);
                    updateSelectedModelType(item.type);
                    setState(() {});
                  },
                );
              },
            ));
      },
    );
  }

  void updateSelectedModelType(ZegoBeautyType? type) {
    selectedEffectTypeNotifier.value = type;
    if (type == null) return;

    // update select type
    // when enable style makeup, all makeups(lipstick, blusher...) and sticker effects will be invalid.
    // when enable makeup(lipstick, blusher...), style makeup will be invalid.
    // when enable sticker, style makeup will be invalid.
    final modelType = selectedModelNotifier.value.type;
    modelSelectedTypeMap[modelType] = type;
    if (modelType == ZegoEffectModelType.style) {
      modelSelectedTypeMap
        ..remove(ZegoEffectModelType.lipstick)
        ..remove(ZegoEffectModelType.blusher)
        ..remove(ZegoEffectModelType.eyelash)
        ..remove(ZegoEffectModelType.eyeliner)
        ..remove(ZegoEffectModelType.eyeshadow)
        ..remove(ZegoEffectModelType.coloredContacts)
        ..remove(ZegoEffectModelType.sticker);
    } else if (modelType.index >= ZegoEffectModelType.lipstick.index ||
        modelType.index <= ZegoEffectModelType.coloredContacts.index) {
      modelSelectedTypeMap.remove(ZegoEffectModelType.style);
    } else if (modelType == ZegoEffectModelType.sticker) {
      modelSelectedTypeMap.remove(ZegoEffectModelType.style);
    }
  }

  void selectBeautyItem() {
    final modelType = selectedModelNotifier.value.type;
    final beautyType = modelSelectedTypeMap[modelType];
    updateSelectedModelType(beautyType);
  }

  void scrollToCenter(GlobalKey itemKey, ScrollController controller) {
    if (itemKey.currentContext == null) return;
    final itemBox = itemKey.currentContext!.findRenderObject();
    if (itemBox == null) return;
    itemBox as RenderBox;

    final itemPosition = itemBox.localToGlobal(Offset.zero);
    final itemWidth = itemBox.size.width;

    var offset = (MediaQuery.of(context).size.width - itemWidth) / 2 - itemPosition.dx;

    offset = controller.offset - offset;
    if (offset < 0) {
      offset = 0;
    }
    if (offset > controller.position.maxScrollExtent) {
      offset = controller.position.maxScrollExtent;
    }

    if (animated) {
      controller.animateTo(offset, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      controller.jumpTo(offset);
    }
    animated = true;
  }
}

void showBeautyEffectSheet(
  BuildContext context, {
  bool rootNavigator = false,
}) {
  showModalBottomSheet(
    context: context,
    barrierColor: const Color(0xff171821).withOpacity(0.1),
    useRootNavigator: rootNavigator,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 50),
        child: SizedBox(
          height: _besSheetTotalHeight + (_besSliderHeight + _besSliderPadding),
          child: const ZegoBeautyEffectSheet(),
        ),
      );
    },
  );
}
