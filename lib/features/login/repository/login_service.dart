import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/features/login/validations/decode_qr.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

abstract class IOAuthService {
  Future<String> getAccessToken(
      QRDetails qrDetails, List<String> scopes, String authClientId);
}

class OAuthService implements IOAuthService {
  @override
  Future<String> getAccessToken(
      QRDetails qrDetails, List<String> scopes, String authClientId) async {
    final endpoint = Uri.parse(qrDetails.protocol +
        '://' +
        qrDetails.server +
        StringConstants.portNumber +
        StringConstants.getTokenPath);
    final client = await oauth2.resourceOwnerPasswordGrant(
        endpoint, qrDetails.username, qrDetails.secret,
        scopes: scopes, identifier: authClientId, secret: qrDetails.secret);
    return client.credentials.accessToken;
  }
}



class LoginService {
  final _authClientId = StringConstants.authClientId;
  final _scopes = StringConstants.scopesList;
  String _token;
  final _key = StringConstants.encryptDecryptKey;
  OAuthService oAuthService;

  LoginService(IOAuthService oAuthService) {
    this.oAuthService = oAuthService;
  }

  getBaseUrl(QRDetails qrDetails) {
    return qrDetails.protocol +
        '://' +
        qrDetails.server +
        StringConstants.portNumber;
  }

  QRDetails useQrCode(String qrCode) {
    if (!QrDecoder.validateQrDetails(qrCode)) throw ("Invalid QR Code");
    return QRDetails.fromJson(JwtDecoder.decode(qrCode));
  }

  Future<String> getAccessToken(QRDetails qrDetails) async {
    _token = await this
        .oAuthService
        .getAccessToken(qrDetails, _scopes, _authClientId);
    return _token;
  }

  String createAuthBody(String token) {
    final String authBody = '{"token":"$token"}';
    return authBody;
  }

  Uint8List createUint8ListFromString(String s) {
    var ret = new Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }

  String getEncryptedAuth(String token) {
    final body = createAuthBody(token);
    final keyBytes = createUint8ListFromString(_key);
    final key = encrypt.Key(keyBytes);
    final encryptor = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: "PKCS7"));
    final encrypted = encryptor.encrypt(body);
    return base64.encode(encrypted.bytes);
  }

  String decryptBody(String body) {
    final keyBytes = createUint8ListFromString(_key);
    final key = encrypt.Key(keyBytes);
    final encryptor = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: null));
    final decrypted = encryptor.decrypt64(body);
    return decrypted;
  }

  Future getConfig(QRDetails qrDetail, String token) async {
    final body = getEncryptedAuth(token);
    final uri = Uri.parse(getBaseUrl(qrDetail) + StringConstants.getConfigPath);
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode == 200) {
      String decrypted = decryptBody(response.body);
      // Remove trailing padding
      int jsonEndPos = decrypted.lastIndexOf('}');
      if (jsonEndPos != -1) {
        decrypted = decrypted.substring(0, jsonEndPos + 1);
      }
      LoginConfigResponse configResponse =
          LoginConfigResponse.fromJson(json.decode(decrypted));
      return configResponse;
    } else {
      throw Exception('Failed to obtain config');
    }
  }
}
