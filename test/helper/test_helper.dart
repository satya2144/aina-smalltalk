import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sip_ua/sip_ua.dart';

dynamic request = new http.Request("post", Uri.tryParse(""));

Future<void> sendMessage(sipEngine, Map<String, String> map) async {
  request.body = json.encode(map);
  SIPMessageRequest messageRequest =
      new SIPMessageRequest(null, "Manual", request);
  await sipEngine.onNewMessage(messageRequest);
}
