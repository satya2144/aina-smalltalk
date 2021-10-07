import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';

class PlaySound {
  static final player = AudioPlayer();
  static playSound(SoundsEnum sound, double volume) {
    player.setVolume(volume);
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((SharedPreferences prefs) {
      if (prefs.getBool(StringConstants.notificationSounds) ?? true) {
        switch (sound) {
          case SoundsEnum.Transmission_Start:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.transmission_Start);
              player.play();
            }
            break;
          case SoundsEnum.Transmission_Stop:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.transmission_Stop);
              player.play();
            }
            break;
          case SoundsEnum.Reception_Start:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.reception_Start);
              player.play();
            }
            break;
          case SoundsEnum.Reception_Stop:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.reception_Stop);
              player.play();
            }
            break;
          case SoundsEnum.Transmission_Confirmed:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.reception_Start);
              player.play();
            }
            break;
          case SoundsEnum.Reception_Confirmed:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.reception_Start);
              player.play();
            }
            break;
          case SoundsEnum.SIP_Registration_OK:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.sip_Registration_OK);
              player.play();
            }
            break;
          case SoundsEnum.Call_Ring:
            {
              player.setAsset(
                  StringConstants.soundsPath + "/" + StringConstants.call_Ring);
              player.play();
            }
            break;
          case SoundsEnum.SIP_Connection_Lost:
            {
              player.setAsset(StringConstants.soundsPath +
                  "/" +
                  StringConstants.sip_Connection_Lost);
              player.play();
            }
            break;
        }
      }
    });
  }
}
