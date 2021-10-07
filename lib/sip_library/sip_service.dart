import 'package:package_info/package_info.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

class SIPService {
  UaSettings createUaSettings(String server, int userId, String authToken)  {
    UaSettings settings = UaSettings();
    settings.webSocketUrl = StringConstants.webSocketURLPre +
        server +
        StringConstants.webSocketURLPost;
    settings.webSocketSettings.userAgent = StringConstants.webSocketUserAgent;
    settings.uri = userId.toString() + '@' + server;
    settings.authorizationUser = authToken;
    settings.password = StringConstants.webSocketpassword;
    settings.userAgent = StringConstants.userName;
    settings.iceServers = [];

    settings.registerParams.extraContactUriParams = <String, String>{
      'transport': 'ws',
    };
    return settings;
  }
}
