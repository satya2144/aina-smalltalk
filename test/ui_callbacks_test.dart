import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';

import 'helper/fake_sip_repo.dart';
import 'helper/test_helper.dart';
import 'states_test/state_register_test.dart';

void main() {
  var listener;
  var fakeSipRepository;
  var sipEngine;

  setUp(() {
    listener = new TestListener();
    fakeSipRepository = new FakeSipRepository();
    sipEngine = new SipEngine(listener , fakeSipRepository);
    sipEngine.setActiveGroupId("118");
  });

  test('test notify UI on Registration Success', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTERED);
    await sipEngine.connect();

    await sipEngine.registrationStateChanged(regState);

    verify(listener.onRegistrationSuccesful()).called(1);
  });

  test('test notify UI on Registration Failed', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTRATION_FAILED);
    await sipEngine.connect();

    sipEngine.registrationStateChanged(regState);
    verify(listener.onRegistrationFailed()).called(1);
  });

  test('test notify UI on Registration Expired', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.UNREGISTERED);
    await sipEngine.connect();

    sipEngine.registrationStateChanged(regState);
    verify(listener.onRegistrationExpired()).called(1);
  });

  test('test notify UI of state idle after registration', () async {
    RegistrationState regState =
        new RegistrationState(state: RegistrationStateEnum.REGISTERED);
    await sipEngine.connect();

    await sipEngine.registrationStateChanged(regState);

    verify(listener.onIdleActivated()).called(1);
  });

  test('test  notify UI when incoming call ended', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "118",
      "from_name": "iu6dispatcher1",
      "action": "Call-Ending"
    });
    verify(listener.onIncomingCallEnded()).called(1);
  });

  test('test  notify UI when incoming call ended and state changes to idle',
      () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "118",
      "from_name": "iu6dispatcher1",
      "action": "Call-Ending"
    });
    verify(listener.onIdleActivated()).called(1);
  });

  test('test  notify UI when outgoing call ended ', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "118",
      "from_name": "iu6dispatcher1",
      "action": "Call-Ended"
    });
    verify(listener.onOutgoingCallEnded()).called(1);
  });

  test('test  notify UI when outgoing call ended and state changes to idle ',
      () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "118",
      "from_name": "iu6dispatcher1",
      "action": "Call-Ended"
    });
    verify(listener.onIdleActivated()).called(1);
  });

  test('test  notify UI when outgoing call failed after not getting heartbeat ',
      () async {
    sipEngine.isCallActive = true;
    sipEngine.goIdle();
    sendMessage(sipEngine, {"action": "Call-Accepted", "group_id": "118"});
    await Future.delayed(Duration(seconds: 16));
    verify(listener.onOutgoingCallFailed()).called(1);
  });

  test('test notify UI when incoming call failed after not getting heartbeat',
      () async {
    sipEngine.setActiveGroups("118", "136");
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "136",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    await Future.delayed(Duration(seconds: 16));
    verify(listener.onIncomingCallFailed()).called(1);
  });

  test('test notify UI when incoming call started', () async {
    sipEngine.setActiveGroups("118", "136");
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "136",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    verify(listener.onIncomingCallStarted("iu6dispatcher1", "136")).called(1);
  });
}
