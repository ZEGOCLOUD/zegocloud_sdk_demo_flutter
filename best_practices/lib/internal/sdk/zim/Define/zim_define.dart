enum RoomRequestAction { request, accept, reject, cancel }

class RoomRequestResult {
  final String requestID;

  RoomRequestResult(this.requestID);
}

class RoomAttributesUpdatedEvent {
  final List<Map<String, String>> setProperties;
  final List<Map<String, String>> deleteProperties;
  RoomAttributesUpdatedEvent(this.setProperties, this.deleteProperties);

  @override
  String toString() {
    return 'RoomAttributesUpdatedEvent{setProperties: $setProperties deleteProperties:$deleteProperties}';
  }
}
