import 'package:flutter/material.dart';
import 'package:pasthelwparking_v1/services/globals.dart' as globals;

class buttonOverlay extends StatefulWidget {
  const buttonOverlay({super.key});

  @override
  _buttonOverlayState createState() => _buttonOverlayState();
}

class _buttonOverlayState extends State<buttonOverlay> {
  @override
  Widget build(context) {
    return Scaffold(
        backgroundColor: Colors.grey.withOpacity(0.45),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Hero(
              tag: "searchTile",
              child: Container(
                  height: MediaQuery.of(context).size.height / 2,
                  width: MediaQuery.of(context).size.width / 1.3,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(225, 235, 235, 1.0),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset('Assets/Images/loading.gif'))),
          Hero(
              tag: "leftButton",
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  shadowColor: Colors.grey,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () =>
                    {Navigator.pop(context), globals.heroOverlay = false},
                child: const Text('Continue'),
              )),
        ])));
  }
}
