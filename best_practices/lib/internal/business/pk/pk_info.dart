import '../../sdk/utils/flutter_extension.dart';
import 'pk_user.dart';

class PKInfo {
  String? requestID;
  ListNotifier<PKUser> pkUserList = ListNotifier(<PKUser>[]);
}
