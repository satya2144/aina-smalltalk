import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';

import '../call_manager.dart';
import '../call_service.dart';

class StateCallEnding extends StateBase {
  const StateCallEnding(CallContext context, CallManager callManager)
      : super(context, callManager);

  @override
  void onStart() {
    callContext.onIncomingCallEnded();
    callContext.goIdle();
  }

  void onDestroy() {
    callManager.hangup();
  }
}
