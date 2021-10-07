import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/sip_library/sip_engine_listener.dart';
import 'package:smalltalk/sip_library/sip_repository.dart';

import '../call_test.dart';
import '../helper/fake_sip_repo.dart';
import '../helper/mock_sip_call.dart';


class TestListener extends Mock implements SipEngineListener {}

void main() {
  var listener;
  var fakeSipRepository;
  var sipEngine;

  setUp(() {
    listener = new TestListener();
    fakeSipRepository = new FakeSipRepository();
    sipEngine = new SipEngine(listener, fakeSipRepository);
    sipEngine.setActiveGroups("118","136");
  });

  test('test SIP Registration', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTERED);
    await sipEngine.connect();

    await sipEngine.registrationStateChanged(regState);

    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateIdle");
  });

  test('test SIP Registration Failed', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTRATION_FAILED);
    await sipEngine.connect();

    sipEngine.registrationStateChanged(regState);
    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateRegister");
  });

  test('test SIP Registration Failed twice', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTRATION_FAILED);
    await sipEngine.connect();

    sipEngine.registrationStateChanged(regState);
    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateRegister");

    sipEngine.registrationStateChanged(regState);
    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateRegister");

    sipEngine.registrationStateChanged(regState);
    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateRegister");
  });
}
