class QRDetails {
  String username;
  String secret;
  String server;
  String protocol;

  QRDetails({this.username, this.secret, this.server, this.protocol});

  QRDetails.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    secret = json['secret'];
    server = json['server'];
    protocol = json['protocol'];
  }

}