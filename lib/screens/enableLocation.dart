
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

class EnableLocation extends StatelessWidget {
  const EnableLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          Container(
              color: const Color.fromRGBO(246, 255, 255, 1.0),
              child: SafeArea(
                  child: CircleAvatar(
                backgroundColor: const Color.fromRGBO(246, 255, 255, 1.0),
                radius: 100,
                child: Image.asset('Assets/Images/location.gif'),
              ))),
          Text(
            "Please enable location services.",
            style: GoogleFonts.openSans(
                textStyle: const TextStyle(color: Colors.black),
                fontWeight: FontWeight.w600,
                fontSize: 20),
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shadowColor: Colors.grey,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
            ),
            onPressed: () {
              Geolocator.openLocationSettings();
            },
            child: Text(
              'Settings',
              style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          )
        ])));
  }
}
