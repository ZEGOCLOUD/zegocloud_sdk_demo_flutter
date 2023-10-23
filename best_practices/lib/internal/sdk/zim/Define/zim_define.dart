
enum RoomRequestAction { 
  request,
  accept, 
  reject, 
  cancel
}

class RoomRequestResult {
  final String requestID;

  RoomRequestResult(this.requestID);

}