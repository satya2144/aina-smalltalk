class LoginConfigResponse {
  int userId;
  String name;
  bool emergency;
  bool privateCall;
  bool callReq;
  bool location;
  int ptt1Group;
  int ptt2Group;
  bool ptt1Lock;
  bool ptt2Lock;
  List<Group> groups;
  List<Users> users;

  LoginConfigResponse(
      {this.userId,
      this.name,
      this.emergency,
      this.privateCall,
      this.callReq,
        this.location,
      this.ptt1Group,
      this.ptt2Group,
      this.ptt1Lock,
      this.ptt2Lock,
      this.groups,
      this.users});

  LoginConfigResponse.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    name = json['name'];
    emergency = json['emergency'];
    callReq = json['call-req'];
    location = json['location'];
    privateCall = json['privateCall'];
    ptt1Group = json['ptt1Group'];
    ptt2Group = json['ptt2Group'];
    ptt1Lock = json['ptt1Lock'];
    ptt2Lock = json['ptt2Lock'];
    if (json['groups'] != null) {
      groups = new List<Group>();
      json['groups'].forEach((v) {
        groups.add(new Group.fromJson(v));
      });
    }
    if (json['users'] != null) {
      users = new List<Users>();
      json['users'].forEach((v) {
        users.add(new Users.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['name'] = this.name;
    data['emergency'] = this.emergency;
    data['privateCall'] = this.privateCall;
    data['ptt1Group'] = this.ptt1Group;
    data['ptt2Group'] = this.ptt2Group;
    data['ptt1Lock'] = this.ptt1Lock;
    data['ptt2Lock'] = this.ptt2Lock;
    if (this.groups != null) {
      data['groups'] = this.groups.map((v) => v.toJson()).toList();
    }
    if (this.users != null) {
      data['users'] = this.users.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Group {
  String name;
  int id;

  Group({this.name, this.id});

  Group.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    return data;
  }
}

class Users {
  String name;
  int id;

  Users({this.name, this.id});

  Users.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    return data;
  }
}
