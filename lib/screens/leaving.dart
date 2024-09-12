import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pasthelwparking_v1/model/pushnotificationModel.dart';
import 'package:http/http.dart' as http;

class Leaving extends StatefulWidget {
  @override
  _LeavingPageState createState() => _LeavingPageState();
}

class _LeavingPageState extends State<Leaving> {
  PushNotification? notification;
  String? token;
  DateTime? notifReceiveTime;

  _getDevToken() async {
    token = await FirebaseMessaging.instance.getToken();
    print("DEV TOKEN FIREBASE CLOUD MESSAGING -> $token");
  }

  checkForInitialState() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      print('initialMessage data: ${initialMessage?.data}');
      if (initialMessage != null) {
        PushNotification(
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
        );
      }
    });
  }

  @override
  void initState() {
    _getDevToken();
    checkForInitialState();
    super.initState();
    _determinePosition();
  }

  Position? _currentPosition;

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
    setState(() {
      _currentPosition = position;
    });
  }

  postData2() async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/leaving.php"),
          body: {
            "lat": _currentPosition?.latitude.toString(),
            "long": _currentPosition?.longitude.toString()
          });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //Text("A parking spot is free for you!"),
            TextButton(
              child: Text("Leaving"),
              onPressed: () {
                postData2();
                setState(() {
                  _determinePosition();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
