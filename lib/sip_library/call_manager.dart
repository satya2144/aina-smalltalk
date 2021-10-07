import 'dart:async';

import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/call_manager_listener.dart';
import 'package:smalltalk/sip_library/call_service.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_repository.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

class CallManager implements CallManagerListener {
  CallManagerListener _listener;
  SIPCall _activeCall;
  String _expectedCall;
  String activeCallId;
  SIPRepository _repo;
  Map<String, SIPCall> calls = new Map();
  Logger logger = Logger();
  int retryCounter = 0;
  SIPCall _incomingCall;
  bool isBTDevice = false;
  CallService _callService;

  CallManager(this._listener, this._repo, this._callService) {}

  bool isActiveCall(String callId) {
    return callId == activeCallId;
  }

  bool isCallEnded(CallStateEnum state) {
    return state == CallStateEnum.ENDED || state == CallStateEnum.FAILED;
  }

  bool canHangupCall(CallStateEnum state) {
    return state == CallStateEnum.CONFIRMED ||
        state == CallStateEnum.ACCEPTED ||
        state == CallStateEnum.CONNECTING;
  }

  Future<String> startCall(String identity) async {
    _expectedCall = identity;
    retryCounter = 0;
    String callID = await _repo.startCall(_expectedCall);
    activeCallId = callID;
    return callID;
  }

  Future<String> startOutgoingCall(String groupId) async {
    if (isSameCall(groupId) && isAlive(_activeCall.getState())) {
    } else {
      hangup(true);
    }
    _callService.emulateOutgoingCall().then((value) async {
      if (isSameCall(groupId) && isAlive(_activeCall.getState())) {
        sendDTMF(EmergencyButtonEventEnum.PRESSED);
        callMute(false);
      } else {
        return await startCall(StringConstants.incomingCallPrefix + groupId);
      }
    }).catchError((error) {
      onCallError();
    });
  }

  void startPrivateCall(int id) {
    hangup(true);
    _callService.emulateOutgoingCall().then((value) async {
      startCall(StringConstants.privateCallPrefix + id.toString());
    }).catchError((error) {
      onCallError();
    });
  }

  void startEmergencyCall() {
    hangup(true);
    _callService.emulateOutgoingCall().then((value) async {
      startCall(StringConstants.emergencyCallPrefix);
    }).catchError((error) {
      onCallError();
    });
  }

  Future<String> startIncomingCall(String groupId, bool mute) async {
    if (isSameCall(groupId) && isAlive(_activeCall.getState())) {
    } else {
      hangup(true);
    }
    if (!mute) {
      _callService.emulateOutgoingCall().then((value) async {
        if (isSameCall(groupId) && isAlive(_activeCall.getState())) {
          callMute(mute);
        } else {
          return await startCall(StringConstants.incomingCallPrefix + groupId);
        }
      }).
      catchError((error) {
        onCallError();
      });
    } else {
      if (isSameCall(groupId) && isAlive(_activeCall.getState())) {
        callMute(mute);
      } else {
        return await startCall(StringConstants.incomingCallPrefix + groupId);
      }
    }
  }

  void hangup([bool force = false]) async {
    _callService.hangup();
    if (!force && (this._activeCall?.isGroupCall() ?? false)) {
      sendDTMF(EmergencyButtonEventEnum.RELEASED);
      callMute(true);
      return;
    }
    _expectedCall = null;
    activeCallId = null;
    if (_activeCall == null) {
      logger.d("hangup called but no calls");
    } else {
      logger.d("Hangup call {" +
          _activeCall.getRemoteIdentity() +
          "} : {" +
          _activeCall.getID() +
          "}");
      _activeCall?.hangup();
      calls?.remove(_activeCall?.getID());
      _activeCall = null;
      this.disposeCalls();
    }
  }

  void setCall(SIPCall sipCall) {
    this.disposeCalls();
    logger.d("saving call from :  {" +
        sipCall.getRemoteIdentity() +
        "} : {" +
        sipCall.getID() +
        "}");
    calls[sipCall.getID()] = sipCall;
    _activeCall = sipCall;
  }

  void disposeCalls() {
    calls.forEach((key, value) {
      if (!this.isActiveCall(key)) {
        if (canHangupCall(value.getState())) {
          calls.remove(key);
          value?.hangup();
        }
      }
    });
  }

  void callStateChanged(SIPCall sipCall) {
    if (sipCall.isIncoming() && sipCall.isRinging()) {
      //check priority first
      if ((_activeCall?.getPriority() ?? -1) < sipCall.getPriority()) {
        // if there is no private/emergency call ringing
        if (this._incomingCall == null) {
          this._incomingCall = sipCall;
          _listener.onIncomingCall(sipCall);
        }
        //if there is an already private call ringing and emergency call comes
        else if (this._incomingCall.getPriority() < sipCall.getPriority()) {
          this._incomingCall.hangup();
          onPrivateOutgoingCallEnded();
          this._incomingCall = sipCall;
          _listener.onIncomingCall(sipCall);
        }
        //if there is an already private call ringing and another private call comes
        else {
          if (!this._incomingCall?.isSameCall(sipCall)) {
            reject(sipCall);
          }
        }
      } else {
        if (!this._incomingCall?.isSameCall(sipCall)) {
          reject(sipCall);
        }
      }
    }

    if (!sipCall.isRinging()) {
      this._incomingCall = null;
    }

    // remove ended/failed calls from dict
    if (isCallEnded(sipCall.getState())) {
      calls.remove(sipCall.getID());
    } else {
      if (!this.isActiveCall(sipCall.getID())) {
        if (canHangupCall(sipCall.getState())) {
          sipCall.hangup();
          calls.remove(sipCall.getID());
        }
      } else {
        if(isBTDevice){
          sipCall.disableSpeaker();
        }else{
          sipCall.enableSpeaker();
        }
        setCall(sipCall);
      }
    }

    // // // call again if dropped for some reason
    // if (expectedCall != null && calls.isEmpty) {
    //   // retry mechanism??
    //   if (retryCounter < 6) {
    //     retryCounter++;
    //     startCall(expectedCall);
    //   }
    // }
  }

  void answer(SIPCall sipCall) {
    hangup(true);
    _callService.emulateOutgoingCall().then((value) async {
      this.activeCallId = sipCall.getID();
      this._expectedCall = sipCall.getRemoteIdentity();
      setCall(sipCall);
      _repo.answer(sipCall);
    }).catchError((error) {
      onCallError();
    });
  }

  void reject(SIPCall sipCall) {
    sipCall.hangup();
  }

  @override
  void onIncomingCall(SIPCall sipCall) {
    _listener.onIncomingCall(sipCall);
  }

  void sendDTMF(EmergencyButtonEventEnum event) {
    if (this._activeCall != null) {
      this._activeCall.sendDTMF(event);
    }
  }

  void callMute(bool bool) {
    if (this._activeCall != null) {
      this._activeCall.callMute(bool);
    }
  }

  @override
  void onPrivateOutgoingCallEnded() {
    _listener.onPrivateOutgoingCallEnded();
  }

  void isBTDeviceConnected(bool bool) {
    this.isBTDevice = bool;
  }

  bool isSameCall(String groupId) {
    return (_expectedCall == (StringConstants.incomingCallPrefix + groupId));
  }

  void dropCalls() {
    hangup(true);
  }

  bool isAlive(CallStateEnum state) {
    return state == CallStateEnum.CONFIRMED ||
        state == CallStateEnum.STREAM ||
        state == CallStateEnum.MUTED ||
        state == CallStateEnum.UNMUTED;
  }

  @override
  void onCallError() {
    _listener.onCallError();
  }
}
