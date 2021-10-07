import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/features/settings/bluetooth_service_provider/bluetooth_manager.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/features/login/view/login_screen.dart';
import 'package:smalltalk/utils/commons/navigations.dart';
import 'package:smalltalk/utils/commons_widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as stateRiverpod;
import '../../../providers.dart';

class Settings extends StatefulWidget {
  SipEngine engine;

  Settings(this.engine);
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool autoStart = true;
  bool playNotification = false;
  bool vibrateWhenConected = true;
  bool isBGCallAllowed = true;
  bool notificationSounds = true;
  String btDeviceName = null;


  @override
  void initState() {

    super.initState();
    getSettings();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: commonAppBar(context, "Settings" , widget.engine , isLeading: true),
      body: SafeArea(
          child: Container(
        width: SizeConfig.screenWidth,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [           
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: customTextWidget("Allow background call")),
                    SizedBox(
                      width: SizeConfig.screenWidth * .2,
                    ),
                    PlatformSwitch(
                      onChanged: (bool value) {
                        setState(() {
                          isBGCallAllowed = value;
                          Future<SharedPreferences> _prefs =
                          SharedPreferences.getInstance();
                          _prefs.then((SharedPreferences prefs) {
                            prefs.setBool(StringConstants.isBGCallAllowed , value);
                          });

                        });

                      },
                      value: isBGCallAllowed,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: customTextWidget("Notification sounds")),
                    SizedBox(
                      width: SizeConfig.screenWidth * .2,
                    ),
                    PlatformSwitch(
                      onChanged: (bool value) {
                        setState(() {
                          notificationSounds = value;
                          Future<SharedPreferences> _prefs =
                          SharedPreferences.getInstance();
                          _prefs.then((SharedPreferences prefs) {
                            prefs.setBool(StringConstants.notificationSounds, value);
                          });
                        });
                      },
                      value: notificationSounds,
                    ),
                  ],
                ),
              ),

              btDeviceName == null ? Container() : Column(children: [              
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: ()  {
                    showPlatformDialog(
                      context: context,
                      barrierDismissible: true,
                      androidBarrierDismissible: true,
                      builder: (_) =>
                          Theme(
                            data: ThemeData.light(),
                            child: PlatformAlertDialog(
                              title: Text('Are you sure you want to unlink bluetooth device?'
                              ),
                              actions: <Widget>[
                                PlatformDialogAction(
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold),
                                  ),
                                  onPressed: ()  async {

                                    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
                                    await _prefs.then((SharedPreferences prefs) async {
                                      prefs.setString(StringConstants.btDeviceId , null);
                                      prefs.setString(StringConstants.btDeviceName , null);
                                    });
                                    Navigator.of(context).pop();

                                    Fluttertoast.showToast(
                                        msg: "Bluetooth device unlinked.",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.black38,
                                        textColor: Colors.white,
                                        fontSize: 16.0
                                    );

                                    setState(() { btDeviceName = null; }); 
                                  },
                                ),
                                PlatformDialogAction(
                                  child: Text(
                                    "No",
                                    style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                    );

                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(
                    'Unlink bluetooth device',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                     btDeviceName,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13.0
                    ),
                  )]),
                ),
              )]),                     
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: ()  {
                      var provider = context.read(bluetoothProvider);
                      provider.startScan((id, name) {
                        setState(() {
                          btDeviceName = name;
                        });
                        Fluttertoast.showToast(
                            msg: "Bluetooth device ${name} connected.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 3,
                            backgroundColor: Colors.black38,
                            textColor: Colors.white,
                            fontSize: 16.0
                        );

                      });

                      Fluttertoast.showToast(
                          msg: "Start scanning...",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.black38,
                          textColor: Colors.white,
                          fontSize: 16.0
                      );                    
                  },
                  child: Text(
                    'Start bluetooth scan',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () async {
                    SharedPreferences _prefs =
                    await SharedPreferences.getInstance();
                    await _prefs.clear();
                    widget.engine.stopEngine();
                    navigateWithPopAllAndPush(
                        context: context, pageName: LoginScreen());
                  },
                  child: Text(
                    'Logout User',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget customTextWidget(String text) {
    return Text(
      text,
      maxLines: 2,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: SizeConfig.textSize * 6.5,
          fontWeight: FontWeight.bold
      ),
    );
  }

  Widget customDisableTextWidget(String text) {
    return Text(
      text,
      maxLines: 2,
      textAlign: TextAlign.left,
      style:
          TextStyle(fontSize: SizeConfig.textSize * 7.5, color: Colors.black26),
    );
  }

  Future<void> getSettings() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    await _prefs.then((SharedPreferences prefs) {
      setState(() {
        autoStart = prefs.getBool(StringConstants.autoStart) ?? true;
        vibrateWhenConected = prefs.getBool(StringConstants.vibrateWhenConected) ?? true;
        isBGCallAllowed = prefs.getBool(StringConstants.isBGCallAllowed) ?? true;
        notificationSounds = prefs.getBool(StringConstants.notificationSounds) ?? true;
        btDeviceName = prefs.getString(StringConstants.btDeviceName);
      });
    });
  }
}
