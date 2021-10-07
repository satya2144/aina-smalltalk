import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smalltalk/features/splash/view/splash_screen.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    configureAudioSession();
    return MaterialApp(
      title: StringConstants.appName,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }

  Future<void> configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions
              .defaultToSpeaker |
          AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers
    ));
    await session.setActive(true);
  }
}
