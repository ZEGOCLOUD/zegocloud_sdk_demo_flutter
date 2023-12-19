import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../zego_sdk_manager.dart';

class RoomRequestListView {
  static Future<void> showBasicModalBottomSheet(context) async {
    final zimService = ZEGOSDKManager().zimService;
    showModalBottomSheet(
      isScrollControlled: false,
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder(
          valueListenable: zimService.roomRequestMapNoti,
          builder: (context, Map<String, RoomRequest> requestMap, _) {
            final requestList = requestMap.values.toList();

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 5),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Text('Request List:', style: Theme.of(context).textTheme.titleMedium)]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: requestMap.values.toList().length,
                      itemBuilder: (BuildContext context, int index) {
                        final roomRequest = requestList[index];
                        final itemUserInfo = ZEGOSDKManager().getUser(roomRequest.senderID);
                        final child = Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: SizedBox()),
                            ElevatedButton(
                              style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.lightGreen)),
                              onPressed: () {
                                zimService.acceptRoomRequest(roomRequest.requestID ?? '').then((value) {
                                  Navigator.pop(context);
                                }).catchError((error) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text('Agree failed: $error .')));
                                });
                              },
                              child: const Icon(Icons.check_outlined),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent)),
                              onPressed: () {
                                zimService.rejectRoomRequest(roomRequest.requestID ?? '').then((value) {
                                  Navigator.pop(context);
                                }).catchError((error) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text('DisAgree failed: $error .')));
                                });
                              },
                              child: const Icon(Icons.close_outlined),
                            ),
                          ],
                        );

                        return itemUserInfo == null
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                Expanded(
                                  child: Row(children: [
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: ${roomRequest.senderID}'),
                                      ],
                                    )
                                  ]),
                                ),
                                Expanded(child: child)
                              ])
                            : ValueListenableBuilder(
                                valueListenable: itemUserInfo.avatarUrlNotifier,
                                builder: (BuildContext context, String? avatarUrl, Widget? child) {
                                  final avatar = avatarUrl?.isNotEmpty ?? false
                                      ? CachedNetworkImage(
                                          width: 50,
                                          height: 50,
                                          imageUrl: avatarUrl!,
                                          fit: BoxFit.cover,
                                          progressIndicatorBuilder: (context, url, _) =>
                                              const CupertinoActivityIndicator(),
                                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                                        )
                                      : const SizedBox.shrink();
                                  return Row(mainAxisSize: MainAxisSize.min, children: [
                                    Expanded(
                                      child: Row(children: [
                                        avatar,
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(itemUserInfo.userName, maxLines: 1, overflow: TextOverflow.fade),
                                            Text('ID: ${roomRequest.senderID}'),
                                          ],
                                        )
                                      ]),
                                    ),
                                    Expanded(child: child!)
                                  ]);
                                },
                                child: child,
                              );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
