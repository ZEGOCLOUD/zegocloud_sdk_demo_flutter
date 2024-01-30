import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

import '../../../components/gift/mp4_player.dart';
import '../../../zego_sdk_manager.dart';
import 'defines.dart';

part 'gift_cache.dart';
part 'gift_protocol.dart';
part 'gift_play_list.dart';

class ZegoGiftManager with GiftCache, GiftPlayList, GiftProtocol {
  static final ZegoGiftManager _singleton = ZegoGiftManager._internal();
  factory ZegoGiftManager() => _singleton;
  ZegoGiftManager._internal();
}
