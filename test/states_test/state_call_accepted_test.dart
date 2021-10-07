import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:http/http.dart' as http;
import '../helper/fake_sip_repo.dart';
import '../helper/test_helper.dart';
import 'state_register_test.dart';

int timerLimit = 0;

void main() {
  var listener;
  var fakeSipRepository;
  var sipEngine;
  dynamic request;
  Timer _timer;

  setUp(() {
    listener = new TestListener();
    fakeSipRepository = new FakeSipRepository();
    sipEngine = new SipEngine(listener , fakeSipRepository);
    request = new http.Request("post", Uri.tryParse(""));
    sipEngine.setActiveGroups("118", "136");
    sipEngine.isCallActive = true;
    sipEngine.goIdle();
  });

  test('test Call Accepted', () async {
    sendMessage(sipEngine, {"action": "Call-Accepted", "group_id": "118"});

    expect(sipEngine.getCurrentState().runtimeType.toString(),
        "StateCallAccepted");
  });

  test('test Call Accepted wrong payload', () async {
    sendMessage(sipEngine, {"action": "Call-Accepteddd", "group_id": "118"});

    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateIdle");
  });

  test('test Call Accepted and heartbeat test', () async {
    await sendRecuringMessage(
        sipEngine, {"action": "Call-Accepted", "group_id": "118"});
    await Future.delayed(Duration(seconds: 15));
    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateIdle");
  });
}

sendRecuringMessage(sipEngine, Map<String, String> map) async {
  await sendMessage(sipEngine, map).whenComplete(() async {
    await Future.delayed(Duration(seconds: 6));
    timerLimit = timerLimit + 6;
    if (timerLimit < 30) {
      await sendRecuringMessage(sipEngine, map);
    }
  });


}
