import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';

import '../call_manager.dart';
import '../call_service.dart';
import '../sip_call.dart';

class StateIdle extends StateBase {
  String _groupId;
  StateIdle(CallContext context, CallManager callManager, String groupId)
      : super(context, callManager) {
    this._groupId = groupId;
  }

  String _activeCallId;

  @override
  Future<void> onStart() async {
    if (_groupId == null) {
      callManager.dropCalls();
    } else {
      this._activeCallId =
          await this.callContext.startIncomingCall(_groupId, true);
    }
  }

  @override
  void onDestroy() {}


  @override
  void onCallStateChanged(SIPCall sipCall) {
    if (sipCall.isIncoming() &&
        (sipCall.getState() == CallStateEnum.FAILED ||
            sipCall.getState() == CallStateEnum.ENDED)) {
      callContext.onPrivateIncomingCallEnded();
    } else if ((sipCall.getState() == CallStateEnum.FAILED ||
        sipCall.getState() == CallStateEnum.ENDED)) {
      if (sipCall.getID() == this._activeCallId) {
        this.onStart();
      }
    }
  }
}
