class MessageModel {
  String action;
  MessageModel({this.action});

  MessageModel.fromJson(Map<String, dynamic> json) {
    action = json['action'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['action'] = this.action;
    return data;
  }
}
