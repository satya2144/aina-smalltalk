import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ExitApplicationDialog extends StatelessWidget {
  final BuildContext context;
  final Function() onExit;
  final Function() onCancel;

  ExitApplicationDialog({
    this.context,
    this.onExit,
    this.onCancel
  });

  @override
  Widget build(BuildContext context) {
    return  PlatformAlertDialog(
      title: Text('Exit application ?' ),
      actions: <Widget>[
        PlatformDialogAction(
            child: Text(
              "Exit",
              style: TextStyle(
                  fontWeight: FontWeight.bold),
            ),
            onPressed:  () {
              onExit();
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
