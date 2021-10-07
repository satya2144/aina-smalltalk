import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/user_model.dart';
import 'package:smalltalk/features/home/widgets/dialog_call_locate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as stateRiverpod;
import 'package:smalltalk/utils/commons/enums.dart';

import '../../../providers.dart';


class ExpandableListView extends StatefulWidget {
  final List<User> usersList;
  final String groupName;
  final String groupKey;
  final String pttListening;
  final Function(User) onLocate;
  final Function(User) onPrivateCall;

  ExpandableListView(
      {Key key,
      this.usersList,
      this.groupName,
      this.groupKey,
      this.pttListening,
      this.onLocate,
      this.onPrivateCall})
      : super(key: key);

  @override
  _ExpandableListViewState createState() => new _ExpandableListViewState();
}

class _ExpandableListViewState extends State<ExpandableListView> {
  bool expandFlag = false;
  bool speakerFlag = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: new Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.groupName,
                          style: new TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            widget.pttListening == null
                                ? ""
                                : widget.pttListening,
                            style: new TextStyle(
                                color: Colors.black26, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        widget.usersList?.length == 0
                            ? Icon(
                                Icons.stop_circle_outlined,
                                color: Colors.red,
                                size: 12,
                              )
                            : Icon(
                                Icons.circle,
                                color: Colors.green,
                                size: 12,
                              ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Text(
                            widget.usersList?.length.toString() + " Online",
                            style:
                                TextStyle(fontSize: 11, color: Colors.black26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                stateRiverpod.Consumer(
                builder: (context, watch, child) {
                  var group = watch(groupChangeProvider).getGroup(widget.groupKey);

                  return IconButton(
                    icon: Center(
                        child: group.status == GroupStateEnum.UNMUTED
                            ? Image.asset("assets/icons/unmute-icon.png")
                            : group.status == GroupStateEnum.LISTENING
                                ? Image.asset(
                                    "assets/icons/unmute-green-icon.png")
                                :  Image.asset("assets/icons/mute-icon.png")),
                    onPressed: () {
                      var provider = context.read(groupChangeProvider);
                      if(group.status == GroupStateEnum.UNMUTED || group.status == GroupStateEnum.MUTED) { 
                        provider.listen(widget.groupKey);
                      } else {            
                        if(provider.isInPTT(widget.groupKey)) {
                          provider.unmute(widget.groupKey);
                        } else {
                          provider.mute(widget.groupKey);
                        }
                      }
                    });})
              ],
            ),
          ),
          !expandFlag
              ? IconButton(
                  icon: Center(
                    child: Icon(
                      expandFlag
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 30.0,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      expandFlag = !expandFlag;
                    });
                  })
              : Container(),
          ExpandableContainer(
              expanded: expandFlag,
              totalitems: widget.usersList?.length,
              child: Row(
                children: [
                  Expanded(
                    child: widget.usersList != null
                        ? ListView.builder(
                            itemCount: widget.usersList?.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext ctx, int indexNew) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  showPlatformDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    androidBarrierDismissible: true,
                                    builder: (_) => Theme(
                                      data: ThemeData.light(),
                                      child: DialogCallLocate(
                                        context: context,
                                        name: widget.usersList[indexNew].name,
                                        onLocate: () {
                                          Navigator.of(context).pop();
                                          widget.onLocate(widget.usersList[indexNew]);
                                        },
                                        onPrivateCall: () {
                                          Navigator.of(context).pop();
                                          widget.onPrivateCall(widget.usersList[indexNew]);
                                        },
                                        onCancel: () {
                                          Navigator.of(context).pop();                                
                                        }                                        
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Container(
                                              child: Icon(
                                                checkOnlineStatus(widget
                                                        .usersList[indexNew]
                                                        .lastActive)
                                                    ? Icons.circle
                                                    : Icons
                                                        .stop_circle_outlined,
                                                size: 15,
                                                color: checkOnlineStatus(widget
                                                        .usersList[indexNew]
                                                        .lastActive)
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            widget.usersList[indexNew].name,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0, left: 24.0, right: 24.0),
                                        child: Divider(
                                          height: 0,
                                          thickness: 0.5,
                                          endIndent: 0,
                                          indent: 0,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                        : SizedBox(),
                  ),
                ],
              )),
          expandFlag
              ? IconButton(
                  icon: Center(
                    child: Icon(
                      expandFlag
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      //color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      expandFlag = !expandFlag;
                    });
                  })
              : Container(),
        ],
      ),
    );
  }

  bool checkOnlineStatus(double lastActive) {
    if (lastActive == 0.0) {
      return false;
    }
    var time = DateTime.fromMillisecondsSinceEpoch(lastActive.toInt() * 1000);
    var currentTime = new DateTime.now();
    if (currentTime.difference(time).inMinutes <= 10) {
      return true;
    } else {
      return false;
    }
  }
}

class ExpandableContainer extends StatelessWidget {
  final bool expanded;
  final double collapsedHeight;
  final double expandedHeight;
  final Widget child;
  final int totalitems;

  ExpandableContainer({
    @required this.child,
    this.collapsedHeight = 0.0,
    this.expandedHeight = 300.0,
    this.expanded = true,
    this.totalitems,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: screenWidth,
      height: expanded ? screenHeight*0.05*totalitems: collapsedHeight,
      child: Container(
        child: child,
      ),
    );
  }
}
