
import 'package:flutter_test/flutter_test.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:http/http.dart' as http;

import '../helper/fake_sip_repo.dart';
import '../helper/test_helper.dart';
import 'state_register_test.dart';

void main() {
  var listener;
  var fakeSipRepository;
  var sipEngine;
  dynamic request;

  setUp(() {
    listener = new TestListener();
    fakeSipRepository = new FakeSipRepository();
    sipEngine = new SipEngine(listener ,fakeSipRepository);
    request = new http.Request("post", Uri.tryParse(""));
    sipEngine.setActiveGroups("118", "136");
    sipEngine.goIdle();
  });

  test('test Call Incoming to selected group', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "118",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    expect(sipEngine.getCurrentState().runtimeType.toString(),
        "StateCallIncoming");
  });

  test('test Call Incoming to another selected group', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "136",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    expect(sipEngine.getCurrentState().runtimeType.toString(),
        "StateCallIncoming");
  });

  test('test Call Incoming to non selected group', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "134",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateIdle");
  });



  test('test Call Incoming to non selected group', () async {
    sendMessage(sipEngine, {
      "from_id": "473",
      "group_id": "134",
      "from_name": "iu6dispatcher1",
      "action": "Call-Incoming"
    });

    expect(sipEngine.getCurrentState().runtimeType.toString(), "StateIdle");
  });
}
