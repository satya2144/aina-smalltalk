import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:uuid/uuid.dart';

typedef CallChanged(Call call);

class CallService {
  factory CallService() {
    return _cache ?? CallService._internal();
  }

  static CallService _cache;

  CallService._internal()
      : _provider = FCXProvider(),
        _callController = FCXCallController(),
        _plugin = FCXPlugin() {
    _cache = this;
    _configure();
  }

  final FCXPlugin _plugin;
  final FCXProvider _provider;
  final FCXCallController _callController;
  Call _managedCall;
  CallChanged callChangedEvent;
  bool _configured = false;
  Completer _activateCallCompleter;
  AudioSession session;

  String get callerName => _managedCall?.callerName;

  Future<void> emulateOutgoingCall() async {
    if (_activateCallCompleter != null) {
      _activateCallCompleter.completeError("");
    }
    _activateCallCompleter = new Completer();
    await _configure();
    Call managedCall = Call(true, "AinaPTT");
    _managedCall = managedCall;
    FCXHandle handle = FCXHandle(FCXHandleType.PhoneNumber, "AinaPTT");
    FCXStartCallAction action = FCXStartCallAction(managedCall.uuid, handle);
    action.video = false;
    _callController.requestTransactionWithAction(action);
    return _activateCallCompleter.future;
  }

  Future<void> _configure() async {
    if (_configured) {
      return;
    }

    await _callController.configure();

    FCXProviderConfiguration configuration = FCXProviderConfiguration(
      'FlutterCallKit',
      iconTemplateImageName: 'CallKitLogo',
      includesCallsInRecents: false,
      supportsVideo: false,
      maximumCallsPerCallGroup: 1,
      supportedHandleTypes: {FCXHandleType.PhoneNumber, FCXHandleType.Generic},
    );

    await _provider.configure(configuration);

    _provider.performStartCallAction = (startCallAction) async {
      _provider.reportOutgoingCallConnected(
          startCallAction.callUuid, DateTime.now());
      startCallAction.fulfill();
    };

    _provider.providerDidActivateAudioSession = () async {
      _activateCallCompleter?.complete();
      _activateCallCompleter = null;
    };

    _provider.performEndCallAction = (endCallAction) async {
      _managedCall = null;
      endCallAction.fulfill();
      callChangedEvent?.call(_managedCall);
    };

    _provider.performAnswerCallAction = (answerCallAction) async {
      configureAudioSeesion();
      session.setActive(true);
      _provider.reportOutgoingCallConnected(
          answerCallAction.callUuid, DateTime.now());
      answerCallAction.fulfill();
    };
    _callController.callObserver.callChanged = (call) async {};
    _configured = true;
  }

  Future<void> hangup() async {
    if (_managedCall == null) {
      return null;
    }

    FCXEndCallAction action = FCXEndCallAction(_managedCall.uuid);
    _callController.requestTransactionWithAction(action);
  }

  Future<void> configureAudioSeesion() async {
    session = await AudioSession.instance;
    session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions
              .defaultToSpeaker
    ));
  }
}

var _uuid = Uuid();

class Call {
  final String uuid;
  final bool outgoing;
  final String callerName;
  bool muted = false;
  bool onHold = false;

  Call(this.outgoing, this.callerName) : uuid = _uuid.v4();
}
