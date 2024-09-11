// import 'dart:async';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:mysql1/mysql1.dart';
// import 'package:pasthelwparking_v1/services/push_notification_service.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class LeavingObject {
//   final int id;
//   final double latitude;
//   final double longitude;
//   final String userID;

//   LeavingObject(this.id, this.latitude, this.longitude, this.userID);
// }

// class MyDatabase extends StatefulWidget {
//   @override
//   _MyDatabaseState createState() => _MyDatabaseState();
// }

// class _MyDatabaseState extends State<MyDatabase> {
//   final settings = ConnectionSettings(
//     host: '192.168.1.26',
//     port: 3306,
//     user: 'marios',
//     password: '123456789',
//     db: 'pasthelwparking',
//   );
//   StreamController<Results> _streamController = StreamController<Results>();
//   late Timer timer;
//   late int leavingsCountNew;
//   int? leavingsCountOld;
//   late int latestRecordID;

//   final channel = WebSocketChannel.connect(
//     Uri.parse('ws://192.168.1.26:3000'),
//   );

//   Future<http.Response> fetchAlbum() {
//     return http.get(Uri.parse('http://192.168.1.26:3000/track-changes'));
//   }

//   Future<MySqlConnection> _connect() async {
//     return await MySqlConnection.connect(settings);
//   }

//   Future trackChanges() async {
//     _connect().then((connection) {
//       connection
//           .query(
//               'SELECT COUNT(*) FROM leaving UNION SELECT ID FROM leaving WHERE time=(SELECT MAX(time) FROM leaving)')
//           .then((results) {
//         //print(results);
//         leavingsCountNew = results.first.fields.values.first;
//         //print(leavingsCountNew);
//         if (!(leavingsCountOld == null)) {
//           if (leavingsCountNew != leavingsCountOld) {
//             print("Change detected");
//             latestRecordID = results.last.fields.values.first;
//             connection
//                 .query(
//                     'SELECT latitude, longitude FROM leaving WHERE id=$latestRecordID')
//                 .then((coordinatesResult) {});
//             NotificationController.createNewNotification();
//             leavingsCountOld = leavingsCountNew;
//           }
//         } else {
//           leavingsCountOld = leavingsCountNew;
//         }
//         _streamController.add(results);
//       });
//     });
//   }

//   @override
//   void initState() {
//     fetchAlbum();

//     /// Listen for all incoming data
//     channel.stream.listen(
//       (data) {
//         print(data);
//         NotificationController.createNewNotification();
//       },
//       onError: (error) => print(error),
//     );
//     //trackChanges();
//     //timer =
//     //Timer.periodic(const Duration(seconds: 1), (timer) => trackChanges());
//     super.initState();
//   }

//   @override
//   void dispose() {
//     //cancel the timer
//     if (timer.isActive) timer.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<MySqlConnection>(
//         future: _connect(),
//         builder:
//             (BuildContext context, AsyncSnapshot<MySqlConnection> snapshot) {
//           if (snapshot.hasData) {
//             return StreamBuilder(
//               stream: _streamController.stream,
//               //_streamController.stream, //Stream.fromFuture(
//               //snapshot.data!.query('SELECT * FROM leaving')),
//               builder: (BuildContext context, AsyncSnapshot snapshot) {
//                 if (snapshot.hasData) {
//                   //print("new data" + snapshot.data.toString());
//                   // Render the table rows using the data from the snapshot
//                   return ListView.builder(
//                     itemCount: snapshot.data?.length,
//                     itemBuilder: (BuildContext context, int index) {
//                       return ListTile(
//                         title: Text(snapshot.data.toString()),
//                       );
//                     },
//                   );
//                 } else if (snapshot.hasError) {
//                   // Handle any errors that occur while fetching the data
//                   return Text('Error: ${snapshot.error}');
//                 } else {
//                   // Show a loading indicator while waiting for the data
//                   return CircularProgressIndicator();
//                 }
//               },
//             );
//           } else if (snapshot.hasError) {
//             // Handle any errors that occur while connecting to the database
//             return Text('Error: ${snapshot.error}');
//           } else {
//             // Show a loading indicator while waiting for the connection
//             return CircularProgressIndicator();
//           }
//         },
//       ),
//     );
//   }
// }
