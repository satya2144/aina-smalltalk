import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/features/about/view/about_screen.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/features/settings/view/settings_screen.dart';
import 'package:smalltalk/utils/commons/navigations.dart';
import 'package:smalltalk/utils/commons_widgets/exit_application_dialog.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

Widget commonAppBar(BuildContext context, String appBarHeader, SipEngine engine , {isLeading = false}) {
  return AppBar(
    backgroundColor: Colors.white,
    brightness: Brightness.dark,
    title: Text(
      appBarHeader,
      style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
    ),
    leading: isLeading ? GestureDetector(
      onTap: () {
          Navigator.pop(context);
      },
      child: new Image(
          image: AssetImage("assets/icons/back.png")),
    ): Container(),

    actions: [
      !isLeading ? GestureDetector(
          onTap: () {
            showPlatformModalSheet(
              context: context,
              builder: (_) => PlatformWidget(
                cupertino: (_, __) => CupertinoActionSheet(
                    actions: <Widget>[
                      CupertinoActionSheetAction(
                        child: Text(
                          'About',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          navigateToPage(
                              context: context, pageName: AboutScreen());
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text('Settings',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          navigateToPage(
                              context: context, pageName: Settings(engine));
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text('Stop service',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          showPlatformDialog(
                              context: context,
                              barrierDismissible: true,
                              androidBarrierDismissible: true,
                              builder: (_) => Theme(
                                data: ThemeData.light(),
                                child:ExitApplicationDialog(
                                  context: context,
                                  onExit: (){
                                    Navigator.of(context).pop();
                                    onAppExit(engine);
                                  },
                                  onCancel: (){
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                          );
                        },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold,
                        color:Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )),
              ),
            );
          },
          child: Container(
            color: Colors.transparent,
            width: 35,
            child: Center(
              child: new Image(
                  image: AssetImage("assets/icons/dots.png")),
            ),
          ),
      ):Container(),
    ],
  );
}

onAppExit(SipEngine engine){
  engine.sendGroupChange(new List());
  engine.stopEngine();
  exit(0);
}
