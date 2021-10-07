import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oauth2/oauth2.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:smalltalk/features/home/model/message_model.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_service.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

abstract class SipRepositoryListener {
  void transportStateChanged(TransportState state);
  void registrationStateChanged(RegistrationState state);
  void callStateChanged(SIPCall sipCall);
  //For SIP messaga coming
  void onNewMessage(SIPMessageRequest msg);
}

abstract class SIPRepository {
  void connect(
      String server, int userId, SipRepositoryListener sipRepositoryListener);

  void registerPushToken(String pushToken, int pushTokenExpires);

  void disconnect();
  void unRegister();
  void sendCallingMessage(String activeGroupId);
  void sendEndingMessage(String activeGroupId);

  Future<String> startCall(String expectedCall) {}

  void answer(SIPCall sipCall) {}

  void sendPresenceMessage() {}

  void sendLocation(double latitude, double longitude) {}

  void statusMessageReply(String messageId, String message) {}

  void sendCallRequest() {}

  void onGroupChange(String group) {}
}

class SIPCallRepository implements SIPRepository, SipUaHelperListener {
  SIPService _sipService;
  SIPUAHelper _ua;
  String sipDomain;
  Credentials authCredentials;
  SipUaHelperListener _sipUaHelperListener;
  SipRepositoryListener _sipRepositoryListener;
  final _groupCallPrefix = StringConstants.groupCallPrefix;
  int _userId;
  bool silentRefresh = false;

  SIPCallRepository() {
    _sipService = new SIPService();
    _sipUaHelperListener = this;
  }

  @override
  void connect(String server, int userId,
      SipRepositoryListener sipRepositoryListener) async {
    this._sipRepositoryListener = sipRepositoryListener;
    this._userId = userId;
    sipDomain = server;
    this.silentRefresh = false;
    String authToken = await getNewAuthToken();
    startUA(authToken);
  }

  Future<void> startUA(String accessToken) async {
    _ua = SIPUAHelper();
    _ua.addSipUaHelperListener(_sipUaHelperListener);
    final settings =
        _sipService.createUaSettings(sipDomain, this._userId, accessToken);
    await _ua.start(settings);
  }

  String createMessageUri(int userId) {
    final uri = 'sip:$_groupCallPrefix$userId@$sipDomain';
    return uri;
  }

  void sendCallingMessage(String groupKey) {
    final target = createMessageUri(int.parse(groupKey));
    final options = createCallOptions(groupKey, "Calling");
    MessageModel msg = new MessageModel(action: "Calling");

    _sendMessage(target, json.encode(msg), options);
  }

  void sendEndingMessage(String groupKey) {
    final target = createMessageUri(int.parse(groupKey));
    final options = createCallOptions(groupKey, "Ending");
    MessageModel msg = new MessageModel(action: "Ending");

    _sendMessage(target, json.encode(msg), options);
  }

  Future registerPushToken(String pushToken, int expires) async {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = await createRegisterPrid(pushToken, expires);

    _sendMessage(target, "", options);
  }

  @override
  void sendPresenceMessage() {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = createPresenceRequest();

    _sendMessage(target, "", options);
  }

  @override
  void sendLocation(double latitude, double longitude) {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = createSendLocationRequest(latitude, longitude);

    _sendMessage(target, "", options);
  }

  @override
  void statusMessageReply(String messageId, String message) {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = createStatusMessageReplyRequest(messageId, message);

    _sendMessage(target, "", options);
  }

  @override
  void sendCallRequest() {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = createSendMessageRequest();
    MessageModel msg = new MessageModel(action: "Call-Request");

    _sendMessage(target, json.encode(msg), options);
  }

  @override
  void onGroupChange(String groupList) {
    final target = '${StringConstants.messagingTarget}$sipDomain';
    final options = createGroupChangeRequest(groupList);
    MessageModel msg = new MessageModel(action: "Group-Change");
    _sendMessage(target, json.encode(msg), options);
  }

  Future<String> startCall(String identity) async {
    final target = createCallUri(identity);
    String callId = await _ua.call(target, true);
    return callId;
  }

  String createCallUri(String identity) {
    final uri = 'sip:$identity@$sipDomain';
    return uri;
  }

  void stopIncomingCall() {
    _ua.stop();
  }

  Map<String, dynamic> createCallOptions(String s, String action) {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: $action');
    return options;
  }

  Future createRegisterPrid(String prid, int expires) async {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    final PackageInfo info = await PackageInfo.fromPlatform();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Register-PRID');
    headers.add('X-PN-Provider: apns');
    headers.add('X-PN-Param: ${info.packageName}');
    headers.add('X-PN-PRID: $prid');
    // Send zero to remove push token
    headers.add('X-PN-PRID-Expires: $expires');
    return options;
  }

  Map<String, dynamic> createPresenceRequest() {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Presence-Request');
    return options;
  }

  createSendLocationRequest(double latitude, double longitude) {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Location');
    headers.add(
        'X-Location: {"latitude" : ${latitude.toString()} , "longitude" : ${longitude.toString()}}');
    return options;
  }

  createStatusMessageReplyRequest(String messageId, String message) {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Status-message-response');
    headers.add(
        'X-Message-id: ${messageId}');
    headers.add(
        'X-Message: ${message}');
    return options;
  }

  createSendMessageRequest() {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Call-Request');
    return options;
  }

  createGroupChangeRequest(String groupList) {
    final options = Map<String, dynamic>();
    final headers = List<dynamic>();
    options['contentType'] = 'text/plain';
    options['extraHeaders'] = headers;
    headers.add('Accept: text/plain');
    headers.add('X-Action: Group-Change');
    headers.add('X-Listened: ${groupList}');//X-Listened: [118,134]
    return options;
  }

  void disconnect() {
    _ua?.stop();
  }

  void unRegister() {
    _ua?.removeSipUaHelperListener(this._sipUaHelperListener);
    _ua?.stop();
  }

  @override
  void callStateChanged(Call call, CallState state) {
    final sipCall = SIPCall(call, state);
    if (state.state == CallStateEnum.CONFIRMED) {
      // If call is a group call, mute it initially
      if (sipCall.isGroupCall())
        call.mute(true);
      else
        call.mute(false);
    }
    _sipRepositoryListener.callStateChanged(sipCall);
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    _sipRepositoryListener.onNewMessage(msg);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    if (!silentRefresh) {
      _sipRepositoryListener.registrationStateChanged(state);
    } else {
      if (state.state == RegistrationStateEnum.REGISTERED ||
          state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
        silentRefresh = false;
      }
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    _sipRepositoryListener.transportStateChanged(state);
  }

  @override
  void answer(SIPCall sipCall) {
    //To - Call answer from Call Manager .. _ua.buildCallOptions(true) in  callStateChanged
    sipCall.answer(_ua.buildCallOptions(true));
  }

  bool tokenExpired(Credentials authCredentials) {
    if ((authCredentials.expiration).difference(DateTime.now()).inMinutes >
        GlobalConstants.expiryTimeLeftforAuthToken) {
      return false;
    }
    return true;
  }

  refreshToken() async {
    silentRefresh = true;
    String authToken = await getNewAuthToken();
    startUA(authToken);
  }

  Future<String> getNewAuthToken() async {
    QRDetails qrDetails;
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    await _prefs.then((SharedPreferences prefs) async {
      qrDetails = QRDetails.fromJson(
          JwtDecoder.decode(prefs.getString(StringConstants.qrCode)));
    });
    final endpoint = Uri.parse(qrDetails.protocol +
        '://' +
        qrDetails.server +
        StringConstants.portNumber +
        StringConstants.getTokenPath);
    final client = await oauth2.resourceOwnerPasswordGrant(
        endpoint, qrDetails.username, qrDetails.secret,
        scopes: StringConstants.scopesList,
        identifier: StringConstants.authClientId,
        secret: qrDetails.secret);
    this.authCredentials = client.credentials;
    return this.authCredentials.accessToken;
  }

  void _sendMessage(String target, String encode, Map<String, dynamic > options) {
    if (tokenExpired(this.authCredentials)) {
      refreshToken();
    }
    _ua.sendMessage(target, encode, options);
  }




}
