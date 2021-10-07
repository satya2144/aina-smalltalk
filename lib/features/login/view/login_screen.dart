import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smalltalk/features/login/providers/login_notifier.dart';
import 'package:smalltalk/features/login/view/qr_code_scan.dart';
import 'package:smalltalk/providers.dart';
import 'package:smalltalk/utils/commons/navigations.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

//Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        body: SafeArea(
      bottom: false,
      child: Center(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
              ),
            ),
            Consumer(
                builder: (context, watch, child) {
                  final state = watch(loginNotifierProvider.state);
                  if (state is LoginInitial) {
                    return buildLoginScreen();
                  } else if (state is LoginLoading) {
                    return buildLoading();
                  } else if (state is LoginError) {
                    return PlatformAlertDialog(
                      title: Text(
                        "Error",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text("Unable to login, try again later"),
                      actions: <Widget>[
                        PlatformDialogAction(
                            child: Text(
                              "OK",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => context
                                .read(loginNotifierProvider)
                                .state = LoginInitial()),
                      ],
                    );
                  } else {
                    return buildLoginScreen();
                  }
                },
                child: buildLoginScreen()),
          ],
        ),
      ),
    ));
  }

  Widget buildLoginScreen() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            StringConstants.instructionTextTitle,
            style: TextStyle(
              color: Colors.black,
              fontSize: SizeConfig.textSize * 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              showOptions();
            },
            child: Padding(
              padding:  EdgeInsets.only(top : 30.0 , bottom: 30.0),
              child:
              new Image(
                  image: AssetImage('assets/icons/qr_code.png'))
            ),
          ),
          Padding(
            padding:  EdgeInsets.only(left: 25.0 , right: 25.0),
            child: Text(
              StringConstants.instructionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoading() {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Signing In...",
            style: TextStyle(
              color: Colors.black26,
            )),
        PlatformCircularProgressIndicator(),
      ],
    ));
  }

  Future<void> _getPhotoByGallery() async {
    var status = await Permission.photos.status;
    if (status.isGranted || status.isUndetermined) {
      Stream.fromFuture(ImagePicker.pickImage(source: ImageSource.gallery))
          .flatMap((file) {
        return Stream.fromFuture(QrCodeToolsPlugin.decodeFrom(file.path));
      }).listen((data) {
        Navigator.of(context).pop();
        context.read(loginNotifierProvider).getLoginDetails(data, context);
      }).onError((error, stackTrace) {
        PlatformAlertDialog(
          title: Text("Some Error Occured"),
        );
      });
    } else {
      return showPlatformDialog(
        context: context,
        barrierDismissible: true,
        androidBarrierDismissible: true,
        builder: (_) => Theme(
          data: ThemeData.light(),
          child: PlatformAlertDialog(
            title: Text('Photos Permission'),
            content: Text('This app needs access to your photos '),
            actions: <Widget>[
              PlatformDialogAction(
                child: Text(
                  'Deny',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              PlatformDialogAction(
                child: Text('Settings'),
                onPressed: () => openAppSettings(),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget showOptions() {
    showPlatformModalSheet(
      context: context,
      builder: (_) => PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheet(
            title: Text(
              'I want to scan QR code from',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  var status = await Permission.camera.status;
                  if (status.isGranted || status.isUndetermined) {
                    navigateToPage(context: context, pageName: QRCodeScan());
                  } else {
                    return showPlatformDialog(
                      context: context,
                      barrierDismissible: true,
                      androidBarrierDismissible: true,
                      builder: (_) => Theme(
                        data: ThemeData.light(),
                        child: PlatformAlertDialog(
                          title: Text('Camera Permission'),
                          content: Text(
                              'This app needs access to your Camera to scan QR code '),
                          actions: <Widget>[
                            PlatformDialogAction(
                              child: Text(
                                'Deny', style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            PlatformDialogAction(
                              child: Text('Settings'),
                              onPressed: () => openAppSettings(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
              CupertinoActionSheetAction(
                child: Text('Photos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  _getPhotoByGallery();
                },
              )
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text('Cancel',
                  style: TextStyle(color: Colors.black26 ,fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
              },
            )),
      ),
    );
  }
}
