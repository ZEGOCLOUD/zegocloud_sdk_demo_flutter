import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';
import 'zego_apply_cohost_list_page.dart';

class CoHostRequestListButton extends StatelessWidget {
  const CoHostRequestListButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ApplyCoHostListView().showBasicModalBottomSheet(context),
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: ZEGOSDKManager.instance.zimService.roomRequestMapNoti,
            builder: (context, Map<String, dynamic> requestMap, _) {
              return Badge(
                smallSize: 8,
                isLabelVisible: requestMap.isNotEmpty,
                child: Container(
                  width: 53,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e2740).withOpacity(0.4),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        requestMap.values.toList().length.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
