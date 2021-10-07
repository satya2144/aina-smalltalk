import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/user_model.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:logger/logger.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';

class PTTButton {
  Group group;
  bool isLocked;
  int button;

  PTTButton(int button) {
    this.button = button;
  }

  setGroup(Group group) {
    if (!group.isListen()) {
      group.unmute();
    }
    this.group = group;
  }

  bool hasGroup() {
    return this.group != null;
  }
}

class Group {
  String id;
  GroupStateEnum status;
  String name;
  List<User> users;

  Group(String id, String name, GroupStateEnum status) {
    this.id = id;
    this.name = name ?? "";
    this.status = status;
    this.users = new List<User>.empty(growable: true);
  }

  setUsers(List<User> users) {
    this.users = users;
  }

  mute() {
    this.status = GroupStateEnum.MUTED;
  }

  unmute() {
    this.status = GroupStateEnum.UNMUTED;
  }

  listen() {
    this.status = GroupStateEnum.LISTENING;
  }

  isMuted() {
    return this.status == GroupStateEnum.MUTED;
  }

  isUnmuted() {
    return this.status == GroupStateEnum.UNMUTED;
  }

  isListen() {
    return this.status == GroupStateEnum.LISTENING;
  }

  void addUser(User user) {
    var idx = this.users.indexWhere((o) => o.id == user.id);
    if (idx != -1) {
      this.users.removeAt(idx);
    }
    this.users.add(user);
  }

  void removeUser(int userId) {
    this.users.removeWhere((item) => item.id == userId);
  }

  getOnlineUsers() {
    var users = this
        .users
        .where((u) => u.isOnline())
        .toList();
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }
}

class GroupChangeNotifier extends ChangeNotifier {
  Logger _logger = Logger();
  SipEngine _engine;

  PTTButton ptt1;
  PTTButton ptt2;
  List<Group> _groups;
  PTTButton _activeButton;
  final groupChange = new BehaviorSubject<bool>();

  List<User> users;

  bool _suppressNotify = false;

  GroupChangeNotifier() {
    // SipEngine engine
    // _engine = engine;
    ptt1 = PTTButton(1);
    ptt2 = PTTButton(2);
    _groups = List<Group>();
    _activeButton = null;

    groupChange
        .debounceTime(
            Duration(milliseconds: GlobalConstants.groupChangeDebounceTime))
        .listen((_) {
      _logger.d("startBackgroundCall");
      _engine.startBackgroundCall();
    });

    groupChange
        .debounceTime(
            Duration(milliseconds: GlobalConstants.groupAffiliationDebounceTime))
        .listen((_) {
      _logger.d("sendGroupChange");
      _engine.sendGroupChange(_groups
          .where((group) => (group.isListen() || group.isUnmuted()))
          .map((e) => e.id)
          .toList());
    });

    //
    // groupChange
    //     .debounceTime(
    //     Duration(milliseconds: GlobalConstants.groupChangeDebounceTime))
    //     .listen((_) {
    //   _engine.startBackgroundCall();
    // });

    // groupChange
    //     .debounceTime(
    //     Duration(milliseconds: 5000))
    //     .listen((_) {
    //   _engine.sendGroupChange(_groups
    //       .where((group) => (group.isListen() || group.isUnmuted()))
    //       .map((e) => e.id)
    //       .toList());
    // });
  }

  setEngine(SipEngine engine) {
    _logger.d("setEngine called");
    _engine = engine;
  }

  void setGroupDetails(LoginConfigResponse loginConfig) {
    _suppressNotify = true;
    // do not send this contract, instead send lock1, lock2, ptt1, ptt2, groups
    _logger.d("setGroupDetails called");

    ptt1.isLocked = loginConfig.ptt1Lock;
    ptt2.isLocked = loginConfig.ptt2Lock;

    _groups = loginConfig.groups
        .map((value) =>
            Group(value.id.toString(), value.name, GroupStateEnum.MUTED))
        .toList();

    _groups.sort((a, b) => a.name
        .toString()
        .toLowerCase()
        .compareTo(b.name.toString().toLowerCase()));

    if (loginConfig.ptt1Group != null) {
      setPTT1(loginConfig.ptt1Group.toString());
    }

    if (loginConfig.ptt2Group != null) {
      setPTT2(loginConfig.ptt2Group.toString());
    }

    int gIndex = 0;
    if (!ptt1.hasGroup()) {
      setPTT1(_groups.length <= gIndex ? null : _groups[gIndex++]?.id);
    }
    if (!ptt2.hasGroup()) {
      setPTT2(_groups.length <= gIndex ? null : _groups[gIndex++]?.id);
    }

    if (ptt1.group != null) {
      setActivePTT(ptt1);
    } else if (ptt2.group != null) {
      setActivePTT(ptt2);
    }

    _suppressNotify = false;
  }

  notify() {
    if (!_suppressNotify) {
      notifyListeners();
    }
  }

  PTTButton getActiveButton() {
    return _activeButton;
  }

  void setActivePTT(PTTButton button) {
    _logger.d("Set active button", button.button);
    _logger.d("Set active group", button.group.id);
    _activeButton = button;
    _engine.setActiveGroup(button.group.id);
    groupChange.add(true);
  }

  void switchChannel() {
    if (_activeButton.button == 1) {
      _logger.d("Switch channel to PTT2");
      setActivePTT(ptt2);
    } else {
      _logger.d("Switch channel to PTT1");
      setActivePTT(ptt1);
    }
    notify();
  }

  void setPTT1Lock(bool locked) {
    _logger.d("Lock PTT1");
    ptt1.isLocked = locked;
    notify();
  }

  void setPTT2Lock(bool locked) {
    _logger.d("Lock PTT2");
    ptt2.isLocked = locked;
    notify();
  }

  void setPTT1(String id) {
    _logger.d("Set PTT1", id);
    var oldGroup = ptt1.group;
    var group = getGroup(id);
    ptt1.setGroup(group);

    if (oldGroup != null && !isInPTT(oldGroup.id)) {
      dropFromPTT(oldGroup);
    }

    groupChange.add(true);
    if (isActivePTT1()) {
      setActivePTT(ptt1);
    }
    notify();
  }

  void setPTT2(String id) {
    _logger.d("Set PTT2", id);
    var oldGroup = ptt2.group;
    var group = getGroup(id);
    ptt2.setGroup(group);

    if (oldGroup != null && !isInPTT(oldGroup.id)) {
      dropFromPTT(oldGroup);
    }

    groupChange.add(true);
    if (isActivePTT2()) {
      setActivePTT(ptt2);
    }
    notify();
  }

  Group getGroup(String id) {
    return _groups.firstWhere((group) => group.id == id);
  }

  List<Group> getGroups() {
    return _groups;
  }

  void dropFromPTT(Group group) {
    if (group == null) {
      return;
    }
    _logger.d("Drop from PTT", group.id);
    if (group != null && !group.isListen()) {
      group.mute();
      groupChange.add(true);
    }
  }

  PTTButton getPTT(int button) {
    return button == 1 ? ptt1 : ptt2;
  }

  void scrollChannel(int channel, int direction) {
    _logger.d("Scroll channel", channel);
    _logger.d("Scroll direction", direction);
    var ptt = getPTT(channel);
    if (ptt.isLocked) {
      return;
    }

    var index = _groups.indexWhere((group) => group.id == ptt.group.id);
    if (index == -1) {
      return;
    }
    var nextIndex = (index + direction) % _groups.length;
    var newGroup = _groups[nextIndex];
    if (channel == 1) {
      setPTT1(newGroup.id);
    } else {
      setPTT2(newGroup.id);
    }
  }

  bool isInPTT(String id) {
    var isPTT1 = ptt1.group?.id == id;
    var isPTT2 = ptt2.group?.id == id;

    return isPTT1 || isPTT2;
  }

  void onNextChannel(int channel) {
    scrollChannel(channel, 1);
    notify();
  }

  void onPreviousChannel(int channel) {
    scrollChannel(channel, -1);
    notify();
  }

  void mute(String id) {
    _logger.d("Mute", id);
    var group = getGroup(id);
    group.mute();
    groupChange.add(true);
    notify();
  }

  void unmute(String id) {
    _logger.d("Unmute", id);
    var group = getGroup(id);
    group.unmute();
    groupChange.add(true);
    notify();
  }

  void listen(String id) {
    _logger.d("Listen", id);
    var group = getGroup(id);
    group.listen();
    groupChange.add(true);
    notify();
  }

  bool isActivePTT2() {
    return getActiveButton()?.button == 2;
  }

  bool isActivePTT1() {
    return getActiveButton()?.button == 1;
  }

  void setContactList(List<User> users) {
    this.users = users;
    users.forEach((user) {
      updateUserGroups(user);
    });
    notify();
  }

  void onGroupChange(GroupChangeUserModel groupChangeUserModel) {
    User user =
        users.firstWhere((user) => user.id == groupChangeUserModel.userId);
    user.updateUser(
        groupChangeUserModel.listened, groupChangeUserModel.lastActive);
    updateUserGroups(user);
    notify();
  }

  void updateUserGroups(User user) {
    _groups.forEach((group) {
      if (user.isInGroup(group)) {
        group.addUser(user);
      } else {
        group.removeUser(user.id);
      }
    });
  }

  // contactList.forEach((contactDetail) {
  //   if (contactDetail.listening != null) {
  //     var listeningList = json.decode(contactDetail.listening);
  //     listeningList.forEach((element) {
  //       _groups.forEach((value) {
  //         if(value.id == element.toString()){
  //           var existingItem = value.contactList.firstWhere((v) => v.userId == contactDetail.userId, orElse: () => null);
  //           if(existingItem == null)
  //           value.contactList.add(contactDetail);
  //         }
  //       });
  //     });
  //   }
  // });

  //////////

}

// void addGroupStatusMap(
//     Map<String, GroupStateEnum> groupStatus, SipEngine engine) {
//   this._groupStatusMap = groupStatus;
//   _sipEngine = engine;
//   notify();
// }

// void updateGroupStatus(String groupKey, bool isGroupEnable) {
//   GroupStateEnum groupStateNNew;
//   GroupStateEnum groupState = _groupStatusMap[groupKey];

//   if (groupState == GroupStateEnum.UNMUTED && isGroupEnable) {
//     groupStateNNew = GroupStateEnum.LISTENING;
//   }
//   if (groupState == GroupStateEnum.LISTENING && isGroupEnable) {
//     groupStateNNew = GroupStateEnum.UNMUTED;
//   }
//   if (groupState == GroupStateEnum.MUTED && !isGroupEnable) {
//     groupStateNNew = GroupStateEnum.LISTENING;
//   }
//   if (groupState == GroupStateEnum.LISTENING && !isGroupEnable) {
//     groupStateNNew = GroupStateEnum.MUTED;
//   }

//   if (groupStateNNew != null) {
//     this._groupStatusMap[groupKey] = groupStateNNew;
//     notify();
//     onGroupChange();
//   }
// }

// void onGroupChange() {
//   var groupList = new List();
//   this._groupStatusMap.forEach((key, value) {
//     if (value == GroupStateEnum.LISTENING || value == GroupStateEnum.UNMUTED)
//       groupList.add(key);
//   });
//   this._sipEngine.onGroupChange(groupList);
// }

// void updateListenningStatus(String oldGroup, String newGroup) {
//   if (oldGroup != null) {
//     if (_groupStatusMap[oldGroup] == GroupStateEnum.MUTED) {
//       _groupStatusMap[oldGroup] = GroupStateEnum.UNMUTED;
//     } else if (_groupStatusMap[oldGroup] == GroupStateEnum.UNMUTED) {
//       _groupStatusMap[oldGroup] = GroupStateEnum.MUTED;
//     }
//   }

//   if (newGroup != null) {
//     if (_groupStatusMap[newGroup] == GroupStateEnum.MUTED) {
//       _groupStatusMap[newGroup] = GroupStateEnum.UNMUTED;
//     } else if (_groupStatusMap[newGroup] == GroupStateEnum.UNMUTED) {
//       _groupStatusMap[newGroup] = GroupStateEnum.MUTED;
//     }
//   }
//   notify();
// }
