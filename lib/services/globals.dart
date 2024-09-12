library pasthelwparking_v1.globals;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;

bool heroOverlay = false;
bool searching = false;

cancelSearch() async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.delete(Uri.parse("http://192.168.1.26:3000/cancel-search"),
        body: cnv.jsonEncode({"user_id": userId}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

deleteLeaving(int latestLeavingID) async {
  try {
    await http.delete(Uri.parse("http://192.168.1.26:3000/delete-leaving"),
        body: cnv.jsonEncode({"leavingID": latestLeavingID}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

postSkip(timesSkipped, time, latitude, longitude, latestLeavingID) async {
  try {
    await http.post(Uri.parse("http://192.168.1.26:3000/parking-skipped"),
        body: cnv.jsonEncode({
          "times_skipped": timesSkipped,
          "time": time,
          "latitude": latitude,
          "longitude": longitude,
          "latestLeavingID": latestLeavingID
        }),
        headers: {"Content-Type": "application/json"});
  } catch (e) {}
}

getPoints() async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("http://192.168.1.26:3000/get-points"),
        body: cnv.jsonEncode({"user_id": userId}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}

updatePoints(int? updatedPoints) async {
  final prefs = await SharedPreferences.getInstance();
  var userId = prefs.getString('userid');
  try {
    await http.post(Uri.parse("http://192.168.1.26:3000/update-points"),
        body: cnv.jsonEncode({"user_id": userId, "points": updatedPoints}),
        headers: {"Content-Type": "application/json"});
  } catch (e) {
    print(e);
  }
}
