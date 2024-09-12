import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:pasthelwparking_v1/screens/claim.dart';
import 'package:pasthelwparking_v1/screens/enableLocation.dart';
import 'package:pasthelwparking_v1/screens/login.dart';
import 'package:pasthelwparking_v1/services/push_notification_service.dart';
import 'screens/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pasthelwparking_v1/model/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert' as cnv;
import 'model/notifications.dart';
import 'services/SqliteService.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationController.initializeLocalNotifications();
  runApp(const MyApp());
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message");
  NotificationController.createNewNotification();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
        child: MaterialApp(
      title: 'pasthelwparking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      //home: MyDatabase(),
      //home: IntroScreen(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //initialize firebase values
  late final FirebaseMessaging _messaging;
  PushNotification? notification;
  String? token, address, fcm_token;
  DateTime? notifReceiveTime;
  Position? _currentPosition;
  double height = 100;

  double width = 100;

  double latitude = 0, longitude = 0;

  int index = 0, count = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  late Future _getPosition;

  OverlayState? overlayState;

  SqliteService sqliteService = SqliteService();

  bool? entered;
  var page;
  //late SharedPreferences prefs;
  String? s_uid;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  late String serviceStatusValue;

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp();
    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Parse the message received
        notifReceiveTime = DateTime.now();
        postInsertTime();
        notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );
        if (notification != null) {
          getLatLon(message.data["user_id"]);
          // For displaying the notification as an overlay
          // showSimpleNotification(
          //   Text(notification!.title!),
          //   subtitle: Text(notification!.body!),
          //   background: Colors.cyan.shade700,
          //   duration: Duration(seconds: 2),
          // );
          // NotificationController.createNewNotification();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ClaimPage(
                  int.parse(message.data["latestLeavingID"]),
                  message.data["user_id"],
                  double.parse(message.data["lat"]),
                  double.parse(message.data["long"]),
                  message.data["cartype"],
                  int.parse(message.data["times_skipped"]),
                  message.data["time"])));
          Notifications ntf = Notifications.empty();
          ntf.address = address.toString();
          ntf.carType = "Sedan";
          ntf.time = message.data["time"];
          ntf.status = "Pending";
          ntf.entry_id = message.data["id"].toString();
          //_show(message.data, token);
          setState(() {});
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future notificationsCount() async {
    count = await SqliteService().getNotificationCount();
  }

  postInsertTime() async {
    try {
      var response = await http.post(
          //Uri.parse("http://192.168.1.26:8080/pasthelwparking/searching.php"), //vm
          Uri.parse("https://pasthelwparkingv1.000webhostapp.com/php/insert_time.php"),
          body: {"time": '$notifReceiveTime', "uid": '$token'});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  getLatLon(userid) async {
    var response = await http.post(
        Uri.parse("http://192.168.1.26:3000/get-latlon"),
        body: cnv.jsonEncode({"userid": userid}),
        headers: {"Content-Type": "application/json"});
    if (response.body.isNotEmpty) {
      Map<String, dynamic> jsonData = cnv.jsonDecode(response.body);
      latitude = jsonData['results'][0]['center_latitude'];
      longitude = jsonData['results'][0]['center_longitude'];
    }
  }

  getUserID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email");
      var response = await http.post(
          Uri.parse("http://192.168.1.26:3000/get-userid"),
          body: cnv.jsonEncode({"email": email.toString()}),
          headers: {"Content-Type": "application/json"});
      if (response.body.isNotEmpty) {
        var decoded = cnv.jsonDecode(response.body);
        token = decoded["user_id"];
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future registerFcmToken() async {
    try {
      await getUserID();
      await _getDevToken();
      var userId = token;
      http.post(Uri.parse("http://192.168.1.26:3000/register-fcmToken"),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "fcm_token": fcm_token.toString()
          }),
          headers: {"Content-Type": "application/json"});
    } catch (e) {}
  }

  checkForInitialState() async {
    //await Firebase.initializeApp();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      print('initialMessage data: ${initialMessage?.data}');
      if (initialMessage != null) {
        // PushNotification notification = PushNotification(
        //   title: initialMessage.notification?.title,
        //   body: initialMessage.notification?.body,
        // );
        NotificationController.createNewNotification();
      }
    });
  }

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    // app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // PushNotification notification = PushNotification(
      //   title: message.notification?.title,
      //   body: message.notification?.body,
      // );
      //NotificationController.createNewNotification();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ClaimPage(
              int.parse(message.data["latestLeavingID"]),
              message.data["user_id"],
              double.parse(message.data["lat"]),
              double.parse(message.data["long"]),
              message.data["cartype"],
              int.parse(message.data["times_skipped"]),
              message.data["time"])));
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    //when app is terminated
    checkForInitialState();

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getPosition = _determinePosition();
    registerNotification();
    overlayState = Overlay.of(context);
    _toggleServiceStatusStream();
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        print("???resumed");
        if (serviceStatusValue == 'enabled') {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MyHomePage()),
              (Route route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => EnableLocation()),
              (Route route) => false);
        }
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        print("???inactive");
        break;
      case AppLifecycleState.paused:
        // widget is paused
        print("???paused");
        break;
      case AppLifecycleState.detached:
        // widget is detached
        print("???detached");
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        break;
    }
  }

  _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        if (serviceStatus == ServiceStatus.enabled) {
          updateStatus('enabled');
        } else {
          updateStatus('disabled');
        }
      });
    }
  }

  void updateStatus(String value) {
    if (serviceStatusValue != value) {
      setState(() {
        serviceStatusValue = value;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (BuildContext context) => super.widget));
      });
    }
  }

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceStatusValue = 'disabled';
      return Future.error('Location services are disabled.');
    } else {
      serviceStatusValue = 'enabled';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentPosition = position;
        address =
            "${place.locality}, ${place.subLocality},${place.street}, ${place.postalCode}";
        print("///// $address");
      });
    } catch (e) {
      print(e);
    }
  }

  Future sharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //await prefs.clear();
    entered = prefs.getBool("isLoggedIn");
  }

  Future _getDevToken() async {
    fcm_token = await FirebaseMessaging.instance.getToken();
    print("DEV TOKEN FIREBASE CLOUD MESSAGING -> $fcm_token");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          _getPosition,
          registerFcmToken(),
          notificationsCount(),
          sharedPref()
        ]),
        builder: (context, snapshot) {
          // Future done with no errors
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            if (entered == null || entered == false) {
              return LoginPage();
            } else {
              return HomePage(address, token, _currentPosition!.latitude,
                  _currentPosition!.longitude, count);
            }
          }

          // Future with some errors
          else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return EnableLocation();
          } else {
            return Scaffold(
              body: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: MediaQuery.of(context).size.width / 1.5,
                  child: CircularProgressIndicator(strokeWidth: 10),
                ),
              ),
            );
          }
        });
  }
}
