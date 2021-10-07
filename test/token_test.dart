import 'package:flutter_test/flutter_test.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/features/login/repository/login_service.dart';

void main() {
  test('null Token Validation ', () {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "pikkupuhe.northeurope.cloudapp.azure.com",
      "protocol": "https"
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
    final result = service.getAccessToken(qrDetails);
    expect(result, isNot(equals(null)));
  });

  test('empty server details Validation ', () {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "",
      "protocol": "https"
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
    final result = service.getAccessToken(qrDetails);
    expect(result, throwsArgumentError);
  });

  test('empty protocol details Validation ', () {
    var QrJson = {
      "username": "sumit3@ios-dev",
      "secret": "LUapLPbvaS",
      "server": "pikkupuhe.northeurope.cloudapp.azure.com",
      "protocol": ""
    };
    QRDetails qrDetails = QRDetails.fromJson(QrJson);
    var service = new LoginService(new OAuthService());
    final result = service.getAccessToken(qrDetails);
    expect(result, throwsFormatException);
  });
}
