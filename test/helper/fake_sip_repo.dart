
import 'package:oauth2/oauth2.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/sip_repository.dart';

import 'mock_sip_call.dart';

class FakeSipRepository extends SIPRepository {
  SipRepositoryListener sipRepositoryListener;
  String _id;
  MockSIPCall mockSIPCall;
  @override
  void connect(String server, int userId,
      SipRepositoryListener sipRepositoryListener) {
    this.sipRepositoryListener = sipRepositoryListener;
  }

  @override
  void disconnect() {}
  @override
  void unRegister() {}
  @override
  void sendEndingMessage(String activeGroupId) {}

  @override
  void registerPushToken(String pushToken, int pushTokenExpires) {}

  @override
  void sendCallingMessage(String activeGroupId) {}

  @override
  Future<String> startCall(String expectedCall) async {
    return this._id;
  }

  setCall(String id) {
    this._id = id;
  }

  simulateCall(String id , CallStateEnum callState){
    mockSIPCall =
    new MockSIPCall(new Call(id, null, callState));
    sipRepositoryListener.callStateChanged(mockSIPCall);
  }
}