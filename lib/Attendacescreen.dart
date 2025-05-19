import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techlead/Calendarscreen.dart';
import 'package:techlead/EmpHomescreen.dart';
import 'dart:async';
import 'package:techlead/Splashscreen.dart';
import 'package:techlead/taskreportpage.dart';
import 'Leavescreen.dart';
import 'Themeprovider.dart';
import 'Viewguildlines.dart';
import 'googlescreen.dart';

class Attendancescreen extends StatefulWidget {
  const Attendancescreen({Key? key}) : super(key: key);

  @override
  State<Attendancescreen> createState() => _AttendancescreenState();
}

class _AttendancescreenState extends State<Attendancescreen> {
  late double screenHeight;
  late double screenWidth;
  String userName = '';
  String employeeName = '';
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
    fetchUserName();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _listenForRealtimeUpdates();
    } else {
      print('No user is logged in.');
    }
    requestLocationPermission().then((_) {
      _getLocation();
    });
    _liveTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentDateTime();
    });
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

// Show the check-out dialog
  Future<bool> _showCheckoutDialog() async {
    // Show the dialog and wait for the user's response (true/false)
    final bool? shouldCheckout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Confirm Check Out',
              style: TextStyle(color: Colors.white), // White color for title
            ),
          ),
          content: Text(
            'Are you sure you want to check out?',
            style: TextStyle(color: Colors.white), // White color for content
          ),
          backgroundColor: Colors.blue.shade900, // Make the background of AlertDialog transparent
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User selected "No"
              },
              child: Text(
                'No',
                style: TextStyle(color: Colors.white), // White text for "No"
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User selected "Yes"
              },
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.white), // White text for "Yes"
              ),
            ),
          ],
          contentPadding: EdgeInsets.zero, // Remove default padding
          insetPadding: EdgeInsets.symmetric(horizontal: 24.0),
        );
      },
    );

    return shouldCheckout ?? false;  // Return false if the value is null
  }

// Show the check-in dialog
  Future<bool> _showCheckInDialog() async {
    // Show the dialog and wait for the user's response (true/false)
    final bool? shouldCheckIn = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Confirm Check In',
              style: TextStyle(color: Colors.white), // White color for title
            ),
          ),
          content: Text(
            'Are you sure you want to check in?',
            style: TextStyle(color: Colors.white), // White color for content
          ),
          backgroundColor: Colors.blue.shade900, // Make the background of AlertDialog transparent
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User selected "No"
              },
              child: Text(
                'No',
                style: TextStyle(color: Colors.white), // White text for "No"
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User selected "Yes"
              },
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.white), // White text for "Yes"
              ),
            ),
          ],
          contentPadding: EdgeInsets.zero, // Remove default padding
          insetPadding: EdgeInsets.symmetric(horizontal: 24.0),
        );
      },
    );

    return shouldCheckIn ?? false;  // Return false if the value is null
  }






  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
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
      _currentDateTime = DateFormat('EE, d MMM yyyy, hh:mm:ss a').format(DateTime.now());
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
    if (userId == null) {
      print('User ID is null, cannot listen for real-time updates.');
      return;
    }

    _firestore
        .collection('Attendance')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: DateFormat('dd/MM/yyyy').format(DateTime.now()))
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = snapshot.docs.first;
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            checkInTime = data['checkIn'] ?? '--:--';
            checkOutTime = data['checkOut'] ?? '--:--';
            hasCheckedIn = data.containsKey('checkIn') && data['checkIn'] != null;
            hasCheckedOut = data.containsKey('checkOut') && data['checkOut'] != null;
            showEntryCompleteMessage = hasCheckedOut;
          });

          if (hasCheckedOut) {
            calculateAttendanceStatus();
          }
        } else {
          _resetAttendance();
        }
      } else {
        _resetAttendance();
      }
    });
  }

  void _resetAttendance() {
    setState(() {
      checkInTime = '--:--';
      checkOutTime = '--:--';
      hasCheckedIn = false;
      hasCheckedOut = false;
      showEntryCompleteMessage = false;
    });
  }

  Future<void> storeCheckInOutTime({required bool isCheckIn}) async {
    String currentTime = DateFormat('HH:mm').format(DateTime.now());
    String todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (userId != null) {
      DocumentSnapshot userSnapshot = await _firestore.collection('EmpProfile').doc(userId).get();
      String employeeName = userSnapshot.exists ? userSnapshot['fullName'] : 'Unknown';
      String department = userSnapshot.exists ? userSnapshot['address'] : 'Unknown';

      QuerySnapshot snapshot = await _firestore
          .collection('Attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: todayStr)
          .get();

      DocumentReference attendanceRef;
      if (snapshot.docs.isNotEmpty) {
        attendanceRef = _firestore.collection('Attendance').doc(snapshot.docs.first.id);
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

  void calculateAttendanceStatus({String? currentCheckoutLocation, bool isAutoCheckout = false}) async {
    if (checkInTime != '--:--') {
      DateTime checkIn = DateFormat('HH:mm').parse(checkInTime);
      DateTime now = DateTime.now();
      DateTime currentDayStart = DateTime(now.year, now.month, now.day);

      const String defaultCheckoutLocation = 'A-303, S.G.Business Hub, Sarkhej - Gandhinagar Hwy, Gota, Ahmedabad, Gujarat 380060';

      if (checkOutTime == '--:--') {
        if (now.isAfter(currentDayStart)) {
          DateTime autoCheckout = checkIn.add(const Duration(hours: 8));
          if (autoCheckout.isAfter(currentDayStart.add(const Duration(hours: 23, minutes: 59)))) {
            autoCheckout = currentDayStart.add(const Duration(hours: 23, minutes: 59));
          }
          checkOutTime = DateFormat('HH:mm').format(autoCheckout);
          isAutoCheckout = true;  // Mark it as automated
        } else {
          setState(() {
            attendanceStatus = 'Incomplete Data';
          });
          return;
        }
      }

      DateTime checkOut = DateFormat('HH:mm').parse(checkOutTime);
      Duration duration = checkOut.difference(checkIn);
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);

      String status = hours >= 8 ? 'Full Day' : 'Half Day';

      setState(() {
        attendanceStatus = '${hours}Hours: ${minutes}Minutes\n Todays Status: $status';
      });

      if (userId != null) {
        String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
        QuerySnapshot snapshot = await _firestore
            .collection('Attendance')
            .where('userId', isEqualTo: userId)
            .where('date', isEqualTo: today)
            .get();

        if (snapshot.docs.isNotEmpty) {
          DocumentReference docRef = _firestore.collection('Attendance').doc(snapshot.docs.first.id);

          Map<String, dynamic> updateData = {
            'status': status,
            'record': '$hours hours, $minutes minutes',
            'checkOutTime': checkOutTime,
          };

          var docData = snapshot.docs.first.data() as Map<String, dynamic>;
          String existingCheckOut = docData['checkOutTime'] ?? '--:--';

          if (checkOutTime != '--:--' && existingCheckOut == '--:--') {
            updateData['checkOutLocation'] = isAutoCheckout
                ? defaultCheckoutLocation
                : currentCheckoutLocation ?? _currentLocation;
          }

          await docRef.update(updateData);
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
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Todays Screen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      drawer: Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1), // Dark Blue
              Color(0xFF1976D2), // Mid Blue
              Color(0xFF42A5F5), // Light Blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child:
                Text(
                  'Techlead',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            _buildDrawerTile(
              icon: Icons.calendar_today,
              label: 'Calendar Screen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Calendarscreen()),
                );
              },
            ),
            // _buildDrawerTile(
            //   icon: Icons.note_alt,
            //   label: 'Leave Form',
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => Leavescreen()),
            //     );
            //   },
            // ),
            // _buildDrawerTile(
            //   icon: Icons.report,
            //   label: 'Daily Task Report',
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => DailyTaskReport2()),
            //     );
            //   },
            // ),
            _buildDrawerTile(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildWelcomeMessage(),
              SizedBox(height: 16,),
              _buildTodaysStatus(),
              SizedBox(height: 16,),
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
  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
              userName.isNotEmpty ? userName : "Employee",
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
                    _buildStatusColumn("Check In", checkInTime, isChecked: hasCheckedIn),
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
                    GestureDetector(
                      onTap: hasCheckedIn
                          ? () async {
                        // Show check-out dialog only if the user is checked in
                        bool shouldCheckout = await _showCheckoutDialog();
                        if (shouldCheckout) {
                          await storeCheckInOutTime(isCheckIn: false);
                          setState(() {
                            hasCheckedIn = false;
                            hasCheckedOut = true;
                          });
                        }
                      }
                          : null, // Disable check-out dialog if not checked in
                      child: _buildStatusColumn("Check Out", checkOutTime, isChecked: hasCheckedOut),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStatusColumn(String title, String time, {bool isChecked = false}) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SlideAction(
              elevation: 0,
              borderRadius: 30,
              text: hasCheckedIn ? "Slide to Check Out" : "Slide to Check In",
              textStyle: TextStyle(
                fontSize: screenWidth / 22,
                color: Colors.cyan.shade700,
                fontFamily: "NexaRegular",
                letterSpacing: 1.2,
              ),
              outerColor: Colors.white,
              innerColor: Colors.cyan,
              sliderButtonIcon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
              onSubmit: () async {
                if (hasCheckedIn) {
                  // If the user is already checked in, show the check-out confirmation dialog
                  bool shouldCheckout = await _showCheckoutDialog();  // Await and get the result
                  if (shouldCheckout) {
                    // If user confirms checkout, store the checkout time in Firestore
                    await storeCheckInOutTime(isCheckIn: false);
                    setState(() {
                      hasCheckedOut = true;  // Update state to reflect check-out
                      // Do not reset hasCheckedIn here, because it's already true
                    });
                  }
                } else {
                  // If the user is not checked in, show the check-in dialog
                  bool shouldCheckIn = await _showCheckInDialog();  // Await and get the result
                  if (shouldCheckIn) {
                    // If user confirms check-in, store the check-in time in Firestore
                    await storeCheckInOutTime(isCheckIn: true);
                    setState(() {
                      hasCheckedIn = true;  // Update state to reflect check-in
                      // Do not reset hasCheckedOut here, because the user can later check out
                    });
                  }
                }
              },




            ),
          ),
          const SizedBox(height: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: ElevatedButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute( builder: (context) => MapScreen(initialPosition: initialPosition)));
            },style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan,shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                child: Text("View Live Google map",style: TextStyle(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold,color: Colors.white,),)),
          ),
        )
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: Text(
        "Current Location: $_currentLocation",
        style: TextStyle(
          fontFamily: "NexaRegular",
          fontSize: screenWidth / 20,
        ),
      ),
    );
  }
}
int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}