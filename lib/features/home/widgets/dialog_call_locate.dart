import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong/latlong.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/user_model.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';

class DialogCallLocate extends StatelessWidget {
  final BuildContext context;
  final String name;
  final Function() onLocate;
  final Function() onPrivateCall;
  final Function() onCancel;

  DialogCallLocate(
      {this.context,
      this.name,
        this.onLocate,
        this.onPrivateCall,
        this.onCancel});

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text('Contact : ' + name),
      actions: <Widget>[
        PlatformDialogAction(
            child: Text(
              "Private Call",
              style: TextStyle(
                  fontWeight:
                  FontWeight.bold),
            ),
            onPressed:  () {
              onPrivateCall();
            }),
        PlatformDialogAction(
            child: Text(
              "Locate User",
              style: TextStyle(
                  fontWeight:
                  FontWeight.bold),
            ),
            onPressed: () {
              onLocate();
            }),
        PlatformDialogAction(
          child: Text(
            "Cancel",
            style: TextStyle(
                fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            onCancel();
          },
        ),
      ],
    );
  }
}
