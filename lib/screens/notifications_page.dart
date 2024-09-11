import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/notifications.dart';
import '../SqliteService.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  SqliteService sqliteService = SqliteService();
  late Future<List<Notifications>> notifications;
  late List<Notifications> notificationlist;

  @override
  void initState() {
    //notifications = this.getNotificationsList();
  }

  Future<List<Notifications>> getNotificationsList() async {
    return await SqliteService().getNotifications();
  }

  Future<void> deleteFromDataBase(String id) async {
    return await SqliteService().deleteItem(id);
  }

  AssetImage notificationImage(String cT) {
    switch (cT) {
      case "Sedan":
        {
          return AssetImage('Assets/Images/Sedan.png');
        }
      case "Coupe":
        return AssetImage('Assets/Images/Coupe.png');
      case "Pickup":
        return AssetImage('Assets/Images/Pickup.png');
      case "Jeep":
        return AssetImage('Assets/Images/Jeep.png');
      case "Wagon":
        return AssetImage('Assets/Images/Wagon.png');
      case "Crossover":
        return AssetImage('Assets/Images/Crossover.png');
      case "Hatchback":
        return AssetImage('Assets/Images/Hatchback.png');
      case "Van":
        return AssetImage('Assets/Images/Van.png');
      case "Sportcoupe":
        return AssetImage('Assets/Images/Sportcoupe.png');
      case "SUV":
        return AssetImage('Assets/Images/SUV.png');
      default:
        return AssetImage('Assets/Images/Sedan.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Notifications>>(
        future: getNotificationsList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // Future done with no errors
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return Container(
                color: Color.fromRGBO(246, 255, 255, 1.0),
                child: SafeArea(
                    child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          title: Text(
                            "Notifications",
                            style: GoogleFonts.openSans(
                                textStyle: TextStyle(color: Colors.black)),
                          ),
                          leading: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.black38,
                            ),
                            onPressed: () =>
                                Navigator.pop(context, snapshot.data.length),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.black38,
                              ),
                              onPressed: () => Navigator.pop(context, 'close'),
                            ),
                          ],
                          centerTitle: true,
                        ),
                        body: Center(
                            child: Container(
                          height: MediaQuery.of(context).size.height,
                          child: snapshot.data!.isNotEmpty
                              ? ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Dismissible(
                                      key: UniqueKey(),
                                      background: Container(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        color: Colors.red,
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (direction) async {
                                        await getNotificationsList();
                                        await deleteFromDataBase(snapshot
                                                .data![index].entry_id
                                                .toString())
                                            .then((value) => ScaffoldMessenger
                                                    .of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Data for ${snapshot.data![index].time.toString()} dismissed'))));
                                        snapshot.data!.removeAt(index);
                                      },
                                      direction: DismissDirection.endToStart,
                                      child: Card(
                                        elevation: 5,
                                        child: Container(
                                          height: 100.0,
                                          child: Row(
                                            children: <Widget>[
                                              Container(
                                                  height: 100.0,
                                                  width: 70.0,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              bottomLeft: Radius
                                                                  .circular(5),
                                                              topLeft: Radius
                                                                  .circular(5)),
                                                      image: DecorationImage(
                                                          fit: BoxFit.fitWidth,
                                                          image: notificationImage(
                                                              snapshot
                                                                  .data![index]
                                                                  .carType)))),
                                              Container(
                                                height: 100,
                                                child: Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      10, 2, 0, 0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Container(
                                                          width: 260,
                                                          child: Text(
                                                            "Address: ${snapshot.data![index].address.toString()}",
                                                          )),
                                                      Text(
                                                        "Cartype: ${snapshot.data![index].carType.toString()}",
                                                      ),
                                                      Text(
                                                        "Time: ${snapshot.data![index].time.toString()}",
                                                      ),
                                                      Text(
                                                        "Status: ${snapshot.data![index].status.toString()}",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                              : const Text('You have no notifications.'),
                        )))));
          }
          // Future with some errors
          else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            //print(snapshot.data![0].entry_id.toString());
            return Text("The error ${snapshot.error} occured");
          }
          // Future not done yet
          else {
            //print(snapshot.connectionState);
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
