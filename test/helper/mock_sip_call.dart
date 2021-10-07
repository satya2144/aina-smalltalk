import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/sip_call.dart';

class MockSIPCall extends SIPCall {
  bool hangedupCalled = false;
  bool speakerEnabled = false;

  MockSIPCall(Call call) : super(call, null);

  @override
  hangup() {
    hangedupCalled = true;
  }

  void enableSpeaker() {
    speakerEnabled = true;
  }

  @override
  String getRemoteIdentity() {
    return "Test-ID";
  }

  ishangedUpCalled() {
    return hangedupCalled;
  }
}