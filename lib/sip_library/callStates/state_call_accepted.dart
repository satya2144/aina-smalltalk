import 'dart:async';

import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';
import 'package:smalltalk/sip_library/call_manager.dart';
import 'package:smalltalk/sip_library/call_service.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

import '../sip_call.dart';

class StateCallAccepted extends StateBase {
  Logger logger = Logger();
  Timer _timerAction;
  Timer _timerHeartbeat;
  SIPCall _sipCall;
  String groupId;
  bool isCallActive = false;
  bool _outgoingCallFailed = false;
  StateCallAccepted(CallContext context, CallManager callManager, this.groupId)
      : super(context, callManager) {}

  void startTimerAction() {
    _timerAction?.cancel();
    _timerHeartbeat?.cancel();
    _timerAction = new Timer(
        Duration(seconds: GlobalConstants.callingHandleTimeoutSeconds),
        handleCall);
    startTimerHeartbeat();
  }

  void startTimerHeartbeat() {
    _timerHeartbeat?.cancel();
    _timerHeartbeat = new Timer(
        Duration(seconds: GlobalConstants.callAcceptedHangoutSeconds),
        handleTimeout);
  }

  void handleTimeout() {
    logger.d(
        "Call Disconnected => Not Recieved Call-Accepted from server in 15 seconds");
    onOutgoingCallFailed();
  }

  void onOutgoingCallFailed() {
    _outgoingCallFailed = true;
    callContext.onOutgoingCallFailed();
  }

  void handleCall() {
    callContext.startCall(this.groupId);
  }

  @override
  void onHeartbeat(String groupID) {
    if (this.groupId == groupId) {
      _timerHeartbeat?.cancel();
      startTimerAction();
    } else {
      logger.d("Call Outgoing HeartBeat to wrong groupID ");
    }
  }

  @override
  void onStart() {
    callContext.startCall(groupId);
  }

  void onCallAccepted(String groupId) {
    if(this.groupId != groupId){
      return;
    }
    if (callContext.isCallActive) {
      _sipCall?.hangup();
      callContext.startOutgoingCall(this.groupId);
      callContext.onOutgoingCallStarted();
      startTimerAction();
    } else {
      callContext.goIdle();
    }
  }


  @override
  void onCallStateChanged(SIPCall sipCall) {
    _sipCall = sipCall;
    if (sipCall.getState() == CallStateEnum.STREAM) {
      callContext.onOutgoingCallConfirmed();
    }
    if (sipCall.getState() == CallStateEnum.FAILED) {
      onOutgoingCallFailed();
    }
  }

  void onDestroy() {
    _timerAction?.cancel();
    _timerHeartbeat?.cancel();
    isCallActive= false;
    callContext.endCallAction(this.groupId);
    callManager.dropCalls();
  }

  void onNewMessage(NewMessageModel newMessage) {
    switch (newMessage.action) {
      case StringConstants.callAccepted:
        {
          if(!isCallActive){
            isCallActive = true;
            onCallAccepted(newMessage.groupId);
          }
          else{
            onHeartbeat(newMessage.groupId);
          }
        }
        break;
      default:
        {
          super.onNewMessage(newMessage);
        }
        break;
    }
  }
}
