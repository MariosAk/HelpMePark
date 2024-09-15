import 'dart:async';
//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:pasthelwparking_v1/model/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:show_up_animation/show_up_animation.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert' as cnv;
import 'overlays/buttonOverlay.dart';
import 'overlays/buttonOverlayRight.dart';
import 'package:badges/badges.dart' as bdg;
import 'package:square_percent_indicater/square_percent_indicater.dart';
import 'package:pasthelwparking_v1/services/globals.dart' as globals;
import 'package:pasthelwparking_v1/screens/notifications_page.dart'
    as notificationPage;

class HomePage extends StatefulWidget {
  String? address, token;
  double latitude;
  double longitude;
  int notificationCount;
  HomePage(this.address, this.token, this.latitude, this.longitude,
      this.notificationCount,
      {super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  PushNotification? notification;
  String? token, address;
  DateTime? notifReceiveTime;
  double height = 100;

  double width = 100;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  bool leaving = false;

  bool isSelected = false;
  bool _searchingTextfield = false;
  double? containerHeight, containerWidth, x, y;

  double _spreadRadius = 7;
  AnimationController? _animationController;

  Animation<double>? _animation;

  String ApiKey = 'AIzaSyBghQsgXKFjMw5LG79JTmLNgibSc2atYZM';
  String TomTomApiKey = 'qa5MzxXesmBUxRLaWQnFRmMZ2D33kE7b';
  final _controller = TextEditingController();
  String searchTxt = "";
  String lat = "";
  String lon = "";
  final MapController _mapctl = MapController();
  TextEditingController textController = TextEditingController();

  int value = 0;
  late Timer timer;
  late int leavingsCountNew;
  int? leavingsCountOld;
  late int latestRecordID;
  String userID = "";

  // final channel = WebSocketChannel.connect(
  //   Uri.parse('ws://192.168.1.26:3000'),
  // );
  final settings = ConnectionSettings(
    host: '192.168.1.26',
    port: 3306,
    user: 'marios',
    password: '123456789',
    db: 'pasthelwparking',
  );

  Future<http.Response> fetchChanges() {
    return http.get(Uri.parse('http://192.168.1.26:3000/track-changes'));
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    fetchChanges();

    /// Listen for all incoming data
    // channel.stream.listen(
    //   (data) {
    //     print(data);
    //     if (data.toString().contains("userIDForCache")) {
    //       var obj = cnv.jsonDecode(data);
    //       updateUserId(obj);
    //       userID = obj['userIDForCache'];
    //     } else if (data.toString().contains("_latitude")) {
    //       data = cnv.jsonDecode(data);
    //       print(data);
    //       print(data["_latitude"]);
    //       NotificationController.createNewNotification();
    //       Navigator.of(context).push(MaterialPageRoute(
    //           builder: (context) => ClaimPage(
    //               data["latestLeavingID"],
    //               userID,
    //               data["_latitude"],
    //               data["_longitude"],
    //               data["carType"],
    //               data["times_skipped"],
    //               data["time"])));
    //     }
    //   },
    //   onError: (error) => print(error),
    // );
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _animation = Tween<double>(begin: 1.0, end: 2.2).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn));
    timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      setState(() {
        value = (value + 1) % 100;
      });
    });
    //_determinePosition();
    //registerNotification();
  }

  updateUserId(obj) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    http.put(Uri.parse("http://192.168.1.26:3000/update-userid"),
        body: cnv.jsonEncode({
          "user_id": obj['userIDForCache'],
          "email": prefs.getString("email")
        }),
        headers: {"Content-Type": "application/json"});
    prefs.setString("userid", obj['userIDForCache']);
  }

  void _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {});
  }

  Future<String> addSearching() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('userid');
      var response =
          await http.post(Uri.parse("http://192.168.1.26:3000/add-searching"),
              body: cnv.jsonEncode({
                "user_id": userId.toString(),
                "lat": widget.latitude.toString(),
                "long": widget.longitude.toString()
              }),
              headers: {"Content-Type": "application/json"});
      print(userId.toString() +
          widget.latitude.toString() +
          widget.longitude.toString());
      print(response.body);
      return response.body;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  addLeaving() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('userid');
      var response =
          await http.post(Uri.parse("http://192.168.1.26:3000/add-leaving"),
              body: cnv.jsonEncode({
                "user_id": userId.toString(),
                "lat": widget.latitude.toString(),
                "long": widget.longitude.toString(),
                "uid": widget.token,
                "newParking": "false",
              }),
              headers: {"Content-Type": "application/json"});
      print(userId.toString() +
          widget.latitude.toString() +
          widget.longitude.toString());
      print(response.body);
      return response.body;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  updateCenterData() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('userid');
    try {
      http.post(Uri.parse("http://192.168.1.26:3000/update-center"),
          body: cnv.jsonEncode({
            "lat": widget.latitude.toString(),
            "long": widget.longitude.toString(),
            "user_id": userId
          }),
          headers: {"Content-Type": "application/json"});
    } catch (e) {
      print(e);
    }
  }

  useridExists(userid) async {
    try {
      var response = await http
          .post(Uri.parse("http://192.168.1.26:3000/userid-exists"), body: {
        "user_id": userid,
      });
      var data = response.body;
      return data;
    } catch (e) {
      print(e);
    }
  }

  Future<List> getSelectionPosition(value) async {
    List<dynamic> locationList = [];
    var encstr = Uri.encodeComponent(value);
    var response = await http.get(Uri.parse(
        'https://api.tomtom.com/search/2/search/$encstr.json?key=$TomTomApiKey&language=el-GR&limit=1&countrySet=GR&idxSet=POI,PAD,Addr,Str'));
    var datajson = cnv.jsonDecode(response.body)["results"];
    for (var i = 0; i < datajson.length; i++) {
      var pair = {
        'lat': datajson[i]["position"]["lat"].toString(),
        'lon': datajson[i]["position"]["lon"].toString(),
      };
      locationList.add(pair);
    }
    return locationList;
  }

  Future<List> getAddress(value) async {
    List resultList = [];
    var encstr = Uri.encodeComponent(value);
    var response = await http.get(Uri.parse(
        'https://api.tomtom.com/search/2/search/$encstr.json?key=$TomTomApiKey&language=el-GR&limit=4&typeahead=true&countrySet=GR&idxSet=POI,PAD,Addr,Str'));
    var datajson = cnv.jsonDecode(response.body)["results"];
    for (var i = 0; i < datajson.length; i++) {
      /*var pair = {
        'address': datajson[i]["address"]["freeformAddress"].toString(),
        'lat': datajson[i]["position"]["lat"].toString(),
        'lon': datajson[i]["position"]["lon"].toString(),
      };*/
      resultList.add(datajson[i]["address"]["freeformAddress"].toString());
    }
    return resultList;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color.fromRGBO(246, 255, 255, 1.0),
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                "Home",
                style: GoogleFonts.openSans(
                    textStyle: const TextStyle(color: Colors.black)),
              ),
              leading: bdg.Badge(
                badgeContent: Text(
                  widget.notificationCount.toString(),
                  style: GoogleFonts.openSans(
                      textStyle: const TextStyle(color: Colors.white)),
                ),
                position: bdg.BadgePosition.topEnd(top: -2, end: -2),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black38,
                  ),
                  onPressed: () => {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) =>
                                const notificationPage.NotificationPage()))
                        .then((value) => setState(() {
                              widget.notificationCount = value;
                            })),
                    print("notifications")
                  },
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showGifSearching
                      ? Container(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 100,
                                child: Container(
                                  width: 260,
                                  height: 280,
                                  decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(100)),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          'https://i.giphy.com/media/fan5q5SIksKGWUzV5D/200.gif'),

                                      //width: 200,

                                      fit: BoxFit.cover,

                                      //),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  value: 1,
                                ),
                              ),
                              const SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE8B961),

                                  value:
                                      null, // Change this value to update the progress
                                ),
                              ),
                            ],
                          ),
                        )
                      : AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 2000), // Animation speed
                          child: SingleChildScrollView(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Hi, are you leaving or searching?",
                                  style: GoogleFonts.openSans(
                                      textStyle:
                                          const TextStyle(color: Colors.black),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              if (_searchingTextfield)
                                ShowUpAnimation(
                                    delayStart: const Duration(seconds: 0),
                                    animationDuration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.bounceIn,
                                    direction: Direction.horizontal,
                                    offset: 0.5,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 15.0, right: 15.0),
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TypeAheadField(
                                            textFieldConfiguration:
                                                TextFieldConfiguration(
                                              autofocus: true,
                                              controller: textController,
                                              style: GoogleFonts.openSans(
                                                  textStyle: const TextStyle(
                                                      color: Colors.black),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                hintText: 'Enter address..',
                                                contentPadding:
                                                    const EdgeInsets.all(10),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: const BorderSide(
                                                      color: Color.fromRGBO(
                                                          225, 235, 235, 1.0),
                                                      width: 2),
                                                ),
                                                focusedBorder:
                                                    const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              20.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.blue),
                                                ),
                                              ),
                                            ),
                                            suggestionsCallback:
                                                (pattern) async {
                                              List data;

                                              if (pattern.isEmpty ?? true) {
                                                data = await getAddress(" ");
                                                return data;
                                              }
                                              data = await getAddress(pattern);
                                              return data;
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                leading: const Icon(
                                                    Icons.location_on),
                                                title:
                                                    Text(suggestion.toString()),
                                              );
                                            },
                                            onSuggestionSelected:
                                                (suggestion) async {
                                              if (suggestion == null) return;
                                              var position =
                                                  await getSelectionPosition(
                                                      suggestion);

                                              setState(() {
                                                lat = position[0]['lat'];
                                                lon = position[0]['lon'];

                                                widget.latitude =
                                                    double.parse(lat);
                                                widget.longitude =
                                                    double.parse(lon);
                                                textController.text =
                                                    suggestion.toString();
                                                widget.address =
                                                    suggestion.toString();
                                              });
                                              var latlng = LatLng(
                                                  double.parse(lat),
                                                  double.parse(lon));
                                              double zoom = 14.0;
                                              _mapctl.move(latlng, zoom);
                                              updateCenterData();
                                            },
                                          )),
                                    )),
                              Container(
                                  margin: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        230, 241, 255, 1.0),
                                    border: Border.all(
                                        color: const Color.fromRGBO(
                                            230, 241, 255, 1.0),
                                        width: 10.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  height:
                                      MediaQuery.of(context).size.height / 4,
                                  width: MediaQuery.of(context).size.width,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: FlutterMap(
                                        mapController: _mapctl,
                                        options: MapOptions(
                                            initialCenter: LatLng(
                                                widget.latitude,
                                                widget.longitude),
                                            initialZoom: 14),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                                userAgentPackageName: "com.example.pasthelwparking_v1"
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                width: 80.0,
                                                height: 80.0,
                                                point: LatLng(widget.latitude,
                                                    widget.longitude),
                                                child: const Icon(
                                                  Icons.pin_drop,
                                                  color: Colors.deepOrange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          CircleLayer(
                                            circles: [
                                              CircleMarker(
                                                  //radius marker
                                                  point: LatLng(widget.latitude,
                                                      widget.longitude),
                                                  color: Colors.blue
                                                      .withOpacity(0.3),
                                                  borderStrokeWidth: 3.0,
                                                  borderColor: Colors.blue,
                                                  radius: 100 //radius
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ))),
                              Container(
                                margin: const EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  widget.address!,
                                  style: GoogleFonts.openSans(
                                      textStyle:
                                          const TextStyle(color: Colors.black),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: TextButton(
                                    child: Text(
                                      "Change searching center",
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(
                                              color: Colors.blue.shade600),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.left,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchingTextfield =
                                            !_searchingTextfield;
                                      });
                                    }),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 30),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                        child: ScaleTransition(
                                      scale: _animation!,
                                      child: GestureDetector(
                                        onTapDown: ((details) => {
                                              if (!globals.searching)
                                                {
                                                  print("On tap down"),
                                                  setState(() {
                                                    isSelected = true;
                                                    _spreadRadius = 1;
                                                  })
                                                }
                                            }),
                                        onTapUp: (_) {
                                          if (!globals.searching) {
                                            print("On tap up");
                                            globals.searching = true;
                                            globals.heroOverlay = true;
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                transitionDuration:
                                                    const Duration(seconds: 2),
                                                pageBuilder: (_, __, ___) =>
                                                    const buttonOverlay(),
                                              ),
                                            );
                                            addSearching();
                                            setState(() {
                                              _spreadRadius = 7;
                                            });
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                Hero(
                                                    tag: "searchTile",
                                                    child: Container(
                                                        //width:
                                                        //double.infinity,
                                                        //height: 140,
                                                        margin: const EdgeInsets
                                                            .only(
                                                            left: 15.0,
                                                            right: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color
                                                              .fromRGBO(225,
                                                              235, 235, 1.0),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.5),
                                                              spreadRadius:
                                                                  _spreadRadius,
                                                              blurRadius: 7,
                                                              offset: const Offset(
                                                                  0,
                                                                  3), // changes position of shadow
                                                            ),
                                                          ],
                                                        ),
                                                        alignment:
                                                            Alignment.topCenter,
                                                        child: Image.asset(
                                                            'Assets/Images/carParkbutton.png'))),
                                                if (globals.searching &
                                                    !globals.heroOverlay)
                                                  Positioned.fill(
                                                      child: Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 15.0,
                                                                  right: 3),
                                                          // width: double.infinity,
                                                          //height: 200,
                                                          child:
                                                              SquarePercentIndicator(
                                                                  //width: double
                                                                  //.infinity,
                                                                  //height: double.infinity,
                                                                  //startAngle:
                                                                  // StartAngle
                                                                  //.bottomRight,
                                                                  reverse: true,
                                                                  borderRadius:
                                                                      12,
                                                                  shadowWidth:
                                                                      1.5,
                                                                  progressWidth:
                                                                      3,
                                                                  shadowColor:
                                                                      Colors
                                                                          .white70,
                                                                  progressColor:
                                                                      Colors
                                                                          .blue,
                                                                  progress:
                                                                      value /
                                                                          100))),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 1.0),
                                              child: Hero(
                                                  tag: "leftButton",
                                                  child: globals.searching
                                                      ? ElevatedButton(
                                                          onPressed: () {
                                                            globals
                                                                .cancelSearch();
                                                            globals.searching =
                                                                false;
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                                    const SnackBar(
                                                                        content:
                                                                            Text('Searching was canceled.')));
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            shape:
                                                                const CircleBorder(), //<-- SEE HERE
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5),
                                                          ),
                                                          child: const Icon(
                                                            //<-- SEE HERE
                                                            Icons.close_rounded,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        )
                                                      : ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                            backgroundColor:
                                                                Colors.blue,
                                                            shadowColor:
                                                                Colors.grey,
                                                            elevation: 3,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            32.0)),
                                                            //minimumSize: Size(100, 40),
                                                          ),
                                                          onPressed: () {
                                                            isSelected = true;
                                                            globals.searching =
                                                                true;
                                                            globals.heroOverlay =
                                                                true;
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                              PageRouteBuilder(
                                                                opaque: false,
                                                                transitionDuration:
                                                                    const Duration(
                                                                        seconds:
                                                                            2),
                                                                pageBuilder: (_,
                                                                        __,
                                                                        ___) =>
                                                                    const buttonOverlay(),
                                                              ),
                                                            );
                                                            addSearching();
                                                          },
                                                          child: Text(
                                                            'Search',
                                                            style: GoogleFonts
                                                                .openSans(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        13),
                                                          ),
                                                        )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                    Flexible(
                                        child: ScaleTransition(
                                      scale: _animation!,
                                      child: GestureDetector(
                                        onTapDown: ((details) => {
                                              print("On tap down"),
                                              setState(() {
                                                isSelected = true;
                                                _spreadRadius = 1;
                                              })
                                            }),
                                        onTapUp: (_) async {
                                          print("On tap up");
                                          var exists =
                                              await useridExists(widget.token);
                                          if (exists == 'true') {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'You already told us you are leaving..')));
                                          } else {
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                transitionDuration:
                                                    const Duration(seconds: 2),
                                                pageBuilder: (_, __, ___) =>
                                                    const buttonOverlayRight(),
                                              ),
                                            );
                                            addLeaving();
                                            setState(() {
                                              _spreadRadius = 7;
                                            });
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            Hero(
                                                tag: "leaveTile",
                                                child: Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 15.0,
                                                            left: 3),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromRGBO(
                                                              225,
                                                              235,
                                                              235,
                                                              1.0),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          spreadRadius: 5,
                                                          blurRadius: 7,
                                                          offset: const Offset(
                                                              0,
                                                              3), // changes position of shadow
                                                        ),
                                                      ],
                                                    ),
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: Image.asset(
                                                        'Assets/Images/drifting-car.png'))),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 3.0),
                                              child: Container(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Colors.white,
                                                        backgroundColor:
                                                            Colors.blue,
                                                        shadowColor:
                                                            Colors.grey,
                                                        elevation: 3,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32.0)),
                                                        //minimumSize: Size(100, 40),
                                                      ),
                                                      onPressed: () async {
                                                        var exists =
                                                            await useridExists(
                                                                widget.token);
                                                        if (exists == 'true') {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'You already told us you are leaving..')));
                                                        } else {
                                                          Navigator.of(context)
                                                              .push(
                                                            PageRouteBuilder(
                                                              opaque: false,
                                                              transitionDuration:
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                              pageBuilder: (_,
                                                                      __,
                                                                      ___) =>
                                                                  const buttonOverlayRight(),
                                                            ),
                                                          );
                                                          addLeaving();
                                                        }
                                                      },
                                                      child: Text(
                                                        'Leave',
                                                        style: GoogleFonts
                                                            .openSans(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13),
                                                      ))),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          )),
                        ),

                  if (showGifSearching)
                    Column(children: [
                      const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                              "Searching for parking! We will notify you when a free spot comes up!",
                              textAlign: TextAlign.center)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                          backgroundColor: Colors.white,

                          shadowColor: Colors.white,

                          elevation: 3,

                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0)),

                          minimumSize: const Size(100, 40), //////// HERE
                        ),
                        onPressed: () {
                          //postCancelSearch();

                          showGifSearching = false;

                          setState(() {
                            height = 100;

                            width = 100;
                          });
                        },
                        child: const Text('Cancel'),
                      )
                    ]),

                  if (showGifLeaving)
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 100,
                          child: Container(
                            width: 260,
                            height: 280,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(100)),
                              image: DecorationImage(
                                image: NetworkImage(
                                    'https://i.giphy.com/media/fOab3uALerAtdB6x4T/200.gif'),

                                //width: 200,

                                fit: BoxFit.cover,

                                //),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: 1,
                          ),
                        ),
                        const SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8B961),

                            value:
                                null, // Change this value to update the progress
                          ),
                        ),
                      ],
                    ),

                  if (showGifLeaving)
                    const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                            "Your empty spot has been registered! You just saved someones day!",
                            textAlign: TextAlign.center))

                  //),
                ],
              ),
            ),
          ),
        ));
  }
}
