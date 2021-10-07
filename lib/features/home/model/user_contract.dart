
class UserContract {
  int userId;
  String name;
  double lastActive;
  bool visible;
  String listening;
  double locationTime;
  double longitude;
  double latitude;

  UserContract({this.userId,
    this.name,
    this.lastActive,
    this.visible,
    this.listening,
    this.locationTime,
    this.longitude,
    this.latitude});



  UserContract.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    name = json['name'];
    lastActive = json['last_active'] == 0 ? 0.0 :json['last_active'];
    visible = json['visible'];
    listening = json['listening'];
    locationTime = json['location_time'];
    longitude = json['longitude'];
    latitude = json['latitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['name'] = this.name;
    data['last_active'] = this.lastActive;
    data['visible'] = this.visible;
    data['listening'] = this.listening;
    data['location_time'] = this.locationTime;
    data['longitude'] = this.longitude;
    data['latitude'] = this.latitude;
    return data;
  }

}