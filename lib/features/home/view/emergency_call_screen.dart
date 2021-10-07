part of 'home_screen.dart';

extension EmergencyCallScreen on _HomeScreenState {
  emergencyCallScreen() {
    return Container(
      width: SizeConfig.screenWidth,
      height: SizeConfig.screenHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: SizeConfig.screenHeight * 0.2,
          ),
          Column(
            children: [
              !emergencyCallHangupButtonDown
                  ? Container(
                      width: SizeConfig.screenWidth * 0.5,
                      height: SizeConfig.screenWidth * 0.5,
                      child: Column(
                        children: [
                          Listener(
                            onPointerDown: (details) {
                              _engine.onEmergencyButtonPressed(
                                  EmergencyButtonEventEnum.PRESSED);
                            },
                            onPointerUp: (details) {
                              _engine.onEmergencyButtonPressed(
                                  EmergencyButtonEventEnum.RELEASED);
                            },
                            child: Container(
                              width: SizeConfig.screenWidth * 0.5,
                              height: SizeConfig.screenWidth * 0.5,
                              child: Image.asset("assets/icons/Icons-29.png"),
                            ),
                          )
                        ],
                      ),
                    )
                  : Container(
                height: SizeConfig.screenWidth * 0.5,
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Text("Cancelling Alarm ...",
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.black,
                                )),
                            SizedBox(
                              height: SizeConfig.screenHeight * 0.1,
                            ),
                            LinearProgressIndicator(
                              value: progressBarAnim.value,
                              backgroundColor: Colors.red.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
              Column(
                children: [
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.03,
                  ),
                   Text(!emergencyCallHangupButtonDown ? _caller + " " + _callingStatus + " ..." : "",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      )),
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.03,
                  ),
                  Listener(
                    onPointerDown: (details) {
                      setState(() {
                        emergencyCallHangupButtonDown = true;
                        startProgress();
                        emergencyHangupTimer = new Timer(
                            Duration(
                                seconds: GlobalConstants.emergencyWaitTimer),
                            () {
                          _engine.hangup();
                        });
                      });
                    },
                    onPointerUp: (details) {
                      emergencyCallHangupButtonDown = false;
                      resetProgress();
                      stopProgress();
                      emergencyHangupTimer?.cancel();
                    },
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: Colors.red,
                      size: SizeConfig.screenHeight * 0.08,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
