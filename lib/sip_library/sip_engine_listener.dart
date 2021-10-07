import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/sip_call.dart';

abstract class SipEngineListener {
  // call events
  void onOutgoingCallConfirmed();
  void onRegistrationSuccesful();
  void onRegistrationFailed();
  void onRegistrationExpired();
  void onOutgoingCallEnded();
  void onIncomingCallEnded();
  void onIncomingCallStarted(String fromName, String fromGroup);
  void onIdleActivated();
  void onOutgoingCallFailed();
  void onIncomingCallFailed();

  // debug!!
  void onStateActivated(String stateName) {}

  void onPrivateIncomingCall(SIPCall sipCall) {}

  void onPrivateIncomingCallConfirmed(String remoteDisplayName) {}

  void onPrivateIncomingCallEnded() {}

  void onPrivateOutgoingCall() {}

  void onPrivateOutgoingCallConfirmed() {}

  void onPrivateOutgoingCallEnded() {}

  void onPrivateOutgoingCallFailed() {}

  void onEmergencyOutgoingCall() {}

  void onEmergencyOutgoingCallConfirmed() {}

  void onEmergencyOutgoingCallEnded() {}

  void onEmergencyIncomingCall(SIPCall sipCall) {}

  void onEmergencyIncomingCallConfirmed(String remoteDisplayName) {}

  void onEmergencyIncomingCallEnded() {}

  void onFetchingContactList(List<UserContract> contactList) {}

  void onOutgoingCallStarted() {}

  void onNewIncomingGroupCall(String groupId, String fromName) {}

  void onStatusMessage(NewMessageModel newMessage) {}

  void onGroupChange(GroupChangeUserModel groupChangeUserModel) {}
}
