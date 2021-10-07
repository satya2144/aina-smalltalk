import 'user_contract.dart';
import 'dart:convert' as js;


class NewMessageModel {
  String fromId;
  String groupId;
  String fromName;
  String action;
  List<UserContract> contactList;
  String message;
  int messageId;
  String sender;
  int userId;
  String name;
  List<String> listened;
  double lastActive;

  NewMessageModel({this.fromId, this.groupId, this.fromName, this.action , this.contactList,this.message, this.messageId, this.sender, this.userId, this.name, this.listened, this.lastActive});

  NewMessageModel.fromJson(Map<String, dynamic> json) {
    fromId = json['from_id'] ?? '';
    groupId = json['group_id'] ?? '';
    fromName = json['from_name'] ?? '';
    action = json['action'] ?? '';
    if (json['data'] != null) {
      contactList = new List<UserContract>();
      json['data'].forEach((v) {
        contactList.add(new UserContract.fromJson(v));
      });
    }
    message = json['message'] ?? "";
    messageId = json['message-id'] ?? 0;
    sender = json['sender'] ?? "";
    userId = json['user_id'];
    name = json['name'];
    if(json['listened'] != null){
      this.listened = (js.json.decode(json['listened']) as List)?.map((item) => item.toString())?.toList();
    }
    lastActive = json['last_active'];
  }

}
