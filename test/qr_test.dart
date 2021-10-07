import 'package:flutter_test/flutter_test.dart';
import 'package:smalltalk/features/login/validations/decode_qr.dart';

void main() {
  test('empty qr data', () {
    final result = QrDecoder.validateQrData('');
    expect(result, false);
  });

  test('null qr data', () {
    final result = QrDecoder.validateQrData(null);
    expect(result, false);
  });

  test('wrong Qr Details 1', () {
    final result = QrDecoder.validateQrDetails(
        'eyJ1c2VybmFtZSI6InN1bWl0M0Bpb3MtZGV2Iiwic2VjcmV0IjoiTFVhcExQYnZhUyIsInNlcnZlciI6InBpa2t1cHVoZS5ub3J0aGV1cm9wZS5jbG91ZGFwcC5henVyZS5jb20iLCJwcm90b2NvbCI6Imh0dHBzIn0.XxKaEYXjKM7Cw6BXkkiJMUJUrk5Mde2EV2KbMMIFDBU');
    expect(result, false);
  });

  test('wrong Qr Details 2', () {
    final result = QrDecoder.validateQrDetails('http://www.abc.com');
    expect(result, false);
  });

  test('wrong Qr Details payload', () {
    // username not present {"secret": "LUapLPbvaS", "server": "pikkupuhe.northeurope.cloudapp.azure.com", "protocol": "https"}
    final result = QrDecoder.validateQrDetails(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZWNyZXQiOiJMVWFwTFBidmFTIiwic2VydmVyIjoicGlra3VwdWhlLm5vcnRoZXVyb3BlLmNsb3VkYXBwLmF6dXJlLmNvbSIsInByb3RvY29sIjoiaHR0cHMifQ.KrzFUbgO4jAbwjYWXkT3NYWG5VFezOFw6REiO7OtGI0');
    expect(result, false);
  });

  test('Correct Qr Details', () {
    final result = QrDecoder.validateQrDetails(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InN1bWl0M0Bpb3MtZGV2Iiwic2VjcmV0IjoiTFVhcExQYnZhUyIsInNlcnZlciI6InBpa2t1cHVoZS5ub3J0aGV1cm9wZS5jbG91ZGFwcC5henVyZS5jb20iLCJwcm90b2NvbCI6Imh0dHBzIn0.XxKaEYXjKM7Cw6BXkkiJMUJUrk5Mde2EV2KbMMIFDBU');
    expect(result, true);
  });
}
