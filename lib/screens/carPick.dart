import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pasthelwparking_v1/screens/home_page.dart';
import 'package:pasthelwparking_v1/main.dart';

class Car {
  Image image;
  String carType;
  Car(this.image, this.carType);
}

class CarPick extends StatefulWidget {
  String? email;
  CarPick(this.email);
  @override
  _CarPickState createState() => _CarPickState();
}

class _CarPickState extends State<CarPick> {
  int tappedIndex = 100;
  List<bool> borders = [];

  Future<String> registerCar(car, email) async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/registerCar.php"),
          body: {"email": email, "car": car});
      //print("LATLON " + response.body);
      return response.body;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Car> _carList = [
      Car(
          Image(
            image: AssetImage('Assets/Images/Sedan.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Sedan'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Coupe.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Coupe'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Pickup.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Pickup'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Jeep.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Jeep'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Wagon.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Wagon'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Crossover.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Crossover'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Hatchback.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Hatchback'),
      Car(
          Image(
            image: AssetImage('Assets/Images/Van.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Van'),
      Car(
          Image(
            image: AssetImage('Assets/Images/SportCoupe.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Sportcoupe'),
      Car(
          Image(
            image: AssetImage('Assets/Images/SUV.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'SUV'),
    ];

    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            Color(0xFF6190e8),
            Color(0xFFa7bfe8),
            Color(0xFFc8d9e8)
          ])),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text("Pick your car type"),
            centerTitle: true,
          ),
          body: Center(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                itemCount: _carList.length,
                itemBuilder: (context, index) {
                  borders.add(false);
                  return GestureDetector(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: tappedIndex == index
                            ? Border.all(color: Colors.white, width: 3.0)
                            : Border.all(
                                color: Colors.transparent,
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _carList[index].image,
                    ),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: MediaQuery.of(context).size.height / 4,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                      'You picked ${_carList[index].carType} cartype.'),
                                  ElevatedButton(
                                    child: const Text('Continue'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      backgroundColor: Colors.white,
                                      shadowColor: Colors.grey,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32.0)),
                                      minimumSize: Size(100, 40),
                                    ),
                                    onPressed: () => () {
                                      Navigator.pop(context);
                                      registerCar(_carList[index].carType,
                                          widget.email);
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MyHomePage()));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Registration completed.")));
                                    }(),
                                  ),
                                  ElevatedButton(
                                      child: const Text('Back'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        backgroundColor: Colors.white,
                                        shadowColor: Colors.grey,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(32.0)),
                                        minimumSize: Size(100, 40),
                                      ),
                                      onPressed: () => Navigator.pop(context))
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      setState(() {
                        tappedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
