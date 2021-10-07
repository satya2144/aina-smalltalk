import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';

import '../call_manager.dart';
import '../call_service.dart';

class StateRegister extends StateBase {
  StateRegister(
      CallContext context, CallManager callManager)
      : super(context, callManager );
  Logger logger = Logger();
  int _counter = 0;

  void onDestroy() {}

  @override
  void onStart() {
    callContext.connect();
  }

  @override
  void onRegistrationStateChanged(
      RegistrationState registrationState, CallContext callContext) {
    if (registrationState.state == RegistrationStateEnum.REGISTERED) {
      callContext.onRegistrationSuccesful();
    } else if (registrationState.state ==
        RegistrationStateEnum.REGISTRATION_FAILED) {
      callContext.onRegistrationFailed();
      var delay = _counter;
      _counter = _counter + 1;
      delay = delay > 0 ? delay + 4 : 0;
      delay = delay > 120 ? 120 : delay;
      logger.d("Registration Failed => Reconnection Attempt in $delay seconds");
      new Future.delayed(Duration(seconds: delay), () => callContext.connect());
    } else {
      _counter = 0;
      callContext.onRegistrationExpired();
    }
  }
}
