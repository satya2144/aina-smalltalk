import 'dart:convert';
import 'package:flutter/src/widgets/framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/features/login/repository/login_service.dart';
import 'package:smalltalk/features/login/validations/decode_qr.dart';
import 'package:smalltalk/providers.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LoginRepository {
  Future fetchLoginDetails(String qrData, BuildContext context);
}

class LoginDataRepository implements LoginRepository {
  LoginService _loginService;
  LoginConfigResponse configResponse;
  LoginDataRepository(){
    _loginService = new LoginService(new OAuthService());
  }
  @override
  Future fetchLoginDetails(String qrData, BuildContext context) async {
    if (!QrDecoder.validateQrData(qrData)) throw ("Invalid QR Code");
    QRDetails qrDetails = _loginService.useQrCode(qrData);
    context.read(qrDetailsProvider).state = qrDetails;
    String token = await _loginService.getAccessToken(qrDetails);
    configResponse = await _loginService.getConfig(qrDetails, token);
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((SharedPreferences prefs) {
      prefs.setString(StringConstants.qrCode, json.encode(qrData));
    });
    return configResponse;
  }
}




