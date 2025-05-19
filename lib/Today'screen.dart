import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:techlead/Splashscreen.dart';
import 'Viewguildlines.dart';
import 'googlescreen.dart';

class Todayscreen extends StatefulWidget {
  const Todayscreen({Key? key}) : super(key: key);

  @override
  State<Todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<Todayscreen> {
  late double screenHeight;
  late double screenWidth;
  String userName = '';
  String checkInTime = '--:--';
  String checkOutTime = '--:--';
  String attendanceStatus = '';
  bool hasCheckedIn = false;
  bool hasCheckedOut = false;
  bool showEntryCompleteMessage = false;
  late Timer _timer;
  late Timer _liveTimeTimer;
  String location = '';
  bool isCheckIn = false;
  String _currentLocation = '';
  String _currentDateTime = '';
  final _firestore = FirebaseFirestore.instance;
  String? userId;
  late GoogleMapController mapController;
  late LatLng _center;
  bool isLoading = false;
  late LatLng initialPosition;

  @override
  void initState() {
    super.initState();
    _center = LatLng(0.0, 0.0);
    initialPosition = _center;
    _fetchUserId();
    fetchUserName();
    _listenForRealtimeUpdates();
    requestLocationPermission().then((_) {
      _getLocation();
    });
    _liveTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentDateTime();
    });
  }

  Future<void> _fetchUserId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
        });

        print("Fetched UserID: $userId");


        if (userId!.isNotEmpty) {
          await fetchUserName();
        }
      } else {
        print('User is not logged in.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }


  @override
  void dispose() {
    _timer.cancel();
    _liveTimeTimer.cancel();
    super.dispose();
  }

  Future<void> requestLocationPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
    if (statuses[Permission.location]!.isGranted) {
      print('Location permission granted');
    } else if (statuses[Permission.location]!.isDenied) {
      print('Location permission denied');
    } else if (statuses[Permission.location]!.isPermanentlyDenied) {
      print('Location permission permanently denied');
      await openAppSettings();
    }

    if (statuses[Permission.camera]!.isGranted) {
      print('Camera permission granted');
    } else if (statuses[Permission.camera]!.isDenied) {
      print('Camera permission denied');
    } else if (statuses[Permission.camera]!.isPermanentlyDenied) {
      print('Camera permission permanently denied');
      await openAppSettings();
    }

    if (statuses[Permission.microphone]!.isGranted) {
      print('Microphone permission granted');
    } else if (statuses[Permission.microphone]!.isDenied) {
      print('Microphone permission denied');
    } else if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      print('Microphone permission permanently denied');
      await openAppSettings();
    }

    if (statuses[Permission.storage]!.isGranted) {
      print('Storage permission granted');
    } else if (statuses[Permission.storage]!.isDenied) {
      print('Storage permission denied');
    } else if (statuses[Permission.storage]!.isPermanentlyDenied) {
      print('Storage permission permanently denied');
      await openAppSettings();
    }

    setState(() {});
  }
  Future<void> _getLocation() async {
    try {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        setState(() {
          _currentLocation = "Location services are disabled. Please enable them.";
          _center = LatLng(0.0, 0.0);
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Location permission denied. Enable it in settings.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation =
          "Location permission is permanently denied. Please enable it in settings.";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation =
          "${place.street}, ${place.subLocality}, ${place.locality}, "
              "${place.administrativeArea}, ${place.postalCode}, ${place.country}";
          _center = LatLng(position.latitude, position.longitude);
          initialPosition = _center;
        });
      } else {
        setState(() {
          _currentLocation = "Location not available";
          _center = LatLng(0.0, 0.0);
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = "Error: ${e.toString()}";
        _center = LatLng(0.0, 0.0);
      });
    }
  }
  void _updateCurrentDateTime() {
    setState(() {
      _currentDateTime =
          DateFormat('EE, d MMM yyyy, hh:mm:ss a').format(DateTime.now());
    });
  }

  void _resetDailyData() {
    setState(() {
      checkInTime = '--:--';
      checkOutTime = '--:--';
      hasCheckedIn = false;
      hasCheckedOut = false;
      showEntryCompleteMessage = false;
      attendanceStatus = '';
    });
    _listenForRealtimeUpdates();
  }

  Future<void> fetchUserName() async {
    try {

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        return;
      }

      String userId = user.uid;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        setState(() {
          userName = userSnapshot.get('fullName') ?? "Unknown";
        });
        print("Fetched User Name: $userName");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _listenForRealtimeUpdates() {
    if (userId != null) {
      _firestore
          .collection('Attendance')
          .where('userId', isEqualTo: userId)
          .where(
          'date', isEqualTo: DateFormat('dd/MM/yyyy').format(DateTime.now()))
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = snapshot.docs.first;
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null) {
            setState(() {
              checkInTime = data['checkIn'] ?? '--:--';
              checkOutTime = data['checkOut'] ?? '--:--';
              hasCheckedIn =
                  data.containsKey('checkIn') && data['checkIn'] != null;
              hasCheckedOut =
                  data.containsKey('checkOut') && data['checkOut'] != null;
              showEntryCompleteMessage = hasCheckedOut;
              if (data.containsKey('department')) {
                String department = data['department'];
              }
            });

            if (hasCheckedOut) {
              calculateAttendanceStatus();
            }
          } else {
            setState(() {
              checkInTime = '--:--';
              checkOutTime = '--:--';
              hasCheckedIn = false;
              hasCheckedOut = false;
              showEntryCompleteMessage = false;
            });
          }
        } else {
          setState(() {
            checkInTime = '--:--';
            checkOutTime = '--:--';
            hasCheckedIn = false;
            hasCheckedOut = false;
            showEntryCompleteMessage = false;
          });
        }
      });
    } else {
      print('User ID is null, cannot listen for real-time updates.');
    }
  }

  Future<void> storeCheckInOutTime({required bool isCheckIn}) async {
    String currentTime = DateFormat('HH:mm').format(DateTime.now());
    String todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (userId != null) {
      DocumentSnapshot userSnapshot = await _firestore.collection('EmpProfile')
          .doc(userId)
          .get();
      String employeeName = userSnapshot.exists
          ? userSnapshot['fullName']
          : 'Unknown';
      String department = userSnapshot.exists
          ? userSnapshot['department']
          : 'Unknown';


      QuerySnapshot snapshot = await _firestore
          .collection('Attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: todayStr)
          .get();

      DocumentReference attendanceRef;
      if (snapshot.docs.isNotEmpty) {
        attendanceRef =
            _firestore.collection('Attendance').doc(snapshot.docs.first.id);
      } else {
        attendanceRef = _firestore.collection('Attendance').doc();
      }

      if (isCheckIn && !hasCheckedIn) {
        await attendanceRef.set({
          'userId': userId,
          'date': todayStr,
          'checkIn': currentTime,
          'checkInLocation': _currentLocation,
          'employeeName': employeeName,
          'department': department,
        }, SetOptions(merge: true));

        setState(() {
          checkInTime = currentTime;
          hasCheckedIn = true;
          showEntryCompleteMessage = false;
        });
      } else if (!isCheckIn && hasCheckedIn && !hasCheckedOut) {
        await attendanceRef.update({
          'checkOut': currentTime,
          'checkOutLocation': _currentLocation,
          'employeeName': employeeName,
          'maplocation': GeoPoint(_center.latitude, _center.longitude),
        });

        setState(() {
          checkOutTime = currentTime;
          hasCheckedOut = true;
          showEntryCompleteMessage = true;
          calculateAttendanceStatus();
        });
      }
    } else {
      print('User ID is null, cannot store attendance data.');
    }
  }

  void calculateAttendanceStatus() async {
    if (checkInTime != '--:--' && checkOutTime != '--:--') {
      DateTime checkIn = DateFormat('HH:mm').parse(checkInTime);
      DateTime checkOut = DateFormat('HH:mm').parse(checkOutTime);

      Duration duration = checkOut.difference(checkIn);
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);

      String status;
      if (hours >= 8) {
        status = 'Full Day';
      } else {
        status = 'Half Day';
      }

      setState(() {
        attendanceStatus =
        '${hours}Hours: ${minutes}Minutes\n Todays Status: $status';
      });

      if (userId != null) {
        QuerySnapshot snapshot = await _firestore
            .collection('Attendance')
            .where('userId', isEqualTo: userId)
            .where(
            'date', isEqualTo: DateFormat('dd/MM/yyyy').format(DateTime.now()))
            .get();

        if (snapshot.docs.isNotEmpty) {
          DocumentReference docRef = _firestore.collection('Attendance').doc(
              snapshot.docs.first.id);
          await docRef.update({
            'status': status,
            'record': '$hours hours, $minutes minutes'
          });
        }
      } else {
        print('User ID is null, cannot update attendance document.');
      }
    } else {
      setState(() {
        attendanceStatus = 'Incomplete Data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.cyan),
        title: Text('Todays Screen', style: TextStyle(color: Colors.white,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.announcement, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Viewguildlines()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildWelcomeMessage(),
              _buildTodaysStatus(),
              _buildDateTime(),
              SizedBox(height: 10),
              if (!hasCheckedOut) _buildSlideAction(),
              if (showEntryCompleteMessage) _buildEntryCompleteMessage(),
              SizedBox(height: 10),
              _buildLocationInfo(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWelcomeMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Center(
            child: Text(
              "Welcome",
              style: TextStyle(
                  color: Colors.green,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 16,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        Container(
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName : "Employ",
              style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                  color: Color(hexColor('#18A2D0'))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          child: Text(
            "Today's Status",
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 12),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.blue,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusColumn(
                        "Check In", checkInTime, isChecked: hasCheckedIn),
                  ],
                ),
              ),
              VerticalDivider(
                color: Colors.white,
                thickness: 1,
                width: 20,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusColumn(
                        "Check Out", checkOutTime, isChecked: hasCheckedOut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumn(String title, String time,
      {bool isChecked = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: "NexaRegular",
            fontSize: screenWidth / 20,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        Text(
          time,
          style: TextStyle(
            fontFamily: "NexaBold",
            fontSize: screenWidth / 18,
            color: Colors.white,
          ),
        ),
        if (isChecked)
          Icon(Icons.check, color: Colors.orange, size: 28),
      ],
    );
  }

  Widget _buildDateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          child: Text(
            "Date & Time",
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 12),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.green,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentDateTime,
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlideAction() {
    return Column(
      children: [
        SlideAction(
          text: hasCheckedIn ? "Slide to Check Out" : "Slide to Check In",
          textStyle: TextStyle(
            fontSize: screenWidth / 20,
            color: Colors.cyan,
            fontFamily: "NexaRegular",
          ),
          outerColor: Colors.white,
          innerColor: Colors.cyan,
          onSubmit: () async {
            bool isLocationEnabled = await Geolocator
                .isLocationServiceEnabled();
            if (!isLocationEnabled) {
              _showLocationDialog();
            } else {
              await storeCheckInOutTime(isCheckIn: !hasCheckedIn);
            }
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }

  /// **Show Dialog Prompting User to Enable Location**
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Location Required"),
            content: Text("Please turn on location services to proceed."),
            actions: [
              TextButton(
                onPressed: () async {
                  await Geolocator
                      .openLocationSettings(); // Open location settings
                  Navigator.of(context).pop();
                },
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  Widget _buildEntryCompleteMessage() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          child: Text(
            "Entry Complete For Today!",
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 12),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text("Work Duration: $attendanceStatus",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: screenWidth / 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 20,),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                  MapScreen(initialPosition: initialPosition)));
            },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5))),
                child: Text("View Live Google map", style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,),)),
          ),
        )
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: Text(
        _currentLocation.isNotEmpty
            ? "Current Location: $_currentLocation"
            : "Location not available. Please turn on location services.",
        style: TextStyle(
          fontFamily: "NexaRegular",
          fontSize: screenWidth / 20,
          color: _currentLocation.isNotEmpty ? Colors.black : Colors
              .red, // Red color for error
        ),
      ),
    );
  }
}
int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}