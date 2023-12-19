import 'package:flutter/material.dart';

import '../../zego_sdk_manager.dart';
import 'common_button.dart';
import 'zego_apply_cohost_list_page.dart';

class CoHostRequestListButton extends StatelessWidget {
  const CoHostRequestListButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ZEGOSDKManager().zimService.roomRequestMapNoti,
      builder: (context, Map<String, dynamic> requestMap, _) {
        return Badge(
          smallSize: 8,
          isLabelVisible: requestMap.isNotEmpty,
          child: CommonButton(
            onTap: () => RoomRequestListView.showBasicModalBottomSheet(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('CoHost request:'),
                const SizedBox(width: 3),
                Text(requestMap.values.toList().length.toString()),
              ],
            ),
          ),
        );
      },
    );
  }
}
