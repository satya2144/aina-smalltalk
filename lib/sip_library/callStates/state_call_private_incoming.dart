import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';

import '../call_manager.dart';
import '../call_service.dart';
import '../sip_call.dart';

class StatePrivateCallIncoming extends StateBase {
  SIPCall _sipCall;

  StatePrivateCallIncoming(CallContext context, CallManager callManager,this._sipCall)
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
    if (sipCall.isPrivate()) {
      if (sipCall.getState() == CallStateEnum.FAILED ||
          sipCall.getState() == CallStateEnum.ENDED) {
        callContext.onPrivateIncomingCallEnded();
      }
    }
  }
}
