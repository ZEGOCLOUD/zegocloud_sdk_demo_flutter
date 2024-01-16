import 'package:flutter/material.dart';

import '../../internal/internal_defines.dart';
import '../../internal/sdk/effect/internal/beauty_ability/zego_beauty_item.dart';
import '../../internal/sdk/effect/internal/beauty_ability/zego_beauty_type.dart';

class ZegoBeautyData {
  static List<ZegoEffectModel> data() => [
        basicModel,
        advancedModel,
        filtersModel,
        lipsModel,
        blusherModel,
        eyelashesModel,
        eyelinerModel,
        eyeshadowModel,
        coloredContactsModel,
        styleMakeupModel,
        stickersModel,
        backgroundModel,
      ];

  static ZegoEffectModel basicModel = ZegoEffectModel(
    title: 'Basic',
    type: ZegoEffectModelType.basic,
    items: [
      ZegoBeautyType.beautyBasicReset,
      ZegoBeautyType.beautyBasicSmoothing,
      ZegoBeautyType.beautyBasicSkinTone,
      ZegoBeautyType.beautyBasicBlusher,
      ZegoBeautyType.beautyBasicSharpening,
      ZegoBeautyType.beautyBasicWrinkles,
      ZegoBeautyType.beautyBasicDarkCircles,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel advancedModel = ZegoEffectModel(
      title: 'Advanced',
      type: ZegoEffectModelType.advanced,
      items: [
        ZegoBeautyType.beautyAdvancedReset,
        ZegoBeautyType.beautyAdvancedFaceSlimming,
        ZegoBeautyType.beautyAdvancedEyesEnlarging,
        ZegoBeautyType.beautyAdvancedEyesBrightening,
        ZegoBeautyType.beautyAdvancedChinLengthening,
        ZegoBeautyType.beautyAdvancedMouthReshape,
        ZegoBeautyType.beautyAdvancedTeethWhitening,
        ZegoBeautyType.beautyAdvancedNoseSlimming,
        ZegoBeautyType.beautyAdvancedNoseLengthening,
        ZegoBeautyType.beautyAdvancedFaceShortening,
        ZegoBeautyType.beautyAdvancedMandibleSlimming,
        ZegoBeautyType.beautyAdvancedCheekboneSlimming,
        ZegoBeautyType.beautyAdvancedForeheadSlimming,
      ].map((type) {
        return ZegoEffectItem(
          type: type,
          icon: icon(type),
          selectIcon: selectedIcon(type),
          iconText: beautyItemText(type),
          textStyle: textStyle(type),
          selectedTextStyle: selectedTextStyle(type),
        );
      }).toList());

  static ZegoEffectModel filtersModel = ZegoEffectModel(
    title: 'Filters',
    type: ZegoEffectModelType.filter,
    items: [
      ZegoBeautyType.filterReset,
      ZegoBeautyType.filterNaturalCreamy,
      ZegoBeautyType.filterNaturalBrighten,
      ZegoBeautyType.filterNaturalFresh,
      ZegoBeautyType.filterNaturalAutumn,
      ZegoBeautyType.filterGrayMonet,
      ZegoBeautyType.filterGrayNight,
      ZegoBeautyType.filterGrayFilmlike,
      ZegoBeautyType.filterDreamySunset,
      ZegoBeautyType.filterDreamyCozily,
      ZegoBeautyType.filterDreamySweet
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel lipsModel = ZegoEffectModel(
    title: 'Lipstick',
    type: ZegoEffectModelType.lipstick,
    items: [
      ZegoBeautyType.beautyMakeupLipstickReset,
      ZegoBeautyType.beautyMakeupLipstickCameoPink,
      ZegoBeautyType.beautyMakeupLipstickSweetOrange,
      ZegoBeautyType.beautyMakeupLipstickRustRed,
      ZegoBeautyType.beautyMakeupLipstickCoral,
      ZegoBeautyType.beautyMakeupLipstickRedVelvet,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel blusherModel = ZegoEffectModel(
    title: 'Blusher',
    type: ZegoEffectModelType.blusher,
    items: [
      ZegoBeautyType.beautyMakeupBlusherReset,
      ZegoBeautyType.beautyMakeupBlusherSlightlyDrunk,
      ZegoBeautyType.beautyMakeupBlusherPeach,
      ZegoBeautyType.beautyMakeupBlusherMilkyOrange,
      ZegoBeautyType.beautyMakeupBlusherAprocitPink,
      ZegoBeautyType.beautyMakeupBlusherSweetOrange,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel eyelashesModel = ZegoEffectModel(
    title: 'Eyelashes',
    type: ZegoEffectModelType.eyelash,
    items: [
      ZegoBeautyType.beautyMakeupEyelashesReset,
      ZegoBeautyType.beautyMakeupEyelashesNatural,
      ZegoBeautyType.beautyMakeupEyelashesTender,
      ZegoBeautyType.beautyMakeupEyelashesCurl,
      ZegoBeautyType.beautyMakeupEyelashesEverlong,
      ZegoBeautyType.beautyMakeupEyelashesThick,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel eyelinerModel = ZegoEffectModel(
    title: 'Eyeliner',
    type: ZegoEffectModelType.eyeliner,
    items: [
      ZegoBeautyType.beautyMakeupEyelinerReset,
      ZegoBeautyType.beautyMakeupEyelinerNatural,
      ZegoBeautyType.beautyMakeupEyelinerCatEye,
      ZegoBeautyType.beautyMakeupEyelinerNaughty,
      ZegoBeautyType.beautyMakeupEyelinerInnocent,
      ZegoBeautyType.beautyMakeupEyelinerDignified,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel eyeshadowModel = ZegoEffectModel(
    title: 'Eyeshadow',
    type: ZegoEffectModelType.eyeshadow,
    items: [
      ZegoBeautyType.beautyMakeupEyeshadowReset,
      ZegoBeautyType.beautyMakeupEyeshadowPinkMist,
      ZegoBeautyType.beautyMakeupEyeshadowShimmerPink,
      ZegoBeautyType.beautyMakeupEyeshadowTeaBrown,
      ZegoBeautyType.beautyMakeupEyeshadowBrightOrange,
      ZegoBeautyType.beautyMakeupEyeshadowMochaBrown,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel coloredContactsModel = ZegoEffectModel(
    title: 'Colored Contacts',
    type: ZegoEffectModelType.coloredContacts,
    items: [
      ZegoBeautyType.beautyMakeupColoredContactsReset,
      ZegoBeautyType.beautyMakeupColoredContactsDarknightBlack,
      ZegoBeautyType.beautyMakeupColoredContactsStarryBlue,
      ZegoBeautyType.beautyMakeupColoredContactsBrownGreen,
      ZegoBeautyType.beautyMakeupColoredContactsLightsBrown,
      ZegoBeautyType.beautyMakeupColoredContactsChocolateBrown,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel styleMakeupModel = ZegoEffectModel(
    title: 'Style',
    type: ZegoEffectModelType.style,
    items: [
      ZegoBeautyType.beautyStyleMakeupReset,
      ZegoBeautyType.beautyStyleMakeupInnocentEyes,
      ZegoBeautyType.beautyStyleMakeupMilkyEyes,
      ZegoBeautyType.beautyStyleMakeupCutieCool,
      ZegoBeautyType.beautyStyleMakeupPureSexy,
      ZegoBeautyType.beautyStyleMakeupFlawless,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel stickersModel = ZegoEffectModel(
    title: 'Stickers',
    type: ZegoEffectModelType.sticker,
    items: [
      ZegoBeautyType.stickerReset,
      ZegoBeautyType.stickerAnimal,
      ZegoBeautyType.stickerDive,
      ZegoBeautyType.stickerCat,
      ZegoBeautyType.stickerWatermelon,
      ZegoBeautyType.stickerDeer,
      ZegoBeautyType.stickerCoolGirl,
      ZegoBeautyType.stickerClown,
      ZegoBeautyType.stickerClawMachine,
      ZegoBeautyType.stickerSailorMoon,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static ZegoEffectModel backgroundModel = ZegoEffectModel(
    title: 'Background',
    type: ZegoEffectModelType.background,
    items: [
      ZegoBeautyType.backgroundReset,
      ZegoBeautyType.backgroundPortraitSegmentation,
      ZegoBeautyType.backgroundMosaicing,
      ZegoBeautyType.backgroundGaussianBlur,
    ].map((type) {
      return ZegoEffectItem(
        type: type,
        icon: icon(type),
        selectIcon: selectedIcon(type),
        iconText: beautyItemText(type),
        textStyle: textStyle(type),
        selectedTextStyle: selectedTextStyle(type),
      );
    }).toList(),
  );

  static String beautyItemText(ZegoBeautyType type) {
    switch (type) {
      // Basic
      case ZegoBeautyType.beautyBasicReset:
        return 'Reset';
      case ZegoBeautyType.beautyBasicSmoothing:
        return 'Smoothing';
      case ZegoBeautyType.beautyBasicSkinTone:
        return 'Skin Tone';
      case ZegoBeautyType.beautyBasicBlusher:
        return 'Blusher';
      case ZegoBeautyType.beautyBasicSharpening:
        return 'Sharpening';
      case ZegoBeautyType.beautyBasicWrinkles:
        return 'Wrinkles';
      case ZegoBeautyType.beautyBasicDarkCircles:
        return 'Dark Circles';

      // Advanced
      case ZegoBeautyType.beautyAdvancedReset:
        return 'Reset';
      case ZegoBeautyType.beautyAdvancedFaceSlimming:
        return 'Slimming';
      case ZegoBeautyType.beautyAdvancedEyesEnlarging:
        return 'Enlarging';
      case ZegoBeautyType.beautyAdvancedEyesBrightening:
        return 'Brightening';
      case ZegoBeautyType.beautyAdvancedChinLengthening:
        return 'Lengthening';
      case ZegoBeautyType.beautyAdvancedMouthReshape:
        return 'Reshape';
      case ZegoBeautyType.beautyAdvancedTeethWhitening:
        return 'Whitening';
      case ZegoBeautyType.beautyAdvancedNoseSlimming:
        return 'Slimming';
      case ZegoBeautyType.beautyAdvancedNoseLengthening:
        return 'Lengthening';
      case ZegoBeautyType.beautyAdvancedFaceShortening:
        return 'Shortening';
      case ZegoBeautyType.beautyAdvancedMandibleSlimming:
        return 'Mandible';
      case ZegoBeautyType.beautyAdvancedCheekboneSlimming:
        return 'Cheekbone';
      case ZegoBeautyType.beautyAdvancedForeheadSlimming:
        return 'Forehead';

      // Filter
      case ZegoBeautyType.filterReset:
        return 'Reset';
      case ZegoBeautyType.filterNaturalCreamy:
        return 'Creamy';
      case ZegoBeautyType.filterNaturalBrighten:
        return 'Brighten';
      case ZegoBeautyType.filterNaturalFresh:
        return 'Fresh';
      case ZegoBeautyType.filterNaturalAutumn:
        return 'Autumn';
      case ZegoBeautyType.filterGrayMonet:
        return 'Monet';
      case ZegoBeautyType.filterGrayNight:
        return 'Night';
      case ZegoBeautyType.filterGrayFilmlike:
        return 'Film-like';
      case ZegoBeautyType.filterDreamySunset:
        return 'Sunset';
      case ZegoBeautyType.filterDreamyCozily:
        return 'Cozily';
      case ZegoBeautyType.filterDreamySweet:
        return 'Sweet';
      case ZegoBeautyType.beautyMakeupLipstickReset:
        return 'Reset';
      case ZegoBeautyType.beautyMakeupLipstickCameoPink:
        return 'Cameo Pink';
      case ZegoBeautyType.beautyMakeupLipstickSweetOrange:
        return 'Sweet Orange';
      case ZegoBeautyType.beautyMakeupLipstickRustRed:
        return 'Rust Red';
      case ZegoBeautyType.beautyMakeupLipstickCoral:
        return 'Coral';
      case ZegoBeautyType.beautyMakeupLipstickRedVelvet:
        return 'Red Velvet';

      // Makeup - Blusher
      case ZegoBeautyType.beautyMakeupBlusherReset:
        return 'None';
      case ZegoBeautyType.beautyMakeupBlusherSlightlyDrunk:
        return 'Slightly Drunk';
      case ZegoBeautyType.beautyMakeupBlusherPeach:
        return 'Peach';
      case ZegoBeautyType.beautyMakeupBlusherMilkyOrange:
        return 'Milky Orange';
      case ZegoBeautyType.beautyMakeupBlusherAprocitPink:
        return 'Aprocit Pink';
      case ZegoBeautyType.beautyMakeupBlusherSweetOrange:
        return 'Sweet Orange';

      // Makeup - Eyelashes
      case ZegoBeautyType.beautyMakeupEyelashesReset:
        return 'None';
      case ZegoBeautyType.beautyMakeupEyelashesNatural:
        return 'Natural';
      case ZegoBeautyType.beautyMakeupEyelashesTender:
        return 'Tender';
      case ZegoBeautyType.beautyMakeupEyelashesCurl:
        return 'Curl';
      case ZegoBeautyType.beautyMakeupEyelashesEverlong:
        return 'Everlong';
      case ZegoBeautyType.beautyMakeupEyelashesThick:
        return 'Thick';

      // Makeup - Eyeliner
      case ZegoBeautyType.beautyMakeupEyelinerReset:
        return 'None';
      case ZegoBeautyType.beautyMakeupEyelinerNatural:
        return 'Natural';
      case ZegoBeautyType.beautyMakeupEyelinerCatEye:
        return 'Cat Eye';
      case ZegoBeautyType.beautyMakeupEyelinerNaughty:
        return 'Naughty';
      case ZegoBeautyType.beautyMakeupEyelinerInnocent:
        return 'Innocent';
      case ZegoBeautyType.beautyMakeupEyelinerDignified:
        return 'Dignified';

      // Makeup - Eyeshadow
      case ZegoBeautyType.beautyMakeupEyeshadowReset:
        return 'None';
      case ZegoBeautyType.beautyMakeupEyeshadowPinkMist:
        return 'Pink Mist';
      case ZegoBeautyType.beautyMakeupEyeshadowShimmerPink:
        return 'Shimmer Pink';
      case ZegoBeautyType.beautyMakeupEyeshadowTeaBrown:
        return 'Tea Brown';
      case ZegoBeautyType.beautyMakeupEyeshadowBrightOrange:
        return 'Bright Orange';
      case ZegoBeautyType.beautyMakeupEyeshadowMochaBrown:
        return 'Mocha Brown';

      // Makeup - Colored Contacts
      case ZegoBeautyType.beautyMakeupColoredContactsReset:
        return 'None';
      case ZegoBeautyType.beautyMakeupColoredContactsDarknightBlack:
        return 'Darknight Black';
      case ZegoBeautyType.beautyMakeupColoredContactsStarryBlue:
        return 'StarryBlue';
      case ZegoBeautyType.beautyMakeupColoredContactsBrownGreen:
        return 'Brown Green';
      case ZegoBeautyType.beautyMakeupColoredContactsLightsBrown:
        return 'Lights Brown';
      case ZegoBeautyType.beautyMakeupColoredContactsChocolateBrown:
        return 'Chocolate Brown';

      // Style Makeup
      case ZegoBeautyType.beautyStyleMakeupReset:
        return 'None';
      case ZegoBeautyType.beautyStyleMakeupInnocentEyes:
        return 'Innocent Eyes';
      case ZegoBeautyType.beautyStyleMakeupMilkyEyes:
        return 'Milky Eyes';
      case ZegoBeautyType.beautyStyleMakeupCutieCool:
        return 'Cutie Cool';
      case ZegoBeautyType.beautyStyleMakeupPureSexy:
        return 'Pure Sexy';
      case ZegoBeautyType.beautyStyleMakeupFlawless:
        return 'Flawless';

      // Stickers
      case ZegoBeautyType.stickerReset:
        return 'None';
      case ZegoBeautyType.stickerAnimal:
        return 'Animal';
      case ZegoBeautyType.stickerDive:
        return 'Dive';
      case ZegoBeautyType.stickerCat:
        return 'Cat';
      case ZegoBeautyType.stickerWatermelon:
        return 'Watermelon';
      case ZegoBeautyType.stickerDeer:
        return 'Deer';
      case ZegoBeautyType.stickerCoolGirl:
        return 'Cool Girl';
      case ZegoBeautyType.stickerClown:
        return 'Clown';
      case ZegoBeautyType.stickerClawMachine:
        return 'Claw Machine';
      case ZegoBeautyType.stickerSailorMoon:
        return 'Sailor Moon';

      // Background
      case ZegoBeautyType.backgroundReset:
        return 'None';
      case ZegoBeautyType.backgroundPortraitSegmentation:
        return 'Portrait Segmentation';
      case ZegoBeautyType.backgroundMosaicing:
        return 'Mosaicing';
      case ZegoBeautyType.backgroundGaussianBlur:
        return 'Gaussian Blur';
      default:
        return type.name;
    }
  }

  static String beautyIconPath(String name) => 'assets/beautyIcons/$name.png';

  static ButtonIcon icon(ZegoBeautyType type) {
    return ButtonIcon(
      icon: Image.asset(beautyIconPath(type.name)),
    );
  }

  static ButtonIcon selectedIcon(ZegoBeautyType type) {
    var radius = 24.0;
    if (type.index >= ZegoBeautyType.beautyStyleMakeupInnocentEyes.index) {
      radius = 8.0;
    }
    Color? color = const Color(0xffA653FF);
    if (type.index >= ZegoBeautyType.beautyBasicReset.index) {
      color = null;
    }
    return ButtonIcon(
      icon: Image.asset(beautyIconPath(type.name)),
      borderColor: color,
      borderWidth: 2.0,
      borderRadius: radius,
    );
  }

  static TextStyle textStyle(ZegoBeautyType type) {
    return const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle selectedTextStyle(ZegoBeautyType type) {
    if (type.index >= ZegoBeautyType.beautyBasicReset.index) {
      return textStyle(type);
    }
    return const TextStyle(
      color: Color(0xffA653FF),
      fontSize: 11,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
    );
  }
}
