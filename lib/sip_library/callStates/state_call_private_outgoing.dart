import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';

import '../call_manager.dart';
import '../call_service.dart';
import '../sip_call.dart';

class StatePrivateCallOutgoing extends StateBase {
  SIPCall _sipCall;
  int userId;

  StatePrivateCallOutgoing(
      CallContext context, CallManager callManager, this.userId)
      : super(context, callManager);

  @override
  Future<void> onStart() async {
    callContext.onPrivateOutgoingCall();
    callManager.startPrivateCall(userId);
  }

  void onDestroy() {}

  void hangup() {
    callManager.hangup();
  }

  @override
  void onCallStateChanged(SIPCall sipCall) {
    _sipCall = sipCall;
    if (_sipCall.isPrivate()) {
      if (sipCall.getState() == CallStateEnum.ACCEPTED) {
        callContext.onPrivateOutgoingCallConfirmed();
      } else if (sipCall.getState() == CallStateEnum.ENDED) {
        callContext.onPrivateOutgoingCallEnded();
      } else if (sipCall.getState() == CallStateEnum.FAILED) {
        callContext.onPrivateOutgoingCallFailed();
      }
    }
  }
}
