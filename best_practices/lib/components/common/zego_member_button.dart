import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';
import 'zego_apply_cohost_list_page.dart';

class ZegoMemberButton extends StatefulWidget {
  const ZegoMemberButton({super.key});

  @override
  State<ZegoMemberButton> createState() => _ZegoMemberButtonState();
}

class _ZegoMemberButtonState extends State<ZegoMemberButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          ApplyCoHostListView().showBasicModalBottomSheet(context);
        },
        child: Stack(
          children: [
            Container(
              width: 53,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xff1e2740).withOpacity(0.4),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(),
                  const SizedBox(width: 3),
                  memberCount(),
                ],
              ),
            ),
            redPoint(),
          ],
        ));
  }

  Widget icon() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }

  Widget redPoint() {
    return ValueListenableBuilder(
      valueListenable: ZEGOSDKManager.instance.zimService.roomRequestMapNoti,
      builder: (context, Map<String, dynamic> requestMap, _) {
        if (requestMap.isEmpty) {
          return Container();
        } else {
          return Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              width: 10,
              height: 10,
            ),
          );
        }
      },
    );
  }

  Widget memberCount() {
    return SizedBox(
      height: 28,
      child: Center(
        child: ValueListenableBuilder(
          valueListenable:
              ZEGOSDKManager.instance.zimService.roomRequestMapNoti,
          builder: (context, Map<String, dynamic> requestMap, _) {
            return Text(
              requestMap.values.toList().length.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            );
          },
        ),
      ),
    );
  }
}
