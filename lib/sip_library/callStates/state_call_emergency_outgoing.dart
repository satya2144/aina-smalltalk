import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';
import 'package:smalltalk/sip_library/call_service.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

import '../call_manager.dart';
import '../sip_call.dart';

class StateEmergencyCallOutgoing extends StateBase {
  SIPCall _sipCall;

  StateEmergencyCallOutgoing(
      CallContext context, CallManager callManager)
      : super(context, callManager);

  @override
  void onStart() {
      callContext.onEmergencyOutgoingCall();
      callManager.startEmergencyCall();
  }

  void onDestroy() {
  }

  void hangup() {
    callManager.hangup();
  }

  @override
  void onCallStateChanged(SIPCall sipCall) {
    _sipCall = sipCall;
    if (sipCall.isEmergency()) {
      if (sipCall.getState() == CallStateEnum.CONFIRMED) {
        callContext.onEmergencyOutgoingCallConfirmed();
      }
      if (sipCall.getState() == CallStateEnum.FAILED ||
          sipCall.getState() == CallStateEnum.ENDED) {
        callContext.onEmergencyOutgoingCallEnded();
      }
    }
  }
}
