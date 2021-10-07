

part of 'home_screen.dart';

extension PrivateCallScreen on _HomeScreenState {
  Widget privateCallScreen() {
    return Container(
      width: SizeConfig.screenWidth,
      height: SizeConfig.screenHeight ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: SizeConfig.screenHeight * 0.2,
          ),
          Column(
            children: [
              Container(
                width: SizeConfig.screenWidth * 0.5,
                height: SizeConfig.screenWidth * 0.5,
                child: Image.asset("assets/icons/Icons-27.png"),
              ),
              Column(
                children: [
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.03,
                  ),
                  Text(_callingStatus + " ...",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      )),
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.03,
                  ),
                  Text(_caller,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      )),
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.03,
                  ),
                  isPrivateCallRinging ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: (){
                          _engine.answerPrivateCall(_sipCall);
                        },
                        child: Icon(CupertinoIcons.check_mark_circled_solid,
                          color: Colors.green,
                          size: SizeConfig.screenHeight * 0.08,),
                      ),
                      GestureDetector(
                        onTap: (){
                          _engine.reject(_sipCall);
                        },
                        child: Icon(CupertinoIcons.clear_circled_solid ,
                          color: Colors.red,
                          size: SizeConfig.screenHeight * 0.08,),
                      ),
                    ],
                  ):GestureDetector(
                    onTap: (){
                      _engine.hangup();
                    },
                    child: Icon(CupertinoIcons.clear_circled_solid ,
                      color: Colors.red,
                      size: SizeConfig.screenHeight * 0.08,),
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

