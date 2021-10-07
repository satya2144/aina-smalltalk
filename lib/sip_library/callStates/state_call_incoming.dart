import 'dart:async';

import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_base.dart';
import 'package:smalltalk/sip_library/call_context.dart';
import 'package:smalltalk/sip_library/call_service.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

import '../call_manager.dart';
import '../sip_call.dart';

class StateCallIncoming extends StateBase {
  Logger logger = Logger();
  SIPCall _sipCall;
  Timer _timer;
  bool _incomingCallFailed = false;
  String groupId;
  String fromName;
  StateCallIncoming(CallContext context, CallManager callManager,
      String fromName, String groupId)
      : super(context, callManager) {
    this.groupId = groupId;
    this.fromName = fromName;
  }

  @override
  void onStart() async {
      startIncomingCall(groupId, false);
  }

  void startTimer() {
    _timer?.cancel();
    _timer = new Timer(
        Duration(seconds: GlobalConstants.callIncomingHangoutSeconds),
        handleTimeout);
  }

  void handleTimeout() {
    logger
        .d("Call Disconnected => Not Recieved Call- from server in 15 seconds");
    onIncomingCallFailed();
  }

  void onIncomingCallFailed() {
    _incomingCallFailed = true;
    callContext.onIncomingCallFailed();
  }

  @override
  void onCallStateChanged(SIPCall sipCall) {
    _sipCall = sipCall;
    if (sipCall.getState() == CallStateEnum.CONFIRMED) {}
    if (sipCall.getState() == CallStateEnum.FAILED) {
      onIncomingCallFailed();
    }
  }

  @override
  void onHeartbeat(String groupID) {
    if (this.groupId == groupID) {
      startTimer();
    } else {
      logger.d("Call Incoming HeartBeat to wrong groupID ");
    }
  }

  void onDestroy() {
    callManager.dropCalls();
    _timer?.cancel();
  }

  void onNewMessage(NewMessageModel newMessage) {
    switch (newMessage.action) {
      case StringConstants.callIncoming:
        {
          if (this.groupId == newMessage.groupId) {
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

  void startIncomingCall(String groupId, bool mute) {
    callContext.startIncomingCall(groupId, mute);
    startTimer();
    callContext.onIncomingCallStarted(fromName, groupId);
  }
}
