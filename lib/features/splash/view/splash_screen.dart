import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/features/login/providers/login_notifier.dart';
import 'package:smalltalk/features/login/view/login_screen.dart';
import 'package:smalltalk/utils/commons/navigations.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as Location;


import '../../../providers.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Location.Location location;

  @override
  void initState() {
    super.initState();
    location = Location.Location();
    checkAllPermissions();
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((SharedPreferences prefs) {
      bool isUserLoggedIn = prefs.containsKey(StringConstants.qrCode) ?? false;
      if (!isUserLoggedIn) {
        Future.delayed(Duration(seconds: 2), () {
          navigateWithReplacement(context: context, pageName: LoginScreen());
        });
      } else {
        Future.delayed(Duration(seconds: 2), () {
          context.read(loginNotifierProvider).getLoginDetails(
              prefs.getString(StringConstants.qrCode), context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return PlatformScaffold(
        backgroundColor: Colors.white,
        body: ProviderListener(
          provider: loginNotifierProvider.state,
          onChange: (context, state) async {
            if (state is LoginError) {
              SharedPreferences _prefs = await SharedPreferences.getInstance();
              await _prefs.clear();
              navigateWithReplacement(
                  context: context, pageName: LoginScreen());
            }
          },
          child: Container(
              child: Center(
                  child: Container(
            child: new Image(
                image: AssetImage('assets/icons/aina_small_talk_app_logo.png')),
          ))),
        ));
  }

  Future<void> checkAllPermissions() async {
    if (!await Permission.microphone.isGranted) await Permission.microphone.request();
    if (!await Permission.camera.isGranted) await Permission.camera.request();
    if (!await Permission.photos.isGranted) await Permission.photos.request();
    // if( (await location.hasPermission()) != Location.PermissionStatus.granted){
    //     await location.requestPermission();
    // }
  }
}
