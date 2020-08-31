import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:location/location.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

var _firebaseRef = FirebaseDatabase().reference();
FlutterTts flutterTts = FlutterTts();
var result = "";
var popupShown = false;
var timePressed;
var prefs;

var firebaseData;
var scavengerData;
var firstCamera;
var videoId;
var distanceLength;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  firstCamera = cameras.first;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          "/": (_) => HomePage(),
          "/video": (_) => VideoPage(),
          "/map": (_) => MapPage(),
          "/treasure": (_) => TreasurePage(),
        });
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  final ChromeSafariBrowser browser =
      new MyChromeSafariBrowser(new MyInAppBrowser());

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
    ref.child("Scavenger").once().then((DataSnapshot data) {
      scavengerData = data.value;
    });
    ref.child("videoId").once().then((DataSnapshot data) {
      videoId = data.value;
    });
    ref.child("distance").once().then((DataSnapshot data) {
      distanceLength = data.value;
    });
    prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('treasureNum') == null) {
      prefs.setInt('treasureNum', 1);
    }
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
  }

  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
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
        title: Text("Medal of Honor Grove"),
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
                          text:
                              'Read the basic information about the Medal of Honor Grove.\n',
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
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image(
                  image: AssetImage('assets/brochure.jpg'),
                  height: 200,
                )),
            Padding(
              padding: const EdgeInsets.only(
                  top: 30.0, bottom: 20.0, left: 15.0, right: 15.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 2.0 - 150),
                child: SingleChildScrollView(
                  child: Container(
                    child: Text(
                      'The Medal of Honor Grove is the oldest living memorial honoring more than 3,500 Medal of Honor Recipients. It serves as a beautiful place of remembrance for the brave souls who risked their lives and, in most cases, made the ultimate sacrifice.\n\nWithin the Grove, there is an area of land for each of the 50 states, as well as Puerto Rico and the District of Columbia.  The recipients of each state are identified by name, rank, and service branch on an obelisk.  Recipients are additionally honored with a ground marker engraved with their name, branch of service and the date and location of the act of valor.\n\nThe Grove is owned by Freedoms Foundation at Valley Forge and maintained by the FRIENDS of the MEDAL of HONOR GROVE.',
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RaisedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.web),
                  ),
                  Text("Visit Website")
                ],
              ),
              onPressed: () async {
                await widget.browser.open(
                    url: "https://friendsmohgrove.org/",
                    options: ChromeSafariBrowserClassOptions(
                        android: AndroidChromeCustomTabsOptions(
                            addDefaultShareMenuItem: true,
                            keepAliveEnabled: true),
                        ios: IOSSafariOptions(
                            dismissButtonStyle:
                                IOSSafariDismissButtonStyle.CLOSE,
                            presentationStyle:
                                IOSUIModalPresentationStyle.OVER_FULL_SCREEN)));
              },
            )
          ],
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
      initialVideoId: videoId,
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

  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
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
                          text: 'Video Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text:
                              'Watch our video about the Medal of Honor Grove.\n',
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
  double latitude = 40.1048872;
  double longitude = -75.4746419;
  final Map<String, Marker> _markers = {};
  BitmapDescriptor pinLocation;

  @override
  initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    pinLocation = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/currentLocation.png');
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
          cos(deg2rad(lat1)) *
              cos(deg2rad(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      var c = 2 * atan2(sqrt(a), sqrt(1 - a));
      var d = R * c; // Distance in km
      return d;
    }

    if (firebaseData != null) {
      firebaseData.keys.forEach((var key) {
        if (getDistanceFromLatLonInKm(
                locationData.latitude,
                locationData.longitude,
                firebaseData[key]["latitude"],
                firebaseData[key]["longitude"]) <
            distanceLength) {
          var body =
              "You are nearby ${firebaseData[key]["name"]}. Would you like to more info?";
          if (!popupShown &&
              (timePressed == null ||
                  new DateTime.now().isAfter(timePressed))) {
            popupShown = true;
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
                            popupShown = false;
                            timePressed = new DateTime.now()
                                .add(new Duration(minutes: 1));
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => new DetailsPage(
                                        title: firebaseData[key]["name"],
                                        info: firebaseData[key]["text"])));
                          },
                          child: Text("OK"),
                        ),
                        MaterialButton(
                          elevation: 5.0,
                          onPressed: () {
                            popupShown = false;
                            timePressed = new DateTime.now()
                                .add(new Duration(minutes: 1));
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel"),
                        )
                      ]);
                });
          }
        }
      });
    }

    setState(() {
      latitude = locationData.latitude;
      longitude = locationData.longitude;
    });

    location.onLocationChanged.listen((LocationData currentLocation) async {
      try {
        LocationData tempLocationData = await location.getLocation();

        firebaseData.keys.forEach((var key) {
          if (getDistanceFromLatLonInKm(
                  locationData.latitude,
                  locationData.longitude,
                  firebaseData[key]["latitude"],
                  firebaseData[key]["longitude"]) <
              distanceLength) {
            var body =
                "You are nearby ${firebaseData[key]["name"]}. Would you like to more info?";
            if (!popupShown &&
                (timePressed == null ||
                    new DateTime.now().isAfter(timePressed))) {
              popupShown = true;
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
                              popupShown = false;
                              timePressed = new DateTime.now()
                                  .add(new Duration(minutes: 1));
                              Navigator.of(context).pop();
                              Navigator.push(
                                  context,
                                  new MaterialPageRoute(
                                      builder: (context) => new DetailsPage(
                                          title: firebaseData[key]["name"],
                                          info: firebaseData[key]["text"])));
                            },
                            child: Text("OK"),
                          ),
                          MaterialButton(
                            elevation: 5.0,
                            onPressed: () {
                              popupShown = false;
                              timePressed = new DateTime.now()
                                  .add(new Duration(minutes: 1));
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancel"),
                          )
                        ]);
                  });
            }
          }
        });

        setState(() {
          _markers.clear();
          var marker = Marker(
            markerId: MarkerId("currentLocation"),
            icon: pinLocation,
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: "Current Location",
            ),
          );
          _markers["currentLocation"] = marker;

          firebaseData.keys.forEach((var key) {
            var newMarker = Marker(
              markerId: MarkerId(key),
              position: LatLng(firebaseData[key]["latitude"],
                  firebaseData[key]["longitude"]),
              infoWindow: InfoWindow(
                  title: firebaseData[key]["name"],
                  snippet: "Click to see more info",
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new DetailsPage(
                                title: firebaseData[key]["name"],
                                info: firebaseData[key]["text"])));
                  }),
            );
            _markers[key] = newMarker;
          });
        });
      } catch (ex) {}
    });

    setState(() {
      _markers.clear();
      var marker = Marker(
        markerId: MarkerId("currentLocation"),
        position: LatLng(latitude, longitude),
        icon: pinLocation,
        infoWindow: InfoWindow(
          title: "Current Location",
        ),
      );
      _markers["currentLocation"] = marker;

      if (firebaseData != null) {
        firebaseData.keys.forEach((var key) {
          var newMarker = Marker(
            markerId: MarkerId(key),
            position: LatLng(
                firebaseData[key]["latitude"], firebaseData[key]["longitude"]),
            infoWindow: InfoWindow(
              title: firebaseData[key]["name"],
            ),
          );
          _markers[key] = newMarker;
        });
      }
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

  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
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
                              builder: (context) => new DetailsPage(
                                  title: locationName, info: locationDetails)));
                    }
                  });
                  if (done == false) {
                    createAlertDialog(context, "Invalid QR Code",
                        "This QR code is not recognized by the Grove app. Please try again.");
                  }
                } on PlatformException catch (ex) {
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
                          text: 'Map Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text:
                              'View a map with all labeled locations. Scan a QR code on a location to view the information. If you are close to the location, you will be alerted.\n',
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
            height: MediaQuery.of(context).size.height - 128,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 17.0,
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
  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
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

  String locationKey = "";
  Map<dynamic, dynamic> locationData = {
    "name": "",
    "latitude": "",
    "longitude": "",
    "qr-id": "",
    "text": ""
  };

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

  initState() {
    super.initState();
    initStateFunction();
  }

  initStateFunction() async {
    setState(() {
      if (scavengerData != null) {
        locationKey = scavengerData[prefs.getInt('treasureNum')];
        locationData = firebaseData[locationKey];
      }
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
                          text: 'Scavenger Hunt Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text:
                              'Take part in a scavenger hunt to search for locations. When you find a location, scan the QR code and you will be given a new clue.\n',
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
          children: (scavengerData != null &&
                  scavengerData.length > prefs.getInt("treasureNum"))
              ? <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      "Location #${prefs.getInt("treasureNum")}: ${locationData["name"]}",
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 2),
                      child: SingleChildScrollView(
                        child: Container(
                          child: Text(
                            '${locationData["text"]}',
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
                    child: FloatingActionButton.extended(
                        icon: Icon(Icons.camera),
                        label: Text("Scan QR"),
                        onPressed: () async {
                          try {
                            String qrResult = await BarcodeScanner.scan();
                            result = qrResult;
                            if (result != locationData["qr-id"]) {
                              createAlertDialog(context, "Incorrect QR Code",
                                  "This QR code does not match ${locationData["name"]}. Please try again.");
                            } else {
                              prefs.setInt('treasureNum',
                                  (prefs.getInt('treasureNum') + 1));
                              Navigator.pushReplacement(
                                  context,
                                  new MaterialPageRoute(
                                      builder: (context) => new SocialPage(
                                          locationData:
                                              json.encode(locationData))));
                            }
                          } on PlatformException catch (ex) {
                            if (ex.code == BarcodeScanner.CameraAccessDenied) {
                              setState(() {
                                createAlertDialog(context, "Scan QR",
                                    "Please enable camera permissions for Grove App.");
                              });
                            } else {
                              setState(() {
                                result = "Unknown Error $ex";
                                createAlertDialog(context, "Scan QR",
                                    "Unkown Error Occured: $ex");
                              });
                            }
                          } on FormatException {
                            setState(() {
                              result =
                                  "You pressed the back button before scanning anything";
                              createAlertDialog(context, "Scan QR",
                                  "No QR Code was recognized.");
                            });
                          } catch (ex) {
                            setState(() {
                              result = "Unknown Error $ex";
                              createAlertDialog(context, "Scan QR",
                                  "Unkown Error Occured: $ex");
                            });
                          }
                        }),
                  ),
                ]
              : <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                        "Congratulations! You have completed the scavenger hunt."),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: FloatingActionButton.extended(
                        icon: Icon(Icons.refresh),
                        label: Text("Restart"),
                        onPressed: () async {
                          if (scavengerData != null) {
                            setState(() {
                              prefs.setInt('treasureNum', 1);
                              locationKey =
                                  scavengerData[prefs.getInt('treasureNum')];
                              locationData = firebaseData[locationKey];
                            });
                          }
                        }),
                  ),
                ],
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
    if (Platform.isIOS) {
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.isLanguageAvailable("en-US");
    } else {
      await flutterTts.setSpeechRate(1.0);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.isLanguageAvailable("en-US");
    }
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

    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        if (status == "Pause") {
          await flutterTts.stop();
          setState(() {
            status = "Play";
          });
        }
        Navigator.of(context).pop();
        return;
      },
      child: Scaffold(
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
                            text: 'Details Page\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text: 'View the details of a location.\n',
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
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 350),
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
                child: FloatingActionButton.extended(
                    icon:
                        Icon(status == "Play" ? Icons.play_arrow : Icons.pause),
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
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialPage extends StatefulWidget {
  SocialPage({Key key, this.locationData}) : super(key: key);

  final String locationData;

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  var locationData;

  initState() {
    super.initState();
    initStateFunction();
  }

  initStateFunction() {
    locationData = json.decode(widget.locationData);
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
        title: Text("Share on Social"),
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
                          text: 'Social Page\n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text:
                              'Share a location through your social media platforms.\n',
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
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0),
              child: Text(
                  "Congratulations, you found location #${prefs.getInt('treasureNum') - 1}: ${locationData["name"]}! Feel free to post it on social media!"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: FloatingActionButton.extended(
                  heroTag: "continueBtn",
                  label: Text("Continue"),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new TreasurePage()));
                  }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: FloatingActionButton.extended(
                  heroTag: "shareBtn",
                  backgroundColor: Colors.blueAccent,
                  icon: Icon(Icons.share),
                  label: Text("Share"),
                  onPressed: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => new TakePictureScreen(
                              // Pass the appropriate camera to the TakePictureScreen widget.
                              camera: firstCamera,
                              locationName: locationData["name"],
                              socialText: locationData["social"]),
                        ));
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String locationName;
  final String socialText;

  const TakePictureScreen(
      {Key key, @required this.camera, this.locationName, this.socialText})
      : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                    imagePath: path,
                    socialText: widget.socialText,
                    locationName: widget.locationName),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final String socialText;
  final String locationName;

  const DisplayPictureScreen(
      {Key key, this.imagePath, this.socialText, this.locationName})
      : super(key: key);

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Share your Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.file(File(widget.imagePath)),
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: FloatingActionButton.extended(
                    heroTag: "socialBtn",
                    backgroundColor: Colors.green,
                    icon: Icon(Icons.share),
                    label: Text("Share"),
                    onPressed: () async {
                      await ShareExtend.share(widget.imagePath, "image",
                          sharePanelTitle: "Grove App",
                          subject: widget.locationName,
                          extraText: widget.socialText);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }),
              ),
            ]),
      ),
    );
  }
}

class MyInAppBrowser extends InAppBrowser {
  @override
  Future onLoadStart(String url) async {
    print("\n\nStarted $url\n\n");
  }

  @override
  Future onLoadStop(String url) async {
    print("\n\nStopped $url\n\n");
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  void onExit() {
    print("\n\nBrowser closed!\n\n");
  }
}

class MyChromeSafariBrowser extends ChromeSafariBrowser {
  MyChromeSafariBrowser(browserFallback) : super(bFallback: browserFallback);

  @override
  void onOpened() {
    print("ChromeSafari browser opened");
  }

  @override
  void onLoaded() {
    print("ChromeSafari browser loaded");
  }

  @override
  void onClosed() {
    print("ChromeSafari browser closed");
  }
}
