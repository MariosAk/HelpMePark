import 'package:flutter/material.dart';

class buttonOverlayRight extends StatefulWidget {
  @override
  _buttonOverlayRightState createState() => _buttonOverlayRightState();
}

class _buttonOverlayRightState extends State<buttonOverlayRight> {
  late AssetImage assetImage;
  @override
  void initState() {
    super.initState();
    assetImage = AssetImage('Assets/Images/done1.gif');
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
    assetImage.evict();
  }

  @override
  Widget build(context) {
    return Scaffold(
        backgroundColor: Colors.grey.withOpacity(0.45),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Hero(
              tag: "leaveTile",
              child: Container(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width / 1.3,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(225, 235, 235, 1.0),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                alignment: Alignment.topCenter,
                child: Image(image: assetImage),
              )),
        ])));
  }
}
