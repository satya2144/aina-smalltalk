import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';
import 'package:smalltalk/sip_library/call_service.dart';
import 'package:smalltalk/utils/commons/enums.dart';

import '../call_manager.dart';
import '../sip_call.dart';

class StateEmergencyCallIncoming extends StateBase {
  SIPCall _sipCall;

  StateEmergencyCallIncoming(CallContext context, CallManager callManager, this._sipCall)
      : super(context, callManager);

  @override
  Future<void> onStart() async {
      callManager.answer(_sipCall);
  }

  void onDestroy() {
  }

  void hangup() {
    callManager.hangup();
  }

  @override
  void onCallStateChanged(SIPCall sipCall) {
    if (sipCall.isEmergency()) {
      if (sipCall.getState() == CallStateEnum.FAILED ||
          sipCall.getState() == CallStateEnum.ENDED) {
        callContext.onEmergencyIncomingCallEnded();
      }
    }
  }

  void onEmergencyButtonPressed(EmergencyButtonEventEnum event) {
    callManager.sendDTMF(event);
  }
}
