
import 'package:flutter_test/flutter_test.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/features/login/repository/login_service.dart';



void main(){
  test('Login Validation Successful', ()
  async {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "pikkupuhe.northeurope.cloudapp.azure.com",
      "protocol": "https"
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
    final accessToken = await service.getAccessToken(qrDetails);
    var result  = await service.getConfig(qrDetails, accessToken);
    expect(result, isA<LoginConfigResponse>());
  });

  test('null Acccess token', ()
  async {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "pikkupuhe.northeurope.cloudapp.azure.com",
      "protocol": "https"
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
   String accessToken = null;
   expect(service.getConfig(qrDetails, accessToken), throwsException);
  });

  test('Empty Acccess token', ()
  async {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "pikkupuhe.northeurope.cloudapp.azure.com",
      "protocol": "https"
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
    String accessToken = "";
    expect(service.getConfig(qrDetails, accessToken), throwsException);
  });
}
