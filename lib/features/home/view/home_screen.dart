import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:logger/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns/apns.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as stateRiverpod;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smalltalk/features/home/model/group_change_user_detail_model.dart';
import 'package:smalltalk/features/home/model/user_contract.dart';
import 'package:smalltalk/features/home/model/new_message_model.dart';
import 'package:smalltalk/features/home/model/user_model.dart';
import 'package:smalltalk/features/home/widgets/group_listeners_list.dart';
import 'package:smalltalk/features/settings/bluetooth_service_provider/bluetooth_listener.dart';
import 'package:smalltalk/features/settings/bluetooth_service_provider/bluetooth_manager.dart';
import 'package:smalltalk/sip_library/sip_call.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/sip_library/sip_engine_listener.dart';
import 'package:smalltalk/sip_library/sip_repository.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/helper/play_sound_helper.dart';
import 'package:smalltalk/providers.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/commons_widgets/app_bar.dart';
import 'package:smalltalk/features/home/widgets/dialog_call_locate.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/utils/constants/size_config_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import 'expandable_list.dart';

part 'emergency_call_screen.dart';
part 'private_call_screen.dart';

class UserLocation {
  final String name;
  final LatLng location;

  UserLocation({this.name, this.location});
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements SipEngineListener, BluetoothDeviceListener {
  int tabIndex = 0;
  FlutterTts flutterTts;
  PageController pageController = new PageController(initialPage: 0);
  PTTButtonEnum buttonState = PTTButtonEnum.UP;
  bool alarmButtonPressed;
  bool reqButtonPressed;
  bool emergencyCallHangupButtonDown;
  bool canShowMessage = true;
  bool isPrivateCall = false;
  bool isPrivateCallRinging = false;
  bool isEmergencyCall = false;
  AnimationController controller;
  Animation progressBarAnim;
  LoginConfigResponse _loginConfig;

  String currentState = "Initial";
  // Map<String, bool> groupSpeakerFlag = Map();
  BluetoothManager _bt;
  bool showDebug;
  Timer ringTimer;
  Timer speechTimer;
  var callingState;
  SipEngine _engine;
  var server;
  Map<int, NewMessageModel> msgList = new Map();
  String _caller = '';
  SIPCall _sipCall;
  String _callingStatus = 'Ringing';
  Timer emergencyTimer;
  Timer emergencyHangupTimer;
  Timer callReqTimer;
  bool isPTTDeviceConnected = false;
  bool _ptt1Down = false;
  bool _ptt2Down = false;
  bool isPrivateCallActive = false;
  final groupCall = new BehaviorSubject<String>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String callerName = null;
  String callerGroup;

  bool showContact = false;
  bool privateCallFlag = false;
  bool incomingCallFlag = false;
  MapController _mapController;
  final Location _locationService = Location();
  bool _permission = false;
  LocationData _currentLocation;
  final _logger = Logger();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _engine = new SipEngine(this, new SIPCallRepository());
    super.initState();
    QRDetails qrDetails = context.read(qrDetailsProvider).state;
    server = qrDetails.server;
    _loginConfig = context.read(configProvider).state;
    // This is commented to run in simulator
    getPushToken();

    //This single line is added to run in simulator
    // _engine.start(this.server, this._loginConfig.userId, connector.token.value);

    buttonState = PTTButtonEnum.UP;
    alarmButtonPressed = false;
    reqButtonPressed = false;
    emergencyCallHangupButtonDown = false;
    controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    progressBarAnim = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() {
        setState(() {});
      });
    // groupChange
    //     .debounceTime(
    //         Duration(milliseconds: GlobalConstants.groupChangeDebounceTime))
    //     .listen((_) {
    //   // TODO set active call here!!
    //   // context.read(groupChangeProvider)
    //   // context.read(groupChangeProvider).onGroupChange(); // TODO why this is calling onGroupChange()
    //   // _engine
    //   //     .setActiveGroup(context.read(groupChangeProvider).getActiveGroup());
    //   _engine.startBackgroundCall();
    // });
    groupCall
        .debounceTime(
            Duration(milliseconds: GlobalConstants.groupCallDebounceTime))
        .listen((groupKey) {
      if (groupKey != null) {
        _engine.startGroupCall(groupKey);
      }
    });
    _bt = new BluetoothManager();
    _bt.setListener(this);
    initTts();

    //map
    _mapController = MapController();
    initLocationService();
  }

  @mustCallSuper
  @protected
  void dispose() {
    controller.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is! MapEventMove && mapEvent is! MapEventRotate) {
      print('mapEvent$mapEvent');
    }
  }

  onTabChange(int index) {
    setState(() {
      if (index == 0) {
        showContact = false;
      }
      if (index == 0 && privateCallFlag) {
        showContact = true;
        privateCallFlag = false;
      }
    });
    tabIndex = index;
  }

  startProgress() {
    controller.forward();
  }

  stopProgress() {
    controller.stop();
  }

  resetProgress() {
    controller.reset();
  }

  void initLocationService() async {
    if (!isLocationEnabled()) {
      _currentLocation = LocationData.fromMap({
        "latitude": GlobalConstants.defaultLatitude,
        "longitude": GlobalConstants.defaultLongitude
      });
      return;
    }
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await _locationService.serviceEnabled();

      if (serviceEnabled) {
        var permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationService.onLocationChanged
              .listen((LocationData result) async {
            setState(() {
              _currentLocation = result;
            });
            if (mounted) {
              setState(() {
                _currentLocation = result;
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        _logger.d("PERMISSION_DENIED");
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _logger.d("SERVICE_STATUS_ERROR");
      }
      location = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: commonAppBar(context, StringConstants.appBarHeader, _engine),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
              activeIcon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: showContact
                      ? Image.asset("assets/icons/tab_home_grey.png")
                      : Image.asset("assets/icons/tab_home_red.png")),
              icon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_home_grey.png")),
              title: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  'Home',
                  style: TextStyle(
                      color: showContact ||
                              tabIndex == 1 ||
                              tabIndex == 2 ||
                              tabIndex == 3
                          ? Color(0xff848a86)
                          : Colors.red),
                ),
              )),
          BottomNavigationBarItem(
              activeIcon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_groups_red.png")),
              icon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_groups_grey.png")),
              title: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text('Groups'),
              )),
          BottomNavigationBarItem(
              activeIcon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_map_red.png")),
              icon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_map_grey.png")),
              title: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text('Map'),
              )),
          BottomNavigationBarItem(
              activeIcon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_account_red.png")),
              icon: Container(
                  height: SizeConfig.screenWidth * 0.10,
                  width: SizeConfig.screenWidth * 0.10,
                  child: Image.asset("assets/icons/tab_account_grey.png")),
              title: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text('Account'),
              )),
        ],
        currentIndex: tabIndex,
        elevation: 5.0,
        onTap: onTabChange,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: new BoxDecoration(color: Colors.grey[100]),
          child: Stack(
            children: [
              stateRiverpod.Consumer(
                builder: (context, watch, child) {
                  isPTTDeviceConnected =
                      watch(isPTTDeviceConnectedProvider).state;
                  return (isPrivateCall || isEmergencyCall)
                      ? isEmergencyCall
                          ? emergencyCallScreen()
                          : privateCallScreen()
                      : IndexedStack(
                          index: tabIndex,
                          children: <Widget>[
                            homeScreen(),
                            groupsScreen(),
                            Offstage(offstage: false, child: mapScreen()),
                            profileScreen()
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mapScreen() {
    return Container(
      child: stateRiverpod.Consumer(builder: (context, watch, child) {
        var users = watch(groupChangeProvider).users;

        // for(var i=0; i<users.length;i++)
        //   print('users${users[i].}');
        var markers = new List();
        markers = users
            ?.where((contact) =>
                contact.latitude != null && contact.longitude != null)
            ?.map((contact) => Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(contact.latitude, contact.longitude),
                  // point:  LatLng(61.924100, 25.748200),
                  builder: (context) => GestureDetector(
                    onTap: () {
                      showPlatformDialog(
                          context: context,
                          barrierDismissible: true,
                          androidBarrierDismissible: true,
                          builder: (_) => Theme(
                                data: ThemeData.light(),
                                // child: platformAlertDialogWidget(index, context,users,_engine),
                                child: DialogCallLocate(
                                    context: context,
                                    name: contact.name,
                                    onLocate: () {
                                      Navigator.of(context).pop();
                                      locateUser(contact);
                                    },
                                    onPrivateCall: () {
                                      Navigator.of(context).pop();
                                      startPrivateCall(contact);
                                    },
                                    onCancel: () {
                                      Navigator.of(context).pop();
                                    }),
                              ));
                      //onTabChange(2); why this?
                    },
                    child: Column(
                      children: [
                        Text(
                          contact.name,
                          style: TextStyle(color: Colors.red),
                        ),
                        Image(
                          image: !contact.isOnline()
                              ? AssetImage('assets/icons/tab_map_grey.png')
                              : AssetImage('assets/icons/tab_map_red.png'),
                          width: 30,
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ))
            ?.toList();

        LatLng currentLatLng;
        currentLatLng = LatLng(
            _currentLocation?.latitude ?? GlobalConstants.defaultLatitude,
            _currentLocation?.longitude ?? GlobalConstants.defaultLongitude);
        markers?.add(Marker(
          width: 80.0,
          height: 80.0,
          point: currentLatLng,
          builder: (context) => Column(
            children: [
              Text(!isLocationEnabled() ? "Location Disabled " : "Me",
                  style: TextStyle(color: Colors.red)),
              isLocationEnabled()
                  ? Image(
                
                      image: AssetImage('assets/icons/pin_blue.png'),
                      width: 30,
                      height: 30,
                    )
                  : SizedBox(),
            ],
          ),
        ));

        return Stack(
          children: [
            markers != null
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(_currentLocation?.latitude,
                          _currentLocation?.longitude),
                      minZoom: 4.0,
                      zoom: 14.0,
                      interactiveFlags:
                          InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                    layers: [
                        TileLayerOptions(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          tileProvider: NonCachingNetworkTileProvider(),
                        ),
                        MarkerLayerOptions(markers: markers)
                      ])
                : Container(),
            Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 16, right: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      child: Container(
                          height: SizeConfig.screenWidth * 0.17,
                          width: SizeConfig.screenWidth * 0.16 + 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                          child: context
                                      .read(groupChangeProvider)
                                      .getActiveButton()
                                      ?.button ==
                                  1
                              ? new Image(
                                  image: AssetImage(
                                      'assets/icons/Switch_1_channel.png'))
                              : new Image(
                                  image: AssetImage(
                                      'assets/icons/Switch_2_channel.png'))),
                    ),
                    onTap: () {
                      setState(() {
                        context.read(groupChangeProvider).switchChannel();
                        // groupChange.add(true);
                      });
                    },
                  ),
                  // SizedBox(width: 15,),
                  context.read(groupChangeProvider).getGroups().length == 0
                      ? Center(
                          child: Text(
                            "Loading ... ",
                            style: TextStyle(fontSize: 20),
                          ),
                        )
                      : context.read(groupChangeProvider).getGroups().length > 0
                          ? Material(
                              elevation: 5,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              child: Container(
                                width: SizeConfig.screenWidth * 0.64,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: context
                                      .read(groupChangeProvider)
                                      .getGroups()
                                      .length, // your List
                                  itemBuilder: (context, index) {
                                    var provider =
                                        context.read(groupChangeProvider);
                                    var group = provider.getGroups()[index];

                                    var isActive =
                                        provider.getActiveButton()?.group.id ==
                                            group.id;
                                    var isPTT1 =
                                        provider.ptt1?.group.id == group.id;
                                    var isPTT2 =
                                        provider.ptt2?.group.id == group.id;
                                    var suffix = (isPTT1 &&
                                            isPTT2) // move this stuff to GroupListenersListView
                                        ? "PTT 1 / PTT 2"
                                        : (isPTT1
                                            ? "PTT 1"
                                            : (isPTT2 ? "PTT 2" : ""));

                                    // why to loop this throug and just return one item always!?!? TODO Fix this shit!!

                                    return isActive
                                        ? GroupListenersListView(
                                            suffix: suffix,
                                            groupName: group.name,
                                            users: group.getOnlineUsers(),
                                            onLocate: (user) {
                                              locateUser(user);
                                            },
                                            onPrivateCall: (user) {
                                              startPrivateCall(user);
                                            },
                                          )
                                        : Container();
                                  },
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                "No Contacts ",
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                ],
              ),
            ),
            isLocationEnabled()
                ? Positioned(
                    bottom: 80,
                    left: 24,
                    child: GestureDetector(
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        child: Container(
                            height: SizeConfig.screenWidth * 0.18,
                            width: SizeConfig.screenWidth * 0.18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image(
                                    image: AssetImage(
                                        'assets/icons/ic_menu_mylocation.png')),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('LOCATE',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )),
                      ),
                      onTap: () {
                        _logger.d(
                            "Moving to",
                            LatLng(_currentLocation?.latitude,
                                _currentLocation?.longitude));
                        _mapController.move(
                            LatLng(_currentLocation?.latitude,
                                _currentLocation?.longitude),
                            _mapController.zoom);
                      },
                    ),
                  )
                : SizedBox(),
            Positioned(
              bottom: 10,
              child: GestureDetector(
                onTapDown: (value) {
                  setState(() {
                    if (buttonState != PTTButtonEnum.INCOMING) {
                      buttonState = PTTButtonEnum.DOWN;
                      groupCall.add(context
                          .read(groupChangeProvider)
                          .getActiveButton()
                          ?.group
                          ?.id);
                    }
                  });
                },
                onTapUp: (value) {
                  setState(() {
                    if (buttonState != PTTButtonEnum.INCOMING &&
                        !isEmergencyCall) {
                      groupCall.add(null);
                      buttonState = PTTButtonEnum.UP;
                      _engine.stopGroupCall();
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Material(
                    elevation: buttonState == PTTButtonEnum.DOWN ? 0 : 5,
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    child: Container(
                      height: SizeConfig.screenWidth * 0.16,
                      width: SizeConfig.screenWidth * 0.87,
                      decoration: BoxDecoration(
                        color: buttonState == PTTButtonEnum.DOWN ||
                                buttonState == PTTButtonEnum.INCOMING
                            ? buttonState == PTTButtonEnum.DOWN
                                ? Colors.red
                                : Colors.green
                            : Color(0xFF6DC3C9),
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image(
                            image: AssetImage(
                                'assets/icons/speaker_voice_white.png')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget homeScreen() {
    return ListView(
      physics: NeverScrollableScrollPhysics(),
      children: [
        !showContact
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: SizeConfig.screenWidth * 0.56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            child: Container(
                                height: SizeConfig.screenWidth * 0.16,
                                width: SizeConfig.screenWidth * 0.16,
                                child: context
                                            .read(groupChangeProvider)
                                            .getActiveButton()
                                            ?.button ==
                                        1
                                    ? new Image(
                                        image: AssetImage(
                                            'assets/icons/Switch_1_channel.png'))
                                    : new Image(
                                        image: AssetImage(
                                            'assets/icons/Switch_2_channel.png'))),
                            onTap: () {
                              setState(() {
                                context
                                    .read(groupChangeProvider)
                                    .switchChannel();
                                // groupChange.add(true);
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // tabIndex = 1;
                                  showContact = !showContact;
                                });
                              },
                              child: Container(
                                  height: SizeConfig.screenWidth * 0.15,
                                  width: SizeConfig.screenWidth * 0.15,
                                  child: new Image(
                                      image: AssetImage(
                                          'assets/icons/contact_list.png'))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _loginConfig.emergency
                        ? Listener(
                            onPointerDown: (details) {
                              setState(() {
                                reqButtonPressed = true;
                                alarmButtonPressed = true;
                                startProgress();
                                emergencyTimer = new Timer(
                                    Duration(
                                        seconds: GlobalConstants
                                            .emergencyWaitTimer), () {

                                  PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
                                  _engine.startEmergencyCall();
                                });
                              });
                            },
                            onPointerUp: (details) {
                              reqButtonPressed = false;
                              alarmButtonPressed = false;
                              resetProgress();
                              stopProgress();
                              emergencyTimer?.cancel();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  height: SizeConfig.screenWidth * 0.15,
                                  width: SizeConfig.screenWidth * 0.15,
                                  child: new Image(
                                      image: AssetImage(
                                          'assets/icons/Icons-29_small.png'))),
                            ),
                          )
                        : Container(),
                  ],
                ),
              )
            : Container(),
        showContact ? contactScreen() : Container(),
        SizedBox(
          height: SizeConfig.screenHeight * 0.05,
        ),
        !showContact
            ? (!reqButtonPressed)
                ? Column(
                    children: [
                      Text(
                          context
                                  .read(groupChangeProvider)
                                  .getActiveButton()
                                  ?.group
                                  ?.name ??
                              "",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                      Text(
                          (context
                                          .read(groupChangeProvider)
                                          .getActiveButton()
                                          ?.group
                                          ?.getOnlineUsers()
                                          ?.length ??
                                      0)
                                  .toString() +
                              " online",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF41AD49),
                          )),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.05,
                      ),
                      Container(
                        height: SizeConfig.screenWidth * 0.7,
                        width: SizeConfig.screenWidth * 0.7,
                        child: GestureDetector(
                          onHorizontalDragEnd: (value) {
                            setState(() {
                              if (buttonState != PTTButtonEnum.INCOMING &&
                                  !isEmergencyCall) {
                                groupCall.add(null);
                                buttonState = PTTButtonEnum.UP;
                                _engine.stopGroupCall();
                              }
                            });
                          },
                          onTapDown: (value) {
                            setState(() {
                              if (buttonState != PTTButtonEnum.INCOMING) {
                                buttonState = PTTButtonEnum.DOWN;
                                groupCall.add(context
                                    .read(groupChangeProvider)
                                    .getActiveButton()
                                    ?.group
                                    ?.id);
                              }
                            });
                          },
                          onTapUp: (value) {
                            setState(() {
                              if (buttonState != PTTButtonEnum.INCOMING &&
                                  !isEmergencyCall) {
                                groupCall.add(null);
                                buttonState = PTTButtonEnum.UP;
                                _engine.stopGroupCall();
                              }
                            });
                          },
                          child: Container(
                            height: SizeConfig.screenWidth * 0.8,
                            width: SizeConfig.screenWidth * 0.8,
                            child: buttonState == PTTButtonEnum.DOWN ||
                                    buttonState == PTTButtonEnum.INCOMING
                                ? buttonState == PTTButtonEnum.DOWN
                                    ? new Image(
                                        fit: BoxFit.scaleDown,
                                        image: AssetImage(
                                            'assets/icons/Main_button_red.png'))
                                    : new Image(
                                        fit: BoxFit.scaleDown,
                                        image: AssetImage(
                                            'assets/icons/Main_button_green.png'))
                                : new Image(
                                    fit: BoxFit.scaleDown,
                                    image: AssetImage(
                                        'assets/icons/Main_button_blue.png')),
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Text(
                            !alarmButtonPressed
                                ? "Sending Call Request ..."
                                : "Sending Alarm ...",
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
                  )
            : Container(),
        !showContact
            ? Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                child: Column(
                  children: [
                    new Text(
                        callerName != null
                            ? "${callerName ?? ''} ${incomingCallFlag ? 'talking to' : 'talked to'} ${callerGroup ?? ''}"
                            : "",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ))
                  ],
                ),
              )
            : Container(),
        debugWidget()
      ],
    );
  }

  Widget profileScreen() {
    return MaterialApp(
      color: Colors.grey[100],
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, top: 8.0),
                  child:
                      new Image(image: AssetImage("assets/icons/profile.png")),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    _loginConfig.name,
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Device Connection", style: TextStyle(fontSize: 17)),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: new Image(
                        image: AssetImage(isPTTDeviceConnected
                            ? "assets/icons/icon_connected_small.png"
                            : "assets/icons/icon_disconnected_small.png")),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0,
              thickness: 0.5,
              endIndent: 0,
              indent: 0,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Service Connection", style: TextStyle(fontSize: 17)),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: new Image(
                        image: AssetImage(currentState != "StateRegister"
                            ? "assets/icons/icon_connected_small.png"
                            : "assets/icons/icon_disconnected_small.png")),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0,
              thickness: 0.5,
              endIndent: 0,
              indent: 0,
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(25.0, 5.0, 25.0, 5.0),
                child: const Text(
                  'Buttons',
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            context.read(groupChangeProvider).getGroups().length > 0
                ? Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PTT 1',
                                style: TextStyle(
                                  fontSize: 15.0,
                                ),
                              ),
                              IgnorePointer(
                                ignoring: context
                                    .read(groupChangeProvider)
                                    .ptt1
                                    .isLocked,
                                child: DropdownButton<String>(
                                  value: context
                                      .read(groupChangeProvider)
                                      .ptt1
                                      ?.group
                                      ?.id,
                                  items: context
                                      .read(groupChangeProvider)
                                      .getGroups()
                                      .map((group) {
                                    return DropdownMenuItem<String>(
                                      value: group.id,
                                      child: Text(group.name,
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  })?.toList(),
                                  onChanged: (String val) {
                                    setState(() {
                                      context
                                          .read(groupChangeProvider)
                                          .setPTT1(val);
                                      // groupChange.add(true);
                                      // changeGroupFlag = true;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                      activeColor: Colors.red,
                                      value: context
                                          .read(groupChangeProvider)
                                          .ptt1
                                          .isLocked,
                                      onChanged: (result) {
                                        setState(() {
                                          context
                                              .read(groupChangeProvider)
                                              .setPTT1Lock(result);
                                          // lockPtt1 = result;
                                        });
                                      }),
                                  Text("Lock")
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PTT 2',
                                style: TextStyle(
                                  fontSize: 15.0,
                                ),
                              ),
                              IgnorePointer(
                                ignoring: context
                                    .read(groupChangeProvider)
                                    .ptt2
                                    .isLocked,
                                child: DropdownButton<String>(
                                  value: context
                                      .read(groupChangeProvider)
                                      .ptt2
                                      ?.group
                                      ?.id,
                                  items: context
                                      .read(groupChangeProvider)
                                      .getGroups()
                                      .map((group) {
                                    return DropdownMenuItem<String>(
                                      value: group.id,
                                      child: Text(group.name,
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  })?.toList(),
                                  onChanged: (String val) {
                                    setState(() {
                                      context
                                          .read(groupChangeProvider)
                                          .setPTT2(val);
                                      // groupChange.add(true);
                                      //changeGroupFlag = true;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                      activeColor: Colors.red,
                                      value: context
                                          .read(groupChangeProvider)
                                          .ptt2
                                          .isLocked,
                                      onChanged: (result) {
                                        setState(() {
                                          context
                                              .read(groupChangeProvider)
                                              .setPTT2Lock(result);
                                          // lockPtt2 = result;
                                        });
                                      }),
                                  Text("Lock")
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: Text("No Groups")),
            debugWidget(),
          ],
        ),
      ),
    );
  }

  Widget contactScreen() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              "Contacts:",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          _loginConfig.callReq
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 28, top: 15, bottom: 15),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF6DC3C9),
                        padding: EdgeInsets.all(10.0),
                        onPrimary: Colors.white,
                        onSurface: Colors.grey,
                        shadowColor: Colors.grey,
                        elevation: 5,
                        shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset("assets/icons/phone_small.png"),
                          Text(' CALL REQUEST TO DISPATCHER'),
                          SizedBox(width: 1)
                        ],
                      ),
                      // label: Padding(
                      //   padding: const EdgeInsets.only(right:25.0),
                      //   child: Text('Call Request to Dispatcher'),
                      // ),
                      // icon: Padding(
                      //   padding: const EdgeInsets.only(right:18.0),
                      //   child: Image.asset("assets/icons/phone_small.png"),
                      // ),
                      onPressed: () {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(
                              'Call Request Sent',
                              style: TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                            behavior: SnackBarBehavior.floating,
                            width: MediaQuery.of(context).size.width * 0.4,
                            backgroundColor: Colors.grey,
                            duration: Duration(milliseconds: 500),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(100)))));
                        _engine.sendCallRequest();
                      },
                    ),
                  ),
                )
              : SizedBox(),
          stateRiverpod.Consumer(builder: (context, watch, child) {
            var contactList = watch(groupChangeProvider).users;
            contactList?.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return contactList.length != 0
                ? Container(
                    height: SizeConfig.screenHeight * 0.60,
                    child: ListView.builder(
                        //physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: contactList.length,
                        itemBuilder: (BuildContext ctx, int index) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              showPlatformDialog(
                                context: context,
                                barrierDismissible: true,
                                androidBarrierDismissible: true,
                                builder: (_) => Theme(
                                  data: ThemeData.light(),
                                  child: DialogCallLocate(
                                      context: context,
                                      name: contactList[index].name,
                                      onLocate: () {
                                        Navigator.of(context).pop();
                                        locateUser(contactList[index]);
                                      },
                                      onPrivateCall: () {
                                        Navigator.of(context).pop(true);
                                        startPrivateCall(contactList[index]);
                                      },
                                      onCancel: () {
                                        Navigator.of(context).pop();
                                      }),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Container(
                                          child: Icon(
                                            checkOnlineStatus(contactList[index]
                                                    .lastActive)
                                                ? Icons.circle
                                                : Icons.stop_circle_outlined,
                                            size: 15,
                                            color: checkOnlineStatus(
                                                    contactList[index]
                                                        .lastActive)
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        contactList[index].name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Divider(
                                      height: 0,
                                      thickness: 0.5,
                                      endIndent: 0,
                                      indent: 0,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                  )
                : Center(
                    child: Text(
                      "No Contacts ",
                      style: TextStyle(fontSize: 20),
                    ),
                  );
          }),
          SizedBox(
            height: 200,
          )
        ],
      ),
    );
  }

  startPrivateCall(User user) {
    // TODO change to User
    _engine.startPrivateCall(user.id);
    setState(() {
      _caller = user.name;
    });
  }

  locateUser(User user) {
    onTabChange(2);
    if (user.latitude != null && user.longitude != null) {
      _mapController.move(
          LatLng(user.latitude, user.longitude), _mapController.zoom);
    } else {
      Fluttertoast.showToast(
          msg: "No location found on map",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.grey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Widget groupsScreen() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              "Talk Groups",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          context.read(groupChangeProvider).getGroups().length == 0
              ? Center(
                  child: Text(
                    "Loading ... ",
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : context.read(groupChangeProvider).getGroups().length > 0
                  ? Expanded(
                      child: ListView.builder(
                      itemCount: context
                          .read(groupChangeProvider)
                          .getGroups()
                          .length, // your List
                      itemBuilder: (context, index) {
                        var provider = context.read(groupChangeProvider);
                        var group = provider.getGroups()[index];

                        var isPTT1 = provider.ptt1?.group?.id == group.id;
                        var isPTT2 = provider.ptt2?.group?.id == group.id;
                        var suffix = (isPTT1 && isPTT2)
                            ? "PTT 1 / PTT 2"
                            : (isPTT1 ? "PTT 1" : (isPTT2 ? "PTT 2" : ""));

                        return ExpandableListView(
                          // TODO why this much of shit here??
                          pttListening: suffix,
                          groupName: group.name,
                          groupKey: group.id,
                          usersList: group.getOnlineUsers(),
                          onLocate: (user) {
                            locateUser(user);
                          },
                          onPrivateCall: (user) {
                            startPrivateCall(user);
                          },
                        );
                      },
                    ))
                  : Center(
                      child: Text(
                        "No groups",
                        style: TextStyle(fontSize: 20),
                      ),
                    )
        ],
      ),
    );
  }

  Widget debugWidget() {
    return context.read(showDebugProvider).state
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("State : $currentState"),
                // GestureDetector(
                //   onLongPress: () async {
                //     final data = ClipboardData(text: _pushToken);
                //     await Clipboard.setData(data);
                //   },
                //   child: Text("Push token : $_pushToken"),
                // ),
                // SizedBox(
                //   height: 20,
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Listener(
                      onPointerDown: (details) {
                        onPTT1ButtonDown();
                      },
                      onPointerUp: (details) {
                        onPTT1ButtonUp();
                      },
                      child: RaisedButton(
                        onPressed: () {},
                        color: _ptt1Down ? Colors.green : Colors.grey,
                        child: Text(
                          "PTT1",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Listener(
                      onPointerDown: (details) {
                        onPTT2ButtonDown();
                      },
                      onPointerUp: (details) {
                        onPTT2ButtonUp();
                      },
                      child: RaisedButton(
                        onPressed: () {},
                        color: _ptt2Down ? Colors.green : Colors.grey,
                        child: Text(
                          "PTT2",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     RaisedButton(
                //         onPressed: () {
                //           onPreviousChannel();
                //         },
                //         color: Colors.orange,
                //         child: new Icon(Icons.arrow_back_ios)),
                //     RaisedButton(
                //         onPressed: () {
                //           onNextChannel();
                //         },
                //         color: Colors.orange,
                //         child: new Icon(Icons.arrow_forward_ios)),
                //   ],
                // )
              ],
            ),
          )
        : Container();
  }

  void setIncomingCallActive(bool bool) {
    if (bool) {
      setState(() {
        buttonState = PTTButtonEnum.INCOMING;
      });
    } else {
      setState(() {
        buttonState = PTTButtonEnum.UP;
      });
    }
  }

  @override
  Future<void> onNewIncomingGroupCall(String groupId, String fromName) async {
    incomingCallFlag = true;
    var provider = context.read(groupChangeProvider);
    var group = provider.getGroup(groupId);

    if (group == null) {
      return;
    }

    bool allowCall = group.isUnmuted() || group.isListen();

    if (!allowCall) {
      return;
    }

    callerName = fromName;
    callerGroup = group.name;

    if (buttonState != PTTButtonEnum.DOWN) {
      PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
      _engine.startIncomingGroupCall(groupId, fromName);
    }
  }

  @override
  Future<void> onIncomingCallEnded() async {
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
    setIncomingCallActive(false);
    setState(() {
      _caller = '';
      incomingCallFlag = false;
    });
  }

  @override
  void onIncomingCallStarted(String fromName, String fromGroup) {
    _bt.enableLed(Led.Green);
    PlaySound.playSound(SoundsEnum.Reception_Start, GlobalConstants.volumeMax);
    setIncomingCallActive(true);
    setState(() {
      _caller = fromName +
          " - " +
          context.read(groupChangeProvider).getGroup(fromGroup).name;
      incomingCallFlag = true;
    });
  }

  @override
  void onOutgoingCallConfirmed() {
    _bt.enableLed(Led.Red);
    PlaySound.playSound(
        SoundsEnum.Transmission_Confirmed, GlobalConstants.volumeMax);
  }

  @override
  void onOutgoingCallStarted() {
    _bt.enableLed(Led.Red);
    PlaySound.playSound(
        SoundsEnum.Transmission_Start, GlobalConstants.volumeMax);
  }

  @override
  void onOutgoingCallEnded() {
    _bt.disableLeds();
    PlaySound.playSound(
        SoundsEnum.Transmission_Stop, GlobalConstants.volumeMax);
  }

  @override
  void onRegistrationExpired() {
    PlaySound.playSound(
        SoundsEnum.SIP_Connection_Lost, GlobalConstants.volumeMax);
  }

  @override
  void onRegistrationFailed() {
    PlaySound.playSound(
        SoundsEnum.SIP_Connection_Lost, GlobalConstants.volumeMax);
  }

  @override
  void onRegistrationSuccesful() {
    // context.read(groupChangeProvider).onGroupChange(); // TODO why this calls onGroupChange()?
    initializeGroups();
    if(_loginConfig.location)
    initializeShareLocation();
    initializePresenceMessage();
    PlaySound.playSound(
        SoundsEnum.SIP_Registration_OK, GlobalConstants.volumeMax);
  }

  @override
  void onStateActivated(String stateName) {
    setState(() {
      currentState = stateName;
    });
  }

  @override
  void onIdleActivated() {
    setIncomingCallActive(false);
  }

  @override
  void onIncomingCallFailed() {
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
    setIncomingCallActive(false);
    setState(() {
      _caller = '';
    });
  }

  @override
  void onOutgoingCallFailed() {
    _bt.disableLeds();
    PlaySound.playSound(
        SoundsEnum.SIP_Connection_Lost, GlobalConstants.volumeMax);
  }

  final PushConnector connector = createPushConnector();
  Future<void> getPushToken() async {
    final connector = this.connector;
    connector.configure(
      onLaunch: (data) => onPush('onLaunch', data),
      onResume: (data) => Future.value(true),
      onMessage: (data) => Future.value(true),
      onBackgroundMessage: (data) => Future.value(true),
    );
    connector.token.addListener(() {
      setState(() {
        // This is commented because of run on simulator
        _engine.start(
            this.server, this._loginConfig.userId, connector.token.value);
      });
    });
    connector.requestNotificationPermissions();
  }

  Future<dynamic> onPush(String name, Map<String, dynamic> payload) {
    if (payload['smalltalk'] != null &&
        payload['smalltalk']['action'] != null) {
      if (payload['smalltalk']['action'] == "Call-Incoming") {
        if (payload['smalltalk']['group_id'] ==
                context.read(groupChangeProvider).ptt1?.group?.id ||
            payload['smalltalk']['group_id'] ==
                context.read(groupChangeProvider).ptt2?.group?.id) {
          _engine.setCallFromPushNotification(payload['smalltalk']['group_id'],
              payload['smalltalk']['from_name']);
        }
      }
    }

    return Future.value(true);
  }

  @override
  void onPrivateIncomingCallConfirmed(String remoteDisplayName) {
    setState(() {
      _caller = remoteDisplayName;
      _callingStatus = "Talking";
      isPrivateCall = true;
      isPrivateCallRinging = false;
      ringTimer?.cancel();
      _bt.enableLed(Led.Green);
    });
  }

  @override
  void onPrivateIncomingCall(SIPCall sipCall) {
    if (msgList.length != 0) {
      Navigator.pop(context);
    }
    setState(() {
      _sipCall = sipCall;
      _caller = sipCall.getRemoteDisplayName();
      _callingStatus = "Ringing";
      isPrivateCall = true;
      isPrivateCallRinging = true;
      ringTimer?.cancel();
      ringTimer =
          Timer.periodic(Duration(seconds: GlobalConstants.ringTimer), (timer) {
        PlaySound.playSound(SoundsEnum.Call_Ring, GlobalConstants.volumeMax);
      });
    });
    _bt.enableLed(Led.Green);
    PlaySound.playSound(SoundsEnum.Call_Ring, GlobalConstants.volumeMax);
  }

  @override
  void onPrivateIncomingCallEnded() {
    setState(() {
      _sipCall = null;
      _caller = '';
      _callingStatus = "Calling";
      isPrivateCall = false;
      isPrivateCallRinging = false;
      ringTimer?.cancel();
    });
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
    checkStatusMessage();
  }

  @override
  void onPrivateOutgoingCallConfirmed() {
    setState(() {
      _callingStatus = "Talking";
      isPrivateCall = true;
      isPrivateCallRinging = false;
    });
    _bt.enableLed(Led.Red);
    PlaySound.playSound(
        SoundsEnum.Reception_Confirmed, GlobalConstants.volumeMax);
  }

  @override
  void onPrivateOutgoingCallEnded() {
    setState(() {
      _caller = '';
      _callingStatus = "Calling";
      isPrivateCall = false;
      isPrivateCallRinging = false;
    });
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
  }

  @override
  Future<void> onPrivateOutgoingCallFailed() async {
    setState(() {
      _caller = '';
      _callingStatus = "Not Available";
    });
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isPrivateCall = false;
      isPrivateCallRinging = false;
    });
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
  }

  @override
  void onPrivateOutgoingCall() {
    setState(() {
      _callingStatus = "Ringing";
      isPrivateCall = true;
      isPrivateCallRinging = false;
    });
  }

  @override
  void onEmergencyOutgoingCall() {
    setState(() {
      _callingStatus = "Ringing";
      isEmergencyCall = true;
    });
    _bt.enableLed(Led.Red);
    PlaySound.playSound(SoundsEnum.Reception_Start, GlobalConstants.volumeMax);
  }

  @override
  void onEmergencyOutgoingCallConfirmed() {
    setState(() {
      _callingStatus = "Talking";
      isEmergencyCall = true;
    });
    PlaySound.playSound(
        SoundsEnum.Reception_Confirmed, GlobalConstants.volumeMax);
  }

  @override
  void onEmergencyOutgoingCallEnded() {
    setState(() {
      _caller = '';
      _callingStatus = "Calling";
      isEmergencyCall = false;
    });
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
  }

  @override
  void onEmergencyIncomingCall(SIPCall sipCall) {
    if (msgList.length != 0) {
      Navigator.pop(context);
    }
    setState(() {
      _caller = sipCall.getRemoteDisplayName();
      _callingStatus = "Ringing";
      isEmergencyCall = true;
    });
    _bt.enableLed(Led.Green);
    PlaySound.playSound(SoundsEnum.Reception_Start, GlobalConstants.volumeMax);
    _engine.answerEmergencyeCall(sipCall);
  }

  @override
  void onEmergencyIncomingCallConfirmed(String remoteDisplayName) {
    setState(() {
      _caller = remoteDisplayName;
      _callingStatus = "Talking";
      isEmergencyCall = true;
    });
  }

  @override
  void onEmergencyIncomingCallEnded() {
    setState(() {
      _caller = '';
      _callingStatus = "Calling";
      isEmergencyCall = false;
    });
    _bt.disableLeds();
    PlaySound.playSound(SoundsEnum.Reception_Stop, GlobalConstants.volumeMax);
    checkStatusMessage();
  }

  @override
  void onFetchingContactList(List<UserContract> contactList) {
    context
        .read(groupChangeProvider)
        .setContactList(contactList.map((contact) => User(contact))?.toList());
  }

  @override
  void onStatusMessage(NewMessageModel newMessage) {
    setState(() {
      msgList[newMessage.messageId] = newMessage;
    });
    if ((!(isPrivateCall || isEmergencyCall) && canShowMessage)) {
      canShowMessage = false;
      showPlatformDialog(
        context: context,
        barrierDismissible: false,
        androidBarrierDismissible: false,
        builder: (_) => Theme(
          data: ThemeData.light(),
          child: PlatformAlertDialog(
            title: Text(newMessage.sender),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                newMessage.message,
                style: TextStyle(fontSize: 15),
              ),
            ),
            actions: <Widget>[
              PlatformDialogAction(
                child: Text(
                  "No",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _engine.statusMessageReply(
                      newMessage.messageId.toString(), "false");
                  setState(() {
                    if (msgList.length == 1) {
                      canShowMessage = true;
                      msgList.clear();
                    } else {
                      msgList.remove(newMessage.messageId);
                      checkStatusMessage();
                    }
                  });
                },
              ),
              PlatformDialogAction(
                  child: Text(
                    "Yes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _engine.statusMessageReply(
                        newMessage.messageId.toString(), "true");
                    setState(() {
                      if (msgList.length == 1) {
                        canShowMessage = true;
                        msgList.clear();
                      } else {
                        msgList.remove(newMessage.messageId);
                        checkStatusMessage();
                      }
                    });
                  }),
            ],
          ),
        ),
      );
    }
  }

  bool checkOnlineStatus(double lastActive) {
    if (lastActive == 0.0) {
      return false;
    }
    var time = DateTime.fromMillisecondsSinceEpoch(lastActive.toInt() * 1000);
    var currentTime = new DateTime.now();
    if (currentTime.difference(time).inMinutes <= 10) {
      return true;
    } else {
      return false;
    }
  }

  @override
  onDeviceConnected() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    await _prefs.then((SharedPreferences prefs) {
      if (prefs.getBool(StringConstants.vibrateWhenConected) ?? true) {
        Vibration.vibrate(duration: 1000);
      }
    });

    context.read(isPTTDeviceConnectedProvider).state = true;
    _engine.isBTDeviceConnected(true);
  }

  @override
  onDeviceDisconnected() {
    context.read(isPTTDeviceConnectedProvider).state = false;
    _engine.isBTDeviceConnected(false);
  }

  @override
  void onPTT1ButtonDown() {
    if (isEmergencyCall) {
      _engine.onEmergencyButtonPressed(EmergencyButtonEventEnum.PRESSED);
    } else if (isPrivateCall) {
    } else {
      if (!_ptt1Down) {
        setState(() {
          _ptt1Down = true;
          _caller = context.read(groupChangeProvider).ptt1?.group?.name;
          buttonState = PTTButtonEnum.DOWN;
          groupCall.add(context.read(groupChangeProvider).ptt1?.group?.id);
        });
      }
    }
  }

  @override
  void onPTT1ButtonUp() {
    if (isEmergencyCall) {
      _engine.onEmergencyButtonPressed(EmergencyButtonEventEnum.RELEASED);
    } else if (isPrivateCall) {
    } else {
      if (_ptt1Down) {
        setState(() {
          _ptt1Down = false;
          _caller = "";
          buttonState = PTTButtonEnum.UP;
          groupCall.add(null);
          _engine.stopGroupCall();
        });
      }
    }
  }

  @override
  void onPTT2ButtonDown() {
    if (isEmergencyCall) {
      _engine.onEmergencyButtonPressed(EmergencyButtonEventEnum.PRESSED);
    } else if (isPrivateCall) {
    } else {
      if (!_ptt2Down) {
        setState(() {
          _caller = context.read(groupChangeProvider).ptt2?.group?.name;
          buttonState = PTTButtonEnum.DOWN;
          _ptt2Down = true;
          groupCall.add(context.read(groupChangeProvider).ptt2?.group?.id);
        });
      }
    }
  }

  @override
  void onPTT2ButtonUp() {
    if (isEmergencyCall) {
      _engine.onEmergencyButtonPressed(EmergencyButtonEventEnum.RELEASED);
    } else if (isPrivateCall) {
    } else {
      if (_ptt2Down) {
        setState(() {
          _ptt2Down = false;
          _caller = "";
          buttonState = PTTButtonEnum.UP;
          groupCall.add(null);
          _engine.stopGroupCall();
        });
      }
    }
  }

  @override
  onNextChannel() async {
    if (!context.read(groupChangeProvider).ptt1.isLocked) {
      // TODO: now we have locks in groupChangeprovider, but still we check this here?
      context.read(groupChangeProvider).onNextChannel(1);
      await speak("Channel " +
          context
              .read(groupChangeProvider)
              .ptt1
              ?.group
              ?.name); // TODO:, can we put some one listener that will listen active group changes and then speak just in one place??
    } else if (!context.read(groupChangeProvider).ptt2.isLocked) {
      context.read(groupChangeProvider).onNextChannel(2);
      await speak(
          "Channel " + context.read(groupChangeProvider).ptt2?.group?.name);
    }
  }

  @override
  onPreviousChannel() async {
    if (!context.read(groupChangeProvider).ptt1.isLocked) {
      context.read(groupChangeProvider).onPreviousChannel(1);

      await speak(
          "Channel " + context.read(groupChangeProvider).ptt1?.group?.name);
    } else if (!context.read(groupChangeProvider).ptt2.isLocked) {
      context.read(groupChangeProvider).onPreviousChannel(2);
      await speak(
          "Channel " + context.read(groupChangeProvider).ptt2?.group?.name);
    }
  }

  @override
  onMultifunctionLongPress() {
    if (isPrivateCall) {
      if (!isPrivateCallRinging) {
        _engine.hangup();
      } else {
        _engine.reject(_sipCall);
      }
    }
  }

  @override
  onMultifunctionPress() {
    if (isPrivateCall) {
      if (isPrivateCallRinging) {
        _engine.answerPrivateCall(_sipCall);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _engine.activateForeground();
        break;
      case AppLifecycleState.paused:
        Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
        _prefs.then((SharedPreferences prefs) {
          _engine.activateBackground(
              prefs.getBool(StringConstants.isBGCallAllowed) ?? true);
        });
        break;
      case AppLifecycleState.detached:
        _engine.sendGroupChange(new List());
        break;
    }
  }

  void checkStatusMessage() {
    canShowMessage = true;
    if (msgList?.length != 0) {
      onStatusMessage(msgList.values.elementAt(0));
    }
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");

    await flutterTts.setSpeechRate(0.5);

    await flutterTts.setVolume(1.0);

    await flutterTts.setPitch(1.0);
    await flutterTts.setSharedInstance(true);
    flutterTts.setCompletionHandler(() {
      // context.read(groupChangeProvider).onGroupChange(); // why this changes group??
      // _engine
      //     .setActiveGroup(context.read(groupChangeProvider).getActiveGroup()); // why this sets active group??
      //_engine.startBackgroundCall();
    });
  }

  Future<void> speak(String speech) async {
    speechTimer?.cancel();
    speechTimer =
        Timer(Duration(milliseconds: GlobalConstants.groupChangeDebounceTime),
            () async {
      await flutterTts.speak(speech);
    });
  }

  void initializeGroups() {
    context.read(groupChangeProvider).setEngine(
        _engine); // TODO: where can pass thiss!???  -> Need to make singleton in refactoring
    context
        .read(groupChangeProvider)
        .setGroupDetails(_loginConfig); // TODO: do not pass whole contract
  }

  @override
  void onGroupChange(GroupChangeUserModel groupChangeUserModel) {
    context.read(groupChangeProvider).onGroupChange(groupChangeUserModel);
  }

  bool isLocationEnabled() {
    return _loginConfig.location;
  }

  void initializeShareLocation() {
    _engine.startSharingLocation();
  }

  void initializePresenceMessage() {
    _engine.startPresenceMessage();
  }
}
