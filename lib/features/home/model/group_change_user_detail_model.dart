import 'package:smalltalk/features/home/providers/group_change_provider.dart';

class GroupChangeUserModel{

  int userId;
  String name;
  List<String> listened;
  double lastActive;

  GroupChangeUserModel ({this.userId,this.name,this.lastActive,this.listened});


}