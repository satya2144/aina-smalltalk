import 'package:flutter_test/flutter_test.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'helper/fake_sip_repo.dart';
import 'states_test/state_register_test.dart';



void main() {
  var listener;
  var fakeSipRepository;
  var sipEngine;

  setUp(() async {
    listener = new TestListener();
    fakeSipRepository = new FakeSipRepository();
    sipEngine = new SipEngine(listener, fakeSipRepository);
    await sipEngine.connect();
  });

  test('test the call manager hangups the calls that are having wrong id ',
      () async {
    fakeSipRepository.setCall("1");
    await sipEngine.startOutgoingCall("118");

    fakeSipRepository.simulateCall("2", CallStateEnum.CONNECTING);

    expect(fakeSipRepository.mockSIPCall.ishangedUpCalled(), true);
  });

  test('test the call manager not call hang up on same call id ', () async {
    fakeSipRepository.setCall("2");
    await sipEngine.startOutgoingCall("118");

    fakeSipRepository.simulateCall("2", CallStateEnum.CONNECTING);

    expect(fakeSipRepository.mockSIPCall.ishangedUpCalled(), false);
  });

  test(
      'test the call manager not call hang up on sending call states in different order ',
      () async {
    fakeSipRepository.setCall("2");
    await sipEngine.startOutgoingCall("118");

    fakeSipRepository.simulateCall("2", CallStateEnum.CONNECTING);

    fakeSipRepository.simulateCall("2", CallStateEnum.ACCEPTED);

    fakeSipRepository.simulateCall("2", CallStateEnum.STREAM);

    fakeSipRepository.simulateCall("2", CallStateEnum.CONFIRMED);

    fakeSipRepository.simulateCall("2", CallStateEnum.STREAM);

    expect(fakeSipRepository.mockSIPCall.ishangedUpCalled(), false);
  });

  // To-Do
  // test(
  //     'test the reconnect feature, simulate all calls dropped and test the call manager reinitiates the call ',
  //     () async {
  //   fakeSipRepository.setCall("Test-Call-12118");
  //   sipEngine.startOutgoingCall("118");
  //
  //   fakeSipRepository.simulateCall("1", CallStateEnum.CONNECTING);
  //
  //   expect(sipEngine.getActiveCall(), "Test-Call-12118");
  // });
}
