abstract class StringConstants {
  //Shared Preference Constants
  static String qrCode = "qrCode";
  static String autoStart = "autoStart";
  static String vibrateWhenConected = "vibrateWhenConected";
  static String isBGCallAllowed = "isBGCallAllowed";
  static String notificationSounds = "notificationSounds";
  static String btDeviceId = "btDeviceId";
  static String btDeviceName = "btDeviceName";

  //App constants
  static String appName = 'AINA';
  static String appBarHeader = "AINA Small Talk";

  //Login
  static String encryptDecryptKey = '+YAinaWirelessY+';
  static String authClientId = '319898';
  static String portNumber = ':8000';
  static String getTokenPath = '/openid/token';
  static String getConfigPath = "/smalltalk/";
  static var scopesList = ['openid', '319898', 'name', 'profile'];

  //UACreation
  static String webSocketURLPre = 'ws://';
  static String webSocketURLPost = ':5066';
  static String webSocketUserAgent = 'Small Talk iOS 2021';
  static String webSocketpassword = '1234';
  static String userName = 'Small Talk iOS 2021';
  static String messagingTarget = 'sip:0@';

  //Path Constants
  static String soundsPath = 'assets/sounds/';

  //SoundsName Constants
  static String transmission_Start = 'beep_double_up.wav';
  static String transmission_Stop = 'beep_double_down.wav';
  static String reception_Start = 'beep_octave_on.wav';
  static String reception_Stop = 'beep_octave_off.wav';
  static String sip_Registration_OK = 'beep_space_up.wav';
  static String sip_Connection_Lost = 'beep_trip_dry.wav';
  static String call_Ring = 'beep_hi_timer.wav';

  //SIP Message Constants
  static const String callAccepted = "Call-Accepted";
  static const String callEnding = "Call-Ending";
  static const String callEnded = "Call-Ended";
  static const String callIncoming = "Call-Incoming";
  static const String presence = "Presence";
  static const String statusMessage = "Status-message";
  static const String groupChange = "Group-Change";


  //Call Related
  static const groupCallPrefix = "10";
  static const incomingCallPrefix = "11";
  static const outgoingCallPrefix = "12";
  static const privateCallPrefix = "00";
  static const emergencyCallPrefix = "99";

  static const incomingString = "INCOMING";
  static const outgoingString = "OUTGOING";

  //Bluetooth manager
  static const bluetoothUUID = "127face1-cb21-11e5-93d0-0002a5d5c51b";
  static const bluetoothButtonCharactersticsUUID =
      "127fbeef-cb21-11e5-93d0-0002a5d5c51b";
  static const bluetoothLedCharactersticsUUID =
      "127fdead-cb21-11e5-93d0-0002a5d5c51b";
  static const bluetoothServicesUUID = "127face1-cb21-11e5-93d0-0002a5d5c51b";

  //Login Screen Constants
  static const instructionText =
      "\*Click on QR code icon to start your scanning";
  static const instructionTextTitle = "Scan QR for Login";
}
