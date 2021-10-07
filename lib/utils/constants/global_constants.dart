abstract class GlobalConstants {
// Debounce Time
  static int groupChangeDebounceTime = 500; //milliseconds
  static int groupAffiliationDebounceTime = 5000; //milliseconds
  static int groupCallDebounceTime = 500; //milliseconds

//Timer Constants
  static int callIncomingHangoutSeconds = 15; //seconds
  static int callAcceptedHangoutSeconds = 15; //seconds
  static int callingHandleTimeoutSeconds = 10; //seconds
  static int emergencyWaitTimer = 3; //seconds
  static int callReqWaitTimer = 3; //seconds
  static int ringTimer = 3; //seconds
  static int presenceTimer = 300; //seconds  5-min
  static int pttPrivateCallResponseTime = 2000; //milliseconds
  static int locationUpdateTimer = 60; //seconds  1-min

//Volume Constants
  static double volumeZero = 0.0;
  static double volumeMax = 1.0;

//Token expires Constant
  static int pushTokenExpires = 60 * 60 * 24; //24 hours
  static int pushTokenExpiresZero = 0;

  // Bluetooth Connection timeout
  static int bluetoothConnectionTimeOut = 2;

  // PTT Buttons Value
  static int ptt1ButtonValue = 1;
  static int ptt2ButtonValue = 4;
  static int pttPrevious = 8;
  static int pttNext = 16;
  static int pttMultiFunction = 32;

  //Show Debug
  static bool showDebug = false;

  //refresh token refreshed before x minutes left in expiry
  static int expiryTimeLeftforAuthToken = 5; //minutes


  // Default Location LatLong
  static double defaultLatitude = 60.3853;
  static double defaultLongitude = 23.1285;

}
