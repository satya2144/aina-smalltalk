import 'dart:convert';

import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_call_ending.dart';
import 'package:smalltalk/sip_library/call_context.dart';
import 'package:smalltalk/sip_library/call_manager.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

import '../sip_call.dart';
import '../sip_engine.dart';

abstract class StateBase {
  final CallContext callContext;
  final CallManager callManager;
  const StateBase(this.callContext, this.callManager);

  void onDestroy();
  void onStart();
  void onHeartbeat(String groupID) {}
  void startOutgoingCall(String groupId) {}

  void onCallStateChanged(SIPCall sipCall) {}

  void onRegistrationStateChanged(
      RegistrationState registrationState, CallContext callContext) {
    if (registrationState.state == RegistrationStateEnum.REGISTERED) {
      callContext.onRegistrationSuccesful();
    } else if (registrationState.state ==
        RegistrationStateEnum.REGISTRATION_FAILED) {
      callContext.onRegistrationFailed();
    } else {
      callContext.onRegistrationExpired();
    }
  }

  void onTransportStateChanged(TransportState transportState) {}

  void onNewMessage(NewMessageModel newMessage) {
    switch (newMessage.action) {
      case StringConstants.callAccepted:
        {}
        break;
      case StringConstants.callEnding:
        {
          callContext.activateState(StateCallEnding(callContext, callManager));
        }
        break;
      case StringConstants.callEnded:
        {}
        break;
      case StringConstants.callIncoming:
        {
          callContext.onNewIncomingGroupCall(
              newMessage.groupId, newMessage.fromName);
        }
        break;
      case StringConstants.presence:
        {
          callContext.onFetchingContactList(newMessage.contactList);
        }
        break;
      case StringConstants.statusMessage:
        {
          callContext.onStatusMessage(newMessage);
        }
        break;
      case StringConstants.groupChange:
        {
          callContext.onGroupChange(new GroupChangeUserModel(
              name: newMessage.name,
              lastActive: newMessage.lastActive,
              listened: newMessage.listened,
              userId: newMessage.userId));
        }
        break;
    }
  }

  void hangup() {}

  void rejectCall(SIPCall sipCall) {
    callManager.reject(sipCall);
  }

  void onEmergencyButtonPressed(EmergencyButtonEventEnum event) {}
}
