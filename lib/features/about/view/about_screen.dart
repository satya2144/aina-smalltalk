import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:smalltalk/utils/commons_widgets/app_bar.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: commonAppBar(context, "About", null, isLeading: true),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color:Colors.grey[100]),
              width: SizeConfig.screenWidth * 0.15,
              height: SizeConfig.screenWidth * 0.15,
              child: new Image(image: AssetImage('assets/icons/ptt_red_new.png')),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                      "Copyright (C) 2021 \nAINA Wireless Finland Oy. \n\nFor more information see our website",
                      textAlign: TextAlign.center),
                  GestureDetector(
                    onTap: () async {
                      await launch(
                        "https://ainaptt.com",
                          forceSafariVC: false,
                      );
                    },
                      child: Text(
                    "https://ainaptt.com",
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  )),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
