import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/user_model.dart';
import 'package:smalltalk/features/home/widgets/dialog_call_locate.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupListenersListView extends StatefulWidget {
  final List<User> users;
  final String groupName;
  final String suffix;
  final Function(User) onLocate;
  final Function(User) onPrivateCall;

  GroupListenersListView({Key key,this.users, this.groupName, this.suffix,this.onLocate, this.onPrivateCall}) : super(key: key);

  @override
  GroupListenersListViewState createState() => new GroupListenersListViewState();
}

class GroupListenersListViewState extends State<GroupListenersListView> {
  bool expandFlag = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SizeConfig.screenWidth * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: new Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height:35,
                  margin:EdgeInsets.only(top:2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.groupName,
                        style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),
                      Text(
                        widget.suffix == null ? "" : widget.suffix,
                        style: new TextStyle(color: Colors.black26,fontSize: 10),
                      ),
                      IconButton(
                          icon: new Center(
                            child: new Icon(
                              expandFlag ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              //color: Colors.white,
                              size: 25.0,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              expandFlag = !expandFlag;
                            });
                          }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top:5,bottom:10),
                  child: Row(
                    children: [
                      widget.users
                          ?.length ==
                          0
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
                        padding:
                        const EdgeInsets.only(left: 2.0),
                        child: Text(
                            widget.users
                              ?.length
                              .toString() +
                              " Online",
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black26),
                        ),
                      ),

                    ],
                  ),
                ),
                expandFlag &&  widget.users
                    ?.length !=
                    0 ? Padding(
                  padding:
                  const EdgeInsets
                      .only(
                      top: 10.0,left:3.0,right:3.0,bottom:5),
                  child: Divider(
                    height: 0,
                    thickness: 0.5,
                    endIndent: 0,
                    indent: 0,
                    color: Colors
                        .black38,
                  ),
                ) :Container(),
              ],
            ),
          ),

          new ExpandableContainer(
              expanded: expandFlag,
              totalitems: widget.users?.length,
              child: widget.users !=
                  null
                  ? ListView.builder(
                  itemCount: widget.users
                      ?.length,
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext ctx,
                      int indexNew) {
                    return GestureDetector(
                      behavior:
                      HitTestBehavior.opaque,
                      onTap: () {
                        showPlatformDialog(
                          context: context,
                          barrierDismissible:
                          true,
                          androidBarrierDismissible:
                          true,
                          builder: (_) => Theme(
                            data:
                            ThemeData.light(),
                            child :DialogCallLocate(
                              context:context,
                              name: widget.users[indexNew].name,
                              onLocate:(){
                                Navigator.of(context).pop();
                                this.widget.onLocate(widget.users[indexNew]);
                                },

                                onPrivateCall:(){
                                  Navigator.of(context).pop(true);
                                  this.widget.onPrivateCall(widget.users[indexNew]);
                                },
                                onCancel:(){
                                  Navigator.of(context).pop();
                                }                              
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                            3.0),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets
                                      .only(
                                      right:
                                      8.0),
                                  child:
                                  Container(
                                    child: Icon(
                                      checkOnlineStatus(widget.users[indexNew]
                                          .lastActive)
                                          ? Icons
                                          .circle
                                          : Icons
                                          .stop_circle_outlined,
                                      size: 12,
                                      color: checkOnlineStatus(widget.users[indexNew]
                                          .lastActive)
                                          ? Colors
                                          .green
                                          : Colors
                                          .red,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.users
                                  [
                                  indexNew]
                                      .name,
                                  style: TextStyle(
                                      fontSize:
                                      14,
                                      fontWeight:
                                      FontWeight
                                          .bold),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                  top: 8.0,left:24.0,right:24.0),
                              child: Divider(
                                height: 0,
                                thickness: 0.5,
                                endIndent: 0,
                                indent: 0,
                                color: Colors
                                    .black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
              )
                  : SizedBox()
                ),

        ],
      ),
    );
  }


  showToast(message){
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0
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
    double screenWidth = MediaQuery.of(context).size.width ;
    double screenHeight = MediaQuery.of(context).size.height;
    return new AnimatedContainer(
      duration: new Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: screenWidth,
      height: expanded ? screenHeight*0.05*totalitems: collapsedHeight,
      child: new Container(
        child: child,
      ),
    );
  }
}