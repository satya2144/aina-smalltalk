import 'dart:async';

import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

class SIPCall {
  Call _call;
  CallState _callState;

  SIPCall(this._call, this._callState);

  String getID() {
    return _call?.id;
  }

  CallStateEnum getState() {
    return _call.state;
  }

  String getRemoteIdentity() {
    return _call?.remote_identity;
  }

  String getDirection() {
    return _call?.direction;
  }

  String getRemoteDisplayName() {
    return _call?.remote_display_name;
  }

  void enableSpeaker() {
    _callState.stream?.getAudioTracks()?.first?.enableSpeakerphone(true);
  }

  void disableSpeaker() {
    _callState.stream?.getAudioTracks()?.first?.enableSpeakerphone(false);
  }

  void hangup() {
    this._call?.hangup();
  }

  void answer(Map<String, Object> options) {
    this._call.answer(options);
  }

  bool isPrivate() {
    return getRemoteIdentity().contains(StringConstants.privateCallPrefix);
  }

  bool isEmergency() {
    return getRemoteIdentity().contains(StringConstants.emergencyCallPrefix);
  }

  bool isIncoming() {
    return getDirection() == StringConstants.incomingString;
  }

  bool isOutgoing() {
    return getDirection() == StringConstants.outgoingString;
  }

  int getPriority() {
    if (isEmergency()) {
      return CallPriorityEnum.High.index;
    } else if (isPrivate()) {
      return CallPriorityEnum.Medium.index;
    } else {
      return CallPriorityEnum.Low.index;
    }
  }

  bool isRinging() {
    return getState() == CallStateEnum.PROGRESS;
  }

  bool isSameCall(SIPCall sipCall) {
    return this._call.id == sipCall.getID();
  }

  void sendDTMF(EmergencyButtonEventEnum event) {
    this._call.sendDTMF(event == EmergencyButtonEventEnum.PRESSED ? "1" : "2");
  }

  void callMute(bool bool) {
    if (bool) {
      this._call.mute();
    } else {
      this._call.unmute();
    }
  }

  bool isGroupCall() {
    return getRemoteIdentity().startsWith("11");
  }
}
