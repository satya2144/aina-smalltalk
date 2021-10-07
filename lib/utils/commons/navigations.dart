import 'package:flutter/cupertino.dart';

void navigateToPage({
  @required BuildContext context,
  @required Widget pageName,
}) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (BuildContext context) => pageName,
    ),
  );
}

void navigateWithReplacement({
  @required BuildContext context,
  @required Widget pageName,
}) {
  Navigator.pushReplacement(
    context,
    CupertinoPageRoute(
      builder: (BuildContext context) => pageName,
    ),
  );
}

void navigateWithPopAllAndPush({
  @required BuildContext context,
  @required Widget pageName,
}) {
  Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => pageName),
      (Route<dynamic> route) => false);
}
