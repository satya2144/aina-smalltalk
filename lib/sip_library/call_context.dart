import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_engine_listener.dart';

import 'callStates/state_base.dart';

abstract class CallContext extends SipEngineListener {
  bool get isCallActive => false;

  // state changes
  void goIdle();
  void goRegistration();

  // call actions26|callContext|.|startIncomingCall|(|groupId|)|;	26|callContext|.|startIncomingCall|(|groupId|)|;	26|callContext|.|startIncomingCall|(|groupId|)|;	26|callContext|.|startIncomingCall|(|groupId|)|;
  void startCall(String groupId);
  Future<String> startOutgoingCall(String groupId);
  void endCallAction(String groupId);
  Future<String> startIncomingCall(String groupId, bool mute);
  void connect();

  void onPrivateIncomingCallConfirmed(String remoteDisplayName) {}

  void onPrivateIncomingCallEnded() {}

  void onPrivateOutgoingCallConfirmed() {}

  void onPrivateOutgoingCallEnded() {}

  void startPrivateCallIncoming(SIPCall sipCall) {}

  void startPrivateCallOutgoing(int userId) {}

  void onPrivateOutgoingCall() {}

  void startEmergencyCallOutgoing() {}
  void onEmergencyOutgoingCall() {}

  void onEmergencyOutgoingCallConfirmed() {}

  void onEmergencyOutgoingCallEnded() {}

  void onPrivateIncomingCall(SIPCall sipCall) {}

  void activateState(StateBase newState) {}

  void onPrivateOutgoingCallFailed() {}

  void onEmergencyIncomingCallEnded() {}

  void onFetchingContactList(List<UserContract> contactList) {}

  void onOutgoingCallStarted() {}

  void onNewIncomingGroupCall(String groupId, String fromName) {}

  void onStatusMessage(NewMessageModel newMessage) {}

  void onGroupChange(GroupChangeUserModel groupChangeUserModel) {}



}
