import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:oauth2/oauth2.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/sip_library/callStates/state_call_emergency_incoming.dart';
import 'package:smalltalk/sip_library/callStates/state_call_emergency_outgoing.dart';
import 'package:smalltalk/sip_library/callStates/state_call_private_incoming.dart';
import 'package:smalltalk/sip_library/callStates/state_call_private_outgoing.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_engine_listener.dart';
import 'package:smalltalk/sip_library/sip_repository.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:location/location.dart';

import 'callStates/state_base.dart';
import 'callStates/state_call_accepted.dart';
import 'callStates/state_call_incoming.dart';
import 'callStates/state_idle.dart';
import 'callStates/state_register.dart';
import 'call_context.dart';
import 'call_manager.dart';
import 'call_manager_listener.dart';
import 'call_service.dart';

class SipEngine
    implements SipRepositoryListener, CallContext, CallManagerListener {
  SIPRepository _sipCallRepository;
  bool isCallActive = false;
  StateBase _state;
  CallContext context;
  SipEngineListener _listener;
  String _server;
  var _userId;
  Credentials _authCred;
  String _pushToken;
  AppLifecycleState appState;
  CallManager _callManager;
  var _pushNotification;
  String _activeGroup;
  bool allowBackgroundCall = true;
  Timer locationTimer;
  Timer presenceTimer;
  Location location;
  CallService _callService;

  SipEngine(this._listener, this._sipCallRepository) {
    context = this;
    _callService = CallService();
    _state = StateRegister(context, _callManager);
    _callManager = new CallManager(this, _sipCallRepository, _callService);
    location = Location();
  }

// To-Do -- must be called again if token expires, not sure how to handle. Would not be ok to disconnect call. Maybe set a flag that token expired so when
// next time going to idle, we run reconnect
  start(String server, int userId, String pushToken) {
    _server = server;
    _userId = userId;
    _pushToken = pushToken;
    this.goRegistration();
  }

  connect() {
    _sipCallRepository.disconnect();
    _sipCallRepository.connect(_server, _userId, this);
  }

  void startGroupCall(String groupId) {
    isCallActive = true;
    activateState(StateCallAccepted(context, _callManager, groupId));
  }

  void startIncomingGroupCall(String groupId, String fromName) {
    activateState(StateCallIncoming(context, _callManager, fromName, groupId));
  }

  void stopGroupCall() {
    if (isCallActive) {
      isCallActive = false;
      onOutgoingCallEnded();
      goIdle();
    }
    // _state.endCall();
  }

  void startPrivateCall(int userId) {
    startPrivateCallOutgoing(userId);
  }

  void startEmergencyCall() {
    startEmergencyCallOutgoing();
  }

  void activateState(StateBase newState) {
    _state.onDestroy();
    _state = newState;
    _state.onStart();
    onStateActivated(_state.runtimeType.toString());
  }

  void registerPushToken(String pushToken, int pushTokenExpires) {
    //Line is commented to run in simulator
    _sipCallRepository.registerPushToken(pushToken, pushTokenExpires);
  }

  void sendPresenceMessage() {
    _sipCallRepository.sendPresenceMessage();
  }

  Future<void> sendLocation() async {
    LocationData _locationData;
    if (await location.hasPermission() != PermissionStatus.granted) {
      return;
    }
    _locationData = await location.getLocation();
    if (_locationData != null) {
      _sipCallRepository.sendLocation(
          _locationData.latitude, _locationData.longitude);
    }
  }

  @override
  void callStateChanged(SIPCall sipCall) {
    _callManager.callStateChanged(sipCall);
    _state.onCallStateChanged(sipCall);
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    NewMessageModel newMessage =
        NewMessageModel.fromJson(json.decode(msg.request.body));
    _state.onNewMessage(newMessage);
  }

  @override
  void registrationStateChanged(RegistrationState registrationState) {
    _state.onRegistrationStateChanged(registrationState, context);
  }

  @override
  void transportStateChanged(TransportState transportState) {
    _state.onTransportStateChanged(transportState);
  }

  // CallContext starts here
  @override
  void goIdle() {
    activateState(StateIdle(
        context, _callManager, allowBackgroundCall ? _activeGroup : null));
    _listener.onIdleActivated();
  }

  @override
  void goRegistration() {
    activateState(StateRegister(context, _callManager));
  }

  @override
  Future<String> startOutgoingCall(String groupId) async {
    try {
      return await _callManager.startOutgoingCall(groupId);
    } catch (e) {
      _listener.onOutgoingCallFailed();
    }
  }

  @override
  Future<String> startIncomingCall(String groupId, bool mute) async {
    try {
      return await _callManager.startIncomingCall(groupId, mute);
    } catch (e) {
      _listener.onIncomingCallFailed();
    }
  }

  @override
  void startCall(String groupId) {
    _sipCallRepository.sendCallingMessage(groupId);
  }

  @override
  void endCallAction(String groupId) {
    _sipCallRepository.sendEndingMessage(groupId);
  }

  void statusMessageReply(String messageId, String message) {
    _sipCallRepository.statusMessageReply(messageId, message);
  }

  void sendCallRequest() {
    _sipCallRepository.sendCallRequest();
  }

  // listener
  @override
  void onOutgoingCallConfirmed() {
    _callManager.sendDTMF(EmergencyButtonEventEnum.PRESSED);
    _callManager.callMute(false);
    _listener.onOutgoingCallConfirmed();
  }

  @override
  void onRegistrationSuccesful() {
    if (_pushNotification != null) {
      _pushNotification = null;
      activateState(StateCallIncoming(context, _callManager,
          _pushNotification["fromName"], _pushNotification["groupId"]));
    } else {
      goIdle();
    }
    registerPushToken(_pushToken, GlobalConstants.pushTokenExpires);
    _listener.onRegistrationSuccesful();
  }

  @override
  void onRegistrationFailed() {
    this.locationTimer?.cancel();
    this.presenceTimer?.cancel();
    _listener.onRegistrationFailed();
  }

  @override
  void onRegistrationExpired() {
    this.locationTimer?.cancel();
    this.presenceTimer?.cancel();
    goRegistration();
    _listener.onRegistrationExpired();
  }

  @override
  void onOutgoingCallEnded() {
    _callManager.hangup();
    _listener.onOutgoingCallEnded();
  }

  @override
  void onIncomingCallEnded() {
    _listener.onIncomingCallEnded();
  }

  @override
  void onIncomingCallStarted(String fromName, String fromGroup) {
    _listener.onIncomingCallStarted(fromName, fromGroup);
  }

  @override
  void onStateActivated(String stateName) {
    _listener.onStateActivated(stateName);
  }

  @override
  void onIdleActivated() {
    // TODO: implement onIdleActivated
  }

  @override
  void onIncomingCallFailed() {
    goIdle();
    _listener.onIncomingCallFailed();
  }

  @override
  void onOutgoingCallFailed() {
    goIdle();
    _listener.onOutgoingCallFailed();
  }

  getCurrentState() {
    return _state;
  }

  void startBackgroundCall() {
    goIdle();
  }

  void setActiveGroup(String groupKey) {
    _activeGroup = groupKey;
  }

  getActiveCall() {
    return _callManager.activeCallId;
  }

  void stopEngine() {
    sendGroupChange(new List());
    _sipCallRepository.registerPushToken(_pushToken, 0);
    _sipCallRepository.unRegister();
    _callManager.dropCalls();
  }

  void setCallFromPushNotification(String groupId, String fromName) {
    _pushNotification = new Map();
    _pushNotification["groupId"] = groupId;
    _pushNotification["fromName"] = fromName;
  }

  @override
  void onPrivateIncomingCallConfirmed(String remoteDisplayName) {
    _listener.onPrivateIncomingCallConfirmed(remoteDisplayName);
  }

  @override
  void onPrivateIncomingCall(SIPCall sipCall) {
    _listener.onPrivateIncomingCall(sipCall);
  }

  void onEmergencyIncomingCall(SIPCall sipCall) {
    _listener.onEmergencyIncomingCall(sipCall);
  }

  @override
  void onPrivateIncomingCallEnded() {
    _listener.onPrivateIncomingCallEnded();
    goIdle();
  }

  @override
  void onPrivateOutgoingCall() {
    _listener.onPrivateOutgoingCall();
  }

  @override
  void onPrivateOutgoingCallConfirmed() {
    _listener.onPrivateOutgoingCallConfirmed();
  }

  @override
  void onPrivateOutgoingCallEnded() {
    _listener.onPrivateOutgoingCallEnded();
    goIdle();
  }

  @override
  void onPrivateOutgoingCallFailed() {
    _listener.onPrivateOutgoingCallFailed();
    goIdle();
  }

  @override
  void startPrivateCallIncoming(SIPCall sipCall) {
    activateState(StatePrivateCallIncoming(context, _callManager, sipCall));
  }

  void startEmergencyCallIncoming(SIPCall sipCall) async {
    activateState(StateEmergencyCallIncoming(context, _callManager, sipCall));
  }

  @override
  void startPrivateCallOutgoing(int userId) async {
    activateState(StatePrivateCallOutgoing(context, _callManager, userId));
  }

  void hangup() {
    _state.hangup();
  }

  void answerPrivateCall(SIPCall sipCall) {
    //To-Do remove after refactoring home screen
    onPrivateIncomingCallConfirmed(sipCall.getRemoteDisplayName());
    startPrivateCallIncoming(sipCall);
  }

  void answerEmergencyeCall(SIPCall sipCall) {
    onEmergencyIncomingCallConfirmed(sipCall.getRemoteDisplayName());
    startEmergencyCallIncoming(sipCall);
  }

  @override
  void startEmergencyCallOutgoing() {
    activateState(StateEmergencyCallOutgoing(context, _callManager));
  }

  @override
  void onEmergencyOutgoingCall() {
    _listener.onEmergencyOutgoingCall();
  }

  @override
  void onEmergencyOutgoingCallConfirmed() {
    _listener.onEmergencyOutgoingCallConfirmed();
  }

  @override
  void onEmergencyOutgoingCallEnded() {
    _listener.onEmergencyOutgoingCallEnded();
    goIdle();
  }

  void reject(SIPCall sipCall) {
    _state.rejectCall(sipCall);
  }

  void onEmergencyIncomingCallConfirmed(String remoteDisplayName) {
    _listener.onEmergencyIncomingCallConfirmed(remoteDisplayName);
  }

  @override
  void onEmergencyIncomingCallEnded() {
    _listener.onEmergencyIncomingCallEnded();
    goIdle();
  }

  @override
  void onNewIncomingGroupCall(String groupId, String fromName) {
    _listener.onNewIncomingGroupCall(groupId, fromName);
  }

  @override
  void onIncomingCall(SIPCall sipCall) {
    if (sipCall.isPrivate()) {
      onPrivateIncomingCall(sipCall);
    } else {
      onEmergencyIncomingCall(sipCall);
    }
  }

  void onEmergencyButtonPressed(EmergencyButtonEventEnum event) {
    _state.onEmergencyButtonPressed(event);
  }

  @override
  void onFetchingContactList(List<UserContract> contactList) {
    _listener.onFetchingContactList(contactList);
  }

  @override
  void onStatusMessage(NewMessageModel newMessage) {
    _listener.onStatusMessage(newMessage);
  }

  void isBTDeviceConnected(bool bool) {
    _callManager.isBTDeviceConnected(bool);
  }

  @override
  void onOutgoingCallStarted() {
    _listener.onOutgoingCallStarted();
  }

  void activateBackground(bool allowbg) {
    this.allowBackgroundCall = allowbg;
    if (!allowbg) {
      stopEngine();
      return;
    }
    if (_state is StateIdle) {
      goIdle();
    }
  }

  void activateForeground() {
    if (!this.allowBackgroundCall) {
      this.allowBackgroundCall = true;
      goRegistration();
      return;
    }
    this.allowBackgroundCall = true;
    if (_state is StateIdle) {
      goIdle();
    }
  }

  @override
  void onCallError() {
    goIdle();
  }

  void sendGroupChange(List groupList) {
    _sipCallRepository.onGroupChange(groupList.toString());
  }

  @override
  void onGroupChange(GroupChangeUserModel groupChangeUserModel) {
    _listener.onGroupChange(groupChangeUserModel);
  }

  void startSharingLocation() {
    sendLocation();
    this.locationTimer = Timer.periodic(
        Duration(seconds: GlobalConstants.locationUpdateTimer), (timer) {
      sendLocation();
    });
  }

  void startPresenceMessage() {
    sendPresenceMessage();
    this.presenceTimer = Timer.periodic(
        Duration(seconds: GlobalConstants.presenceTimer), (timer) {
      sendPresenceMessage();
    });
  }
}
