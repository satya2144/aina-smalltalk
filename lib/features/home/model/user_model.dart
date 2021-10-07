import 'dart:convert';

import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/providers/group_change_provider.dart';

class User {
  int id;
  String name;
  double lastActive;
  List<String> listening;
  double longitude;
  double latitude;

  User(UserContract userContract) {
    this.name = userContract.name ?? "";
    this.id = userContract.userId;
    this.lastActive = userContract.lastActive;
    if(userContract.listening != null){
      this.listening = (json.decode(userContract.listening) as List)?.map((item) => item.toString())?.toList();
    }
    this.longitude = userContract.longitude;
    this.latitude = userContract.latitude;
  }

  bool isInGroup(Group group) {
    return this.listening?.contains(group.id.toString()) ?? false;
  }

  bool isOnline() {
    var now = DateTime.now();
    var date = DateTime.fromMillisecondsSinceEpoch(lastActive.toInt() * 1000);
    var diff = now.difference(date);
    int timestampInMinutes = diff.inMinutes;
    return timestampInMinutes < 10;
  }

  void updateUser(List<String> listened, double lastActive) {
    this.listening = listened;
    this.lastActive = lastActive;
  }
}
