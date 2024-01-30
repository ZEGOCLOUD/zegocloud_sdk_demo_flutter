part of 'gift_manager.dart';

mixin GiftCache {
  final _cacheImpl = CacheImpl();

  CacheImpl get cache => _cacheImpl;
}

class CacheImpl {
  void cache(List<ZegoGiftItem> cacheList) {
    for (var itemData in cacheList) {
      debugPrint('${DateTime.now()} try cache ${itemData.sourceURL}');
      switch (itemData.source) {
        case ZegoGiftSource.url:
          readFromURL(url: itemData.sourceURL).then((value) {
            debugPrint('${DateTime.now()} cache done: ${itemData.sourceURL} ');
          });
          break;
        case ZegoGiftSource.asset:
          readFromAsset(itemData.sourceURL).then((value) {
            debugPrint('${DateTime.now()} cache done: ${itemData.sourceURL} ');
          });
          break;
      }
    }
  }

  Future<List<int>> readFromURL({required String url}) async {
    List<int> result = kTransparentImage.toList();
    final FileInfo? info = await DefaultCacheManager().getFileFromCache(url);
    if (info == null) {
      try {
        final Uri uri = Uri.parse(url);
        final http.Response response = await http.get(uri);
        if (response.statusCode == HttpStatus.ok) {
          result = response.bodyBytes.toList();

          DefaultCacheManager().putFile(url, response.bodyBytes).then((value) {
            print("cache download done:$url");
          });
        } else {}
      } on Exception catch (e, s) {
        print("download Exception: $e $s, url:$url");
      }
    } else {
      result = info.file.readAsBytesSync().toList();
    }

    return Future<List<int>>.value(result);
  }

  Future<List<int>> readFromAsset(String assetPath) async {
    List<int> result = kTransparentImage.toList();
    final FileInfo? info =
        await DefaultCacheManager().getFileFromCache(assetPath);
    if (info == null) {
      await loadAssetData(assetPath).then((bytesData) async {
        result = bytesData;

        DefaultCacheManager().putFile(assetPath, bytesData).then((value) {
          print("cache asset done:$assetPath");
        });
      });
    } else {
      result = info.file.readAsBytesSync().toList();
    }

    return Future<List<int>>.value(result);
  }

  Future<Uint8List> loadAssetData(String assetPath) async {
    ByteData assetData = await rootBundle.load(assetPath);
    Uint8List data = assetData.buffer.asUint8List();
    return data;
  }

  void cacheAllFiles(List<ZegoGiftItem> cacheList) {
    for (var itemData in cacheList) {
      debugPrint('${DateTime.now()} try cache ${itemData.sourceURL}');
      if (itemData.source != ZegoGiftSource.url) {
        continue;
      }
      cacheFile(itemData.sourceURL);
    }
  }

  void cacheFile(String url) {
    DefaultCacheManager().getSingleFile(url);
  }

  Future<String?> getFilePathFromCache(String url) async {
    final FileInfo? fileInfo =
        await DefaultCacheManager().getFileFromCache(url);
    return fileInfo?.file.path;
  }
}
