import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';

class QrDecoder {
  static bool validateQrData(String qrData) {
    if (qrData == null || qrData == "") {
      return false;
    }
    return true;
  }

  static bool validateQrDetails(String qrCode) {
    final parts = qrCode.split('.');

    if (parts.length != 3) {
      return false;
    }
    var decodedQr = JwtDecoder.decode(qrCode);
    if (decodedQr == null) {
      return false;
    }
    QRDetails qrDetails = QRDetails.fromJson(decodedQr);
    if (qrDetails.protocol == null ||
        qrDetails.username == null ||
        qrDetails.secret == null ||
        qrDetails.server == null) {
      return false;
    }

    return true;
  }
}
