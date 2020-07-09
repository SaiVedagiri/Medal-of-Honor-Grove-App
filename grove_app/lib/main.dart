import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:uni_links/uni_links.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:location/location.dart';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

var _firebaseRef = FirebaseDatabase().reference();
FlutterTts flutterTts = FlutterTts();
var result = "";

var firebaseData;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Grove App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          "/": (_) =>
              StreamBuilder(
                stream: getLinksStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var result = snapshot.data;
                    return HomePage();
                  } else {
                    return HomePage();
                  }
                },
              ),
          "/video": (_) => VideoPage(),
          "/map": (_) => MapPage(),
          "/treasure": (_) => TreasurePage(),
        });
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final fb = FirebaseDatabase.instance;

  initState() {
    super.initState();
    initStateFunction();
  }

  initStateFunction() async {
    final ref = fb.reference();
    ref.child("locations").once().then((DataSnapshot data) {
      firebaseData = data.value;
    });
  }

  Future<String> createAlertDialog(BuildContext context, String title,
      String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Grove App"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              helpContext(
                  context,
                  "Help",
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Home Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: 'Text goes here.\n',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/video");
              },
            ),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/map");
              },
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/treasure");
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
    );
  }
}

class VideoPage extends StatefulWidget {
  VideoPage({Key key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  YoutubePlayerController _controller;
  PlayerState _playerState;
  YoutubeMetaData _videoMetaData;
  double _volume = 100;
  bool _muted = false;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'VDJOSB3bj2Q',
      flags: const YoutubePlayerFlags(
          mute: false,
          autoPlay: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: false,
          hideControls: false),
    );
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> createAlertDialog(BuildContext context, String title,
      String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Video"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              helpContext(
                  context,
                  "Help",
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Home Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: 'Text goes here.\n',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/");
              },
            ),
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/map");
              },
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/treasure");
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.blueAccent,
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
              ],
              onReady: () {
                _isPlayerReady = true;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location location;
  bool serviceEnabled;
  PermissionStatus permissionGranted;
  LocationData locationData;
  GoogleMapController mapController;
  double latitude = 45.0;
  double longitude = -122.0;
  final Map<String, Marker> _markers = {};

  @override
  initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    location = new Location();
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    double deg2rad(deg) {
      return deg * (pi / 180);
    }

    double getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
      var R = 6371; // Radius of the earth in km
      var dLat = deg2rad(lat2 - lat1); // deg2rad below
      var dLon = deg2rad(lon2 - lon1);
      var a = sin(dLat / 2) * sin(dLat / 2) +
          cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) *
              sin(dLon / 2);
      var c = 2 * atan2(sqrt(a), sqrt(1 - a));
      var d = R * c; // Distance in km
      return d;
    }

    print(locationData.latitude);
    print(locationData.longitude);

    firebaseData.keys.forEach((var key) {
      print(firebaseData[key]["latitude"]);
      print(firebaseData[key]["longitude"]);
      print(getDistanceFromLatLonInKm(locationData.latitude, locationData.longitude, firebaseData[key]["latitude"], firebaseData[key]["longitude"]));
      if (getDistanceFromLatLonInKm(
          locationData.latitude, locationData.longitude,
          firebaseData[key]["latitude"], firebaseData[key]["longitude"]) < 1000) {
        var body = "You are about ${1000 * getDistanceFromLatLonInKm(locationData.latitude, locationData.longitude, firebaseData[key]["latitude"], firebaseData[key]["longitude"])}m to ${firebaseData[key]["name"]}. Would you like to more info?";
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: Text("Location Near"),
                  content: Text(body),
                  actions: <Widget>[
                    MaterialButton(
                      elevation: 5.0,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) =>
                                new DetailsPage(
                                    title: firebaseData[key]["name"], info: firebaseData[key]["text"])));
                      },
                      child: Text("OK"),
                    ),
                    MaterialButton(
                      elevation: 5.0,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Cancel"),
                    )
                  ]);
            });
      }
    });

    setState(() {
      latitude = locationData.latitude;
      longitude = locationData.longitude;
    });
    location.onLocationChanged.listen((LocationData currentLocation) async {
      LocationData tempLocationData = await location.getLocation();

      double deg2rad(deg) {
        return deg * (pi / 180);
      }

      double getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
        var R = 6371; // Radius of the earth in km
        var dLat = deg2rad(lat2 - lat1); // deg2rad below
        var dLon = deg2rad(lon2 - lon1);
        var a = sin(dLat / 2) * sin(dLat / 2) +
            cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) *
                sin(dLon / 2);
        var c = 2 * atan2(sqrt(a), sqrt(1 - a));
        var d = R * c; // Distance in km
        return d;
      }

      firebaseData.keys.forEach((var key) {
        if (getDistanceFromLatLonInKm(
            tempLocationData.latitude, tempLocationData.longitude,
            firebaseData[key]["latitude"], firebaseData[key]["longitude"]) <
            10) {
          var body = "You are about ${1000 * getDistanceFromLatLonInKm(tempLocationData.latitude, tempLocationData.longitude, firebaseData[key]["latitude"], firebaseData[key]["longitude"])}m to ${firebaseData[key]["name"]}. Would you like to view details.";
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                    title: Text("Location Near"),
                    content: Text(body),
                    actions: <Widget>[
                      MaterialButton(
                        elevation: 5.0,
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) =>
                                  new DetailsPage(
                                      title: firebaseData[key]["name"], info: firebaseData[key]["text"])));
                        },
                        child: Text("OK"),
                      ),
                      MaterialButton(
                        elevation: 5.0,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      )
                    ]);
              });
        }
      });

      setState(() {
        _markers.clear();
        var marker = Marker(
          markerId: MarkerId("currentLocation"),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: "Current Location",
          ),
        );
        _markers["currentLocation"] = marker;

//      for (var office in locations.offices) {
//        var newMarker = Marker(
//          markerId: MarkerId(office.name),
//          position: LatLng(office.lat, office.lng),
//          infoWindow: InfoWindow(
//            title: office.name,
//            snippet: office.address,
//          ),
//        );
//        _markers[office.name] = newMarker;
//      }
      });
    });

    setState(() {
      _markers.clear();
      var marker = Marker(
        markerId: MarkerId("currentLocation"),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: "Current Location",
        ),
      );
      _markers["currentLocation"] = marker;

//      for (var office in locations.offices) {
//        var newMarker = Marker(
//          markerId: MarkerId(office.name),
//          position: LatLng(office.lat, office.lng),
//          infoWindow: InfoWindow(
//            title: office.name,
//            snippet: office.address,
//          ),
//        );
//        _markers[office.name] = newMarker;
//      }
    });

    location.onLocationChanged.timeout(Duration(seconds: 5));
  }

  @override
  void dispose() {
    super.dispose();
    location = null;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<String> createAlertDialog(BuildContext context, String title,
      String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Grove Map"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                try {
                  String qrResult = await BarcodeScanner.scan();
                  result = qrResult;
                  var done = false;
                  firebaseData.keys.forEach((var key) {
                    if (firebaseData[key]["qr-id"] == qrResult) {
                      done = true;
                      var locationName = firebaseData[key]["name"];
                      var locationDetails = firebaseData[key]["text"];
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) =>
                              new DetailsPage(
                                  title: locationName, info: locationDetails)));
                    }
                  });
                  if (done == false) {
                    createAlertDialog(context, "Invalid QR Code",
                        "This QR code is not recognized by the Grove app. Please try again.");
                  }
                }
                on PlatformException catch (ex) {
                  if (ex.code == BarcodeScanner.CameraAccessDenied) {
                    setState(() {
                      createAlertDialog(context, "Scan QR",
                          "Please enable camera permissions for Grove App.");
                    });
                  } else {
                    setState(() {
                      result = "Unknown Error $ex";
                      createAlertDialog(
                          context, "Scan QR", "Unkown Error Occured: $ex");
                    });
                  }
                } on FormatException {
                  setState(() {
                    result =
                    "You pressed the back button before scanning anything";
                    createAlertDialog(
                        context, "Scan QR", "No QR Code was recognized.");
                  });
                } catch (ex) {
                  setState(() {
                    result = "Unknown Error $ex";
                    createAlertDialog(
                        context, "Scan QR", "Unkown Error Occured: $ex");
                  });
                }
              }),
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              helpContext(
                  context,
                  "Help",
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Home Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: 'Text goes here.\n',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/");
              },
            ),
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/video");
              },
            ),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/treasure");
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height - 128,
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: LatLng(40.4367445053398, -74.23047140991979),
                zoom: 11.0,
              ),
              markers: _markers.values.toSet(),
            ),
          ),
        ],
      ),
    );
  }
}

class TreasurePage extends StatefulWidget {
  TreasurePage({Key key}) : super(key: key);

  @override
  _TreasurePageState createState() => _TreasurePageState();
}

class _TreasurePageState extends State<TreasurePage> {
  Future<String> createAlertDialog(BuildContext context, String title,
      String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Grove Treasure Hunt"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              helpContext(
                  context,
                  "Help",
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Home Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: 'Text goes here.\n',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/");
              },
            ),
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/video");
              },
            ),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/map");
              },
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
    );
  }
}

class DetailsPage extends StatefulWidget {
  DetailsPage({Key key, this.title, this.info}) : super(key: key);

  final String title;
  final String info;

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {

  initState() {
    super.initState();
    initStateFunction();
  }

  initStateFunction() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.isLanguageAvailable("en-US");
  }

  String status = "Play";

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              helpContext(
                  context,
                  "Help",
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Home Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: 'Text goes here.\n',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height - 350),
                child: SingleChildScrollView(
                  child: Container(
                    child: Text(
                      '${widget.info}',
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child:
              FloatingActionButton.extended(
                  icon: Icon(status == "Play" ? Icons.play_arrow : Icons.pause),
                  label: Text(status),
                  onPressed: () async {
                    if (status == "Play") {
                      await flutterTts.speak(widget.info);
                      setState(() {
                        status = "Pause";
                      });
                    } else {
                      await flutterTts.stop();
                      setState(() {
                        status = "Play";
                      });
                    }
                  }),),
          ],
        ),
      ),
    );
  }
}