import 'dart:async';

import 'package:smalltalk/sip_library/sip_call.dart';

abstract class CallManagerListener {
  void onIncomingCall(SIPCall sipCall) {}

  void onPrivateOutgoingCallEnded() {}

  void onCallError() {}

}
