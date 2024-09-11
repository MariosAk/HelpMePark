import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:pasthelwparking_v1/screens/carPick.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController textControllerEmail = TextEditingController();
  TextEditingController textControllerPassword = TextEditingController();
  bool isEmailValid = false;
  bool registrationSuccess = false;
  late String registrationStatus;
  String? token;

  Future<String> registerUser(email, password, _token) async {
    try {
      var response = await http.post(
          //Uri.parse("http://192.168.1.26:8080/pasthelwparking/searching.php"), //vm
          Uri.parse("https://pasthelwparkingv1.000webhostapp.com/php/register.php"),
          body: {"email": email, "password": password, "token": _token});
      //print("LATLON " + response.body);
      registrationStatus = response.body;
      if (registrationStatus.contains("successful")) {
        registrationSuccess = true;
      } else if (registrationStatus.contains("exists")) {
        registrationSuccess = false;
      } else {
        registrationSuccess = false;
      }
      return registrationStatus;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  Future _getDevToken() async {
    token = await FirebaseMessaging.instance.getToken();
    print("DEV TOKEN FIREBASE CLOUD MESSAGING -> $token");
  }

  @override
  void dispose() {
    textControllerEmail.dispose();
    textControllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([_getDevToken()]),
        builder: (context, snapshot) {
          return Scaffold(
              body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, colors: [
              Color(0xFF6190e8),
              Color(0xFFa7bfe8),
              Color(0xFFc8d9e8)
            ])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: 80,
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Register",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Easy parking!",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60))),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: <Widget>[
                            const SizedBox(
                              height: 60,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color.fromRGBO(0, 100, 255, .2),
                                        blurRadius: 10,
                                        offset: Offset(0, 10))
                                  ]),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Colors.grey.shade200))),
                                    child: TextFormField(
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        EmailValidator.validate(value!)
                                            ? isEmailValid = true
                                            : isEmailValid = false;
                                        ;
                                      },
                                      controller: textControllerEmail,
                                      decoration: const InputDecoration(
                                          hintText: "Email",
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Colors.grey.shade200))),
                                    child: TextField(
                                      controller: textControllerPassword,
                                      decoration: const InputDecoration(
                                          hintText: "Password",
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const TextField(
                                      decoration: InputDecoration(
                                          hintText: "Repeat Password",
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blueAccent,

                                elevation: 3,

                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0)),

                                minimumSize: const Size(100, 40), //////// HERE
                              ),
                              onPressed: () {
                                //postCancelSearch();
                                if (!isEmailValid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a valid email.')));
                                } else {
                                  var registration = registerUser(
                                      textControllerEmail.text,
                                      textControllerPassword.text,
                                      token);
                                  registration.then((value) =>
                                      registrationSuccess
                                          ? () {
                                              print(
                                                  "////INSIDE THEN ???? $value");
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          CarPick(
                                                              textControllerEmail
                                                                  .text)));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          registrationStatus)));
                                            }()
                                          : ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      registrationStatus))));
                                }
                              },
                              child: const Text('Continue',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ));
        });
  }
}
