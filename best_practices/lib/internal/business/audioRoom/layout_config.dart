class ZegoLiveAudioRoomLayoutConfig {
  ZegoLiveAudioRoomLayoutConfig({
    this.rowSpacing = 0,
    List<ZegoLiveAudioRoomLayoutRowConfig>? rowConfigs,
  }) : rowConfigs = rowConfigs ??
            [
              ZegoLiveAudioRoomLayoutRowConfig(),
              ZegoLiveAudioRoomLayoutRowConfig(),
            ];

  int rowSpacing;
  List<ZegoLiveAudioRoomLayoutRowConfig> rowConfigs;

  @override
  String toString() {
    return 'spacing:$rowSpacing, row configs:${rowConfigs.map((e) => e.toString()).toList()}';
  }
}

class ZegoLiveAudioRoomLayoutRowConfig {
  ZegoLiveAudioRoomLayoutRowConfig({
    this.count = 4,
    this.seatSpacing = 0,
  });
  // Number of seats in each row. Range is [1~4], default value is 4.
  int count;

  /// The horizontal spacing between each seat. It should be set to a value equal to or greater than 0.
  int seatSpacing = 0;

  /// @nodoc
  @override
  String toString() {
    return 'row config:{count:$count, spacing:$seatSpacing}';
  }
}
